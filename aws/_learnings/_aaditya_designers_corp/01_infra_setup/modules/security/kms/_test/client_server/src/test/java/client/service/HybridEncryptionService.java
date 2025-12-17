package client.service;

import client.crypto.AESEncryptionKeyGenerator;
import client.crypto.FieldEncryptor;
import client.crypto.JwtBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * Hybrid Encryption Service - Main utility for encrypting REST API requests.
 *
 * <h2>CLIENT STEPS 1-4: Complete Client-Side Encryption Flow</h2>
 * <pre>
 * ┌──────────────────────────────────────────────────────────────────────────────┐
 * │                      CLIENT ENCRYPTION ORCHESTRATION                         │
 * │                                                                              │
 * │  STEP 1: loadRSAPublicKey()                                                  │
 * │  ► Load RSA-4096 public key from PEM file                                    │
 * │                                 ▼                                            │
 * │  STEP 2+3: generateAESEncryptionKeyAndAddItToJWTMetadata()        │
 * │  ► fieldEncryptor.generateAESEncryptionKey() - Create 256-bit AES DEK  │
 * │  ► jwtBuilder.wrapByEncryptingAESEncryptionKeyByRSAPublicKey(dek, rsaPublicKey) - Wrap DEK in JWE                   │
 * │                                 ▼                                            │
 * │  STEP 4: encryptField(plaintext)                                             │
 * │  ► fieldEncryptor.encrypt(plaintext, dek)                                    │
 * │  ► Output: "iv.encryptedText.authTag" (~60 chars per field)                  │
 * │                                 ▼                                            │
 * │  getJwtEncryptionMetadata()                                                  │
 * │  ► Returns JWE for X-Encryption-Key header                                   │
 * └──────────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Service
public class HybridEncryptionService {

  private static final Logger log = LoggerFactory.getLogger(HybridEncryptionService.class);
  private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";

  private final FieldEncryptor fieldEncryptor;
  private final JwtBuilder jwtBuilder;

  private RSAPublicKey rsaPublicKey;
  private SecretKey aesEncryptionKey;
  private String jwtEncryptionMetadata;
  private AESEncryptionKeyGenerator aesEncryptionKeyGenerator;

  @Autowired
  public HybridEncryptionService(
      FieldEncryptor fieldEncryptor,
      JwtBuilder jwtBuilder,
      AESEncryptionKeyGenerator aesEncryptionKeyGenerator) {
    this.fieldEncryptor = fieldEncryptor;
    this.jwtBuilder = jwtBuilder;
    this.aesEncryptionKeyGenerator = aesEncryptionKeyGenerator;
  }

  /**
   * TODO: Move to AWS Secrets Manager
   * Loads the RSA public key from the default resource location.
   */
  public void loadRSAPublicKey() {
    try (InputStream is = getClass().getResourceAsStream(PUBLIC_KEY_RESOURCE)) {
      if (is == null) {
        throw new IOException("Public key not found at: " + PUBLIC_KEY_RESOURCE);
      }
      String pemContent = new String(is.readAllBytes(), StandardCharsets.UTF_8);
      loadRSAPublicKey(pemContent);
    } catch (IOException e) {
      throw new RuntimeException("Failed to load public key from resources", e);
    }
  }

  /**
   * Loads the RSA public key from a PEM-formatted string.
   */
  public void loadRSAPublicKey(String pemContent) {
    try {
      String base64Key = pemContent
          .replace("-----BEGIN PUBLIC KEY-----", "")
          .replace("-----END PUBLIC KEY-----", "")
          .replaceAll("\\s", "");

      byte[] keyBytes = Base64.getDecoder().decode(base64Key);
      X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
      KeyFactory keyFactory = KeyFactory.getInstance("RSA");
      this.rsaPublicKey = (RSAPublicKey) keyFactory.generatePublic(keySpec);

    } catch (Exception e) {
      throw new RuntimeException("Failed to parse public key", e);
    }
  }

  /**
   * Generates a fresh AES encryption key and wraps it in JWE format.
   */
  public void generateAESEncryptionKeyAndAddItToJWTMetadata() {
    if (rsaPublicKey == null) {
      throw new IllegalStateException("Public key not loaded. Call loadRSAPublicKey() first.");
    }
    this.aesEncryptionKey = aesEncryptionKeyGenerator.generateAESEncryptionKey();

    log.info("=== DEBUG: CLIENT - generateAESEncryptionKeyAndAddItToJWTMetadata ===");
    log.info("DEBUG: CLIENT - Generated AES key size: {} bytes", aesEncryptionKey.getEncoded().length);
    log.info("DEBUG: CLIENT - Generated AES key base64: {}", Base64.getEncoder().encodeToString(aesEncryptionKey.getEncoded()));

    this.jwtEncryptionMetadata = jwtBuilder.wrapByEncryptingAESEncryptionKeyByRSAPublicKey(aesEncryptionKey, rsaPublicKey);
    log.info("DEBUG: CLIENT - JWE metadata (first 100 chars): {}",
        jwtEncryptionMetadata.length() > 100 ? jwtEncryptionMetadata.substring(0, 100) + "..." : jwtEncryptionMetadata);
  }

  /**
   * Encrypts a sensitive field value.
   *
   * @param plaintext The sensitive value to encrypt
   * @return Encrypted string in format: iv.encryptedText.authTag
   */
  public String encryptField(String plaintext) {
    if (aesEncryptionKey == null) {
      throw new IllegalStateException("Call generateAESEncryptionKeyAndAddItToJWTMetadata() first.");
    }
    return fieldEncryptor.encrypt(plaintext, aesEncryptionKey);
  }

  /**
   * Gets the JWE encryption header value for the current request.
   *
   * @return The JWE string for the X-Encryption-Key header
   */
  public String getJwtEncryptionMetadata() {
    if (jwtEncryptionMetadata == null) {
      throw new IllegalStateException("Call generateAESEncryptionKeyAndAddItToJWTMetadata() first.");
    }
    return jwtEncryptionMetadata;
  }

  /**
   * Clears the current request state.
   */
  public void clear() {
    this.aesEncryptionKey = null;
    this.jwtEncryptionMetadata = null;
  }
}

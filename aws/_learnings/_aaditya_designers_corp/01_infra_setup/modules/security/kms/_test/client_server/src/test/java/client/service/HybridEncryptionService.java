package client.service;

import client.crypto.FieldEncryptor;
import client.crypto.JweBuilder;
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
 * │  STEP 2+3: generateLocalRandomAESEncryptionKeyAndAddItToJWTMetadata()        │
 * │  ► fieldEncryptor.generateRandomAESEncryptionKey() - Create 256-bit AES DEK  │
 * │  ► jweBuilder.wrapKey(dek, rsaPublicKey) - Wrap DEK in JWE                   │
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

  private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";

  private final FieldEncryptor fieldEncryptor;
  private final JweBuilder jweBuilder;

  private RSAPublicKey rsaPublicKey;
  private SecretKey randomAESEncryptionKey;
  private String jwtEncryptionMetadata;

  @Autowired
  public HybridEncryptionService(FieldEncryptor fieldEncryptor, JweBuilder jweBuilder) {
    this.fieldEncryptor = fieldEncryptor;
    this.jweBuilder = jweBuilder;
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
  public void generateLocalRandomAESEncryptionKeyAndAddItToJWTMetadata() {
    if (rsaPublicKey == null) {
      throw new IllegalStateException("Public key not loaded. Call loadRSAPublicKey() first.");
    }
    this.randomAESEncryptionKey = fieldEncryptor.generateRandomAESEncryptionKey();
    this.jwtEncryptionMetadata = jweBuilder.wrapKey(randomAESEncryptionKey, rsaPublicKey);
  }

  /**
   * Encrypts a sensitive field value.
   *
   * @param plaintext The sensitive value to encrypt
   * @return Encrypted string in format: iv.encryptedText.authTag
   */
  public String encryptField(String plaintext) {
    if (randomAESEncryptionKey == null) {
      throw new IllegalStateException("Call generateLocalRandomAESEncryptionKeyAndAddItToJWTMetadata() first.");
    }
    return fieldEncryptor.encrypt(plaintext, randomAESEncryptionKey);
  }

  /**
   * Gets the JWE encryption header value for the current request.
   *
   * @return The JWE string for the X-Encryption-Key header
   */
  public String getJwtEncryptionMetadata() {
    if (jwtEncryptionMetadata == null) {
      throw new IllegalStateException("Call generateLocalRandomAESEncryptionKeyAndAddItToJWTMetadata() first.");
    }
    return jwtEncryptionMetadata;
  }

  /**
   * Clears the current request state.
   */
  public void clear() {
    this.randomAESEncryptionKey = null;
    this.jwtEncryptionMetadata = null;
  }
}

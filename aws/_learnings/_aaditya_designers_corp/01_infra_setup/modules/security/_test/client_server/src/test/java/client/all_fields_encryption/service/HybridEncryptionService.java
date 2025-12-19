package client.all_fields_encryption.service;

import client.all_fields_encryption.crypto.JWEEncryptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * Hybrid Encryption Service (All-Fields) - Client-side JWE encryption.
 *
 * <h2>CLIENT STEPS 1-2: All-Fields JWE Encryption Flow</h2>
 * <pre>
 * ┌──────────────────────────────────────────────────────────────────────────────┐
 * │                ALL-FIELDS ENCRYPTION (PROPER JWE/CEK)                        │
 * │                                                                              │
 * │  STEP 1: loadPublicKey()                                                  │
 * │  ► Load RSA-4096 public key from PEM file                                    │
 * │                                 ▼                                            │
 * │  STEP 2: encryptPayload(jsonPayload)                                         │
 * │  ► jweEncryptor.encrypt(jsonPayload, publicKey)                           │
 * │  ► JWE library generates CEK (aesContentEncryptionKey) internally            │
 * │  ► Encrypts entire JSON with CEK                                             │
 * │  ► Encrypts CEK with RSA public key                                          │
 * │  ► Output: JWE string (entire encrypted payload)                             │
 * └──────────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>When to Use This Approach:</h3>
 * <ul>
 *   <li>Encrypting <b>entire payload</b> at once</li>
 *   <li>Payload may be large (CEK/AES handles this efficiently)</li>
 *   <li>Want standard JWE format (RFC 7516)</li>
 *   <li>Don't need to decrypt individual fields separately</li>
 * </ul>
 */
@Service("allFieldsHybridEncryptionService")
public class HybridEncryptionService {

  private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";

  private final JWEEncryptor jweEncryptor;
  private RSAPublicKey publicKey;

  @Autowired
  public HybridEncryptionService(JWEEncryptor jweEncryptor) {
    this.jweEncryptor = jweEncryptor;
  }

  /**
   * Loads the RSA public key from the default resource location.
   */
  public void loadPublicKey() {
    try (InputStream is = getClass().getResourceAsStream(PUBLIC_KEY_RESOURCE)) {
      if (is == null) {
        throw new IOException("Public key not found at: " + PUBLIC_KEY_RESOURCE);
      }
      String pemContent = new String(is.readAllBytes(), StandardCharsets.UTF_8);
      loadPublicKey(pemContent);
    } catch (IOException e) {
      throw new RuntimeException("Failed to load public key from resources", e);
    }
  }

  /**
   * Loads the RSA public key from a PEM-formatted string.
   */
  public void loadPublicKey(String pemContent) {
    try {
      String base64Key = pemContent
          .replace("-----BEGIN PUBLIC KEY-----", "")
          .replace("-----END PUBLIC KEY-----", "")
          .replaceAll("\\s", "");

      byte[] keyBytes = Base64.getDecoder().decode(base64Key);
      X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
      KeyFactory keyFactory = KeyFactory.getInstance("RSA");
      this.publicKey = (RSAPublicKey) keyFactory.generatePublic(keySpec);

    } catch (Exception e) {
      throw new RuntimeException("Failed to parse public key", e);
    }
  }

  /**
   * Encrypts the entire JSON payload into JWE format.
   *
   * <p>The JWE library internally:</p>
   * <ol>
   *   <li>Generates random CEK (aesContentEncryptionKey)</li>
   *   <li>Encrypts payload with CEK using AES-256-GCM</li>
   *   <li>Encrypts CEK with RSA public key</li>
   * </ol>
   *
   * @param jsonPayload The entire JSON payload to encrypt
   * @return JWE compact serialization string
   */
  public String encryptPayload(String jsonPayload) {
    if (publicKey == null) {
      throw new IllegalStateException("Public key not loaded. Call loadPublicKey() first.");
    }
    return jweEncryptor.encrypt(jsonPayload, publicKey);
  }
}

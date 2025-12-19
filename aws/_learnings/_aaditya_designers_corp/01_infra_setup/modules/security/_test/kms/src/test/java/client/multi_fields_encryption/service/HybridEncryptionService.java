package client.multi_fields_encryption.service;

import client.multi_fields_encryption.crypto.DEKGenerator;
import client.multi_fields_encryption.crypto.FieldEncryptor;
import client.multi_fields_encryption.crypto.DEKEncryptorAndWrapper;
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
 * Hybrid Encryption Service (Multi-Fields) - Client-side encryption orchestration.
 *
 * <h2>CLIENT STEPS 1-4: Multi-Field Encryption Flow</h2>
 * <pre>
 * ┌──────────────────────────────────────────────────────────────────────────────┐
 * │               MULTI-FIELD ENCRYPTION (NO JWE/CEK)                            │
 * │                                                                              │
 * │  STEP 1: loadPublicKey()                                                  │
 * │  ► Load RSA-4096 public key from PEM file                                    │
 * │                                 ▼                                            │
 * │  STEP 2: generateEncryptAndWrapDataEncryptionKey()                                                │
 * │  ► Generate AES DEK (256-bit Data Encryption Key)                            │
 * │  ► RSA-encrypt DEK directly (NO CEK, NO JWE)                                 │
 * │  ► Output: BASE64(encryptedDataEncryptionKey)                                              │
 * │                                 ▼                                            │
 * │  STEP 3: encryptField(plaintext)                                             │
 * │  ► fieldEncryptor.encrypt(plaintext, dataEncryptionKey)                   │
 * │  ► Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"                │
 * │                                 ▼                                            │
 * │  STEP 4: getEncryptedDataEncryptionKey()                                                   │
 * │  ► Returns BASE64(encryptedDataEncryptionKey) for X-Encryption-Key header                  │
 * └──────────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why This Approach (vs JWE/CEK)?</h3>
 * <ul>
 *   <li><b>Simpler:</b> Direct RSA encryption of DEK, no intermediate CEK</li>
 *   <li><b>Efficient:</b> Server needs only 1 KMS call to decrypt DEK</li>
 *   <li><b>Sufficient:</b> DEK is 32 bytes, RSA-4096 can encrypt up to ~470 bytes</li>
 * </ul>
 */
@Service("multiFieldsHybridEncryptionService")
public class HybridEncryptionService {

  private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";

  private final FieldEncryptor fieldEncryptor;
  private final DEKEncryptorAndWrapper dekEncryptorAndWrapper;
  private final DEKGenerator dekGenerator;

  private RSAPublicKey publicKey;
  private SecretKey dataEncryptionKey;
  private String encryptedDataEncryptionKey;

  @Autowired
  public HybridEncryptionService(
      FieldEncryptor fieldEncryptor,
      DEKEncryptorAndWrapper dekEncryptorAndWrapper,
      DEKGenerator dekGenerator
  ) {
    this.fieldEncryptor = fieldEncryptor;
    this.dekEncryptorAndWrapper = dekEncryptorAndWrapper;
    this.dekGenerator = dekGenerator;
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
   * Generates an AES Data Encryption Key (DEK) and wraps it with RSA.
   *
   * <p>Unlike JWE approach, this directly RSA-encrypts the DEK:</p>
   * <pre>
   * DEK ──(RSA-OAEP-256)──► encryptedDataEncryptionKey
   * </pre>
   *
   * <p>No intermediate CEK is used.</p>
   */
  public void generateEncryptAndWrapDataEncryptionKey() {
    if (publicKey == null) {
      throw new IllegalStateException("Public key not loaded. Call loadPublicKey() first.");
    }
    this.dataEncryptionKey = dekGenerator.generateDataEncryptionKey();
    this.encryptedDataEncryptionKey = dekEncryptorAndWrapper.encryptAndWrapDataEncryptionKey(dataEncryptionKey, publicKey);
  }

  /**
   * Encrypts a sensitive field value using the AES DEK.
   *
   * @param plaintext The sensitive value to encrypt
   * @return Encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   */
  public String encryptField(String plaintext) {
    if (dataEncryptionKey == null) {
      throw new IllegalStateException("Call generateEncryptAndWrapDataEncryptionKey() first.");
    }
    return fieldEncryptor.encrypt(plaintext, dataEncryptionKey);
  }

  /**
   * Gets the encrypted DEK for the X-Encryption-Key header.
   *
   * @return BASE64-encoded RSA-encrypted DEK
   */
  public String getEncryptedDataEncryptionKey() {
    if (encryptedDataEncryptionKey == null) {
      throw new IllegalStateException("Call generateEncryptAndWrapDataEncryptionKey() first.");
    }
    return encryptedDataEncryptionKey;
  }

  /**
   * Clears the current request state.
   */
  public void clear() {
    this.dataEncryptionKey = null;
    this.encryptedDataEncryptionKey = null;
  }
}

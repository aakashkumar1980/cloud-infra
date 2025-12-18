package client.multi_fields_encryption.service;

import client.multi_fields_encryption.crypto.AESKeyGenerator;
import client.multi_fields_encryption.crypto.FieldEncryptor;
import client.multi_fields_encryption.crypto.RsaKeyWrapper;
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
 * │  STEP 1: loadRSAPublicKey()                                                  │
 * │  ► Load RSA-4096 public key from PEM file                                    │
 * │                                 ▼                                            │
 * │  STEP 2: generateAndWrapDek()                                                │
 * │  ► Generate AES DEK (256-bit Data Encryption Key)                            │
 * │  ► RSA-encrypt DEK directly (NO CEK, NO JWE)                                 │
 * │  ► Output: BASE64(encryptedDek)                                              │
 * │                                 ▼                                            │
 * │  STEP 3: encryptField(plaintext)                                             │
 * │  ► fieldEncryptor.encrypt(plaintext, aesDataEncryptionKey)                   │
 * │  ► Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"                │
 * │                                 ▼                                            │
 * │  STEP 4: getEncryptedDek()                                                   │
 * │  ► Returns BASE64(encryptedDek) for X-Encryption-Key header                  │
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
  private final RsaKeyWrapper rsaKeyWrapper;
  private final AESKeyGenerator aesKeyGenerator;

  private RSAPublicKey rsaPublicKey;
  private SecretKey aesDataEncryptionKey;
  private String encryptedDek;

  @Autowired
  public HybridEncryptionService(
      FieldEncryptor fieldEncryptor,
      RsaKeyWrapper rsaKeyWrapper,
      AESKeyGenerator aesKeyGenerator
  ) {
    this.fieldEncryptor = fieldEncryptor;
    this.rsaKeyWrapper = rsaKeyWrapper;
    this.aesKeyGenerator = aesKeyGenerator;
  }

  /**
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
   * Generates an AES Data Encryption Key (DEK) and wraps it with RSA.
   *
   * <p>Unlike JWE approach, this directly RSA-encrypts the DEK:</p>
   * <pre>
   * DEK ──(RSA-OAEP-256)──► encryptedDek
   * </pre>
   *
   * <p>No intermediate CEK is used.</p>
   */
  public void generateAndWrapDek() {
    if (rsaPublicKey == null) {
      throw new IllegalStateException("Public key not loaded. Call loadRSAPublicKey() first.");
    }
    this.aesDataEncryptionKey = aesKeyGenerator.generateAesDataEncryptionKey();
    this.encryptedDek = rsaKeyWrapper.wrapKey(aesDataEncryptionKey, rsaPublicKey);
  }

  /**
   * Encrypts a sensitive field value using the AES DEK.
   *
   * @param plaintext The sensitive value to encrypt
   * @return Encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   */
  public String encryptField(String plaintext) {
    if (aesDataEncryptionKey == null) {
      throw new IllegalStateException("Call generateAndWrapDek() first.");
    }
    return fieldEncryptor.encrypt(plaintext, aesDataEncryptionKey);
  }

  /**
   * Gets the encrypted DEK for the X-Encryption-Key header.
   *
   * @return BASE64-encoded RSA-encrypted DEK
   */
  public String getEncryptedDek() {
    if (encryptedDek == null) {
      throw new IllegalStateException("Call generateAndWrapDek() first.");
    }
    return encryptedDek;
  }

  /**
   * Clears the current request state.
   */
  public void clear() {
    this.aesDataEncryptionKey = null;
    this.encryptedDek = null;
  }
}

package client.multi_fields_encryption.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.security.NoSuchAlgorithmException;

/**
 * AES Key Generator - Generates 256-bit AES Data Encryption Keys (DEK).
 *
 * <h2>STEP 2 (CLIENT): Generate AES Data Encryption Key</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  DEK GENERATION                                                        │
 * │                                                                        │
 * │  aesDataEncryptionKey = KeyGenerator.getInstance("AES")                │
 * │                           .generateKey()                               │
 * │                                                                        │
 * │  Output: SecretKey (32 bytes / 256 bits)                               │
 * │                                                                        │
 * │  Purpose: Encrypt multiple PII fields with same key                    │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class AESKeyGenerator {

  private static final String ALGORITHM = "AES";
  private static final int KEY_SIZE_BITS = 256;

  /**
   * Generates a new AES-256 Data Encryption Key.
   *
   * @return A new 256-bit AES SecretKey
   */
  public SecretKey generateAesDataEncryptionKey() {
    try {
      KeyGenerator keyGen = KeyGenerator.getInstance(ALGORITHM);
      keyGen.init(KEY_SIZE_BITS);
      return keyGen.generateKey();
    } catch (NoSuchAlgorithmException e) {
      throw new RuntimeException("AES algorithm not available", e);
    }
  }
}

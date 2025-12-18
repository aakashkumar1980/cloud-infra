package client.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.security.SecureRandom;

/**
 * AES Data Encryption Key Generator.
 *
 * <h2>What is AES?</h2>
 * <p><b>AES (Advanced Encryption Standard)</b> is a symmetric block cipher:</p>
 * <ul>
 *   <li>Uses the <b>same key</b> for encryption and decryption</li>
 *   <li>Key sizes: 128, 192, or 256 bits (we use <b>256-bit</b> for maximum security)</li>
 *   <li>Very fast: can encrypt/decrypt at ~GB/sec</li>
 *   <li>Industry standard since 2001 (replaced DES)</li>
 *   <li>Used by governments, banks, and secure applications worldwide</li>
 * </ul>
 *
 * <h2>What is DEK?</h2>
 * <p><b>DEK (Data Encryption Key)</b> is industry-standard terminology for envelope encryption:</p>
 * <ul>
 *   <li><b>DEK</b> = Data Encryption Key (encrypts actual data/fields)</li>
 *   <li><b>KEK</b> = Key Encryption Key (encrypts the DEK for transport)</li>
 * </ul>
 */
@Component
public class AESEncryptionKeyGenerator {

  private static final int KEY_SIZE_BITS = 256;
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Generates a new random AES Data Encryption Key (DEK).
   *
   * <p>Creates a cryptographically secure 256-bit AES key using SecureRandom.</p>
   *
   * @return A new 256-bit AES secret key (aesDataEncryptionKey)
   */
  public SecretKey generateAesDataEncryptionKey() {
    try {
      KeyGenerator keyGen = KeyGenerator.getInstance("AES");
      keyGen.init(KEY_SIZE_BITS, SECURE_RANDOM);
      return keyGen.generateKey();
    } catch (Exception e) {
      throw new RuntimeException("Failed to generate AES DEK", e);
    }
  }
}

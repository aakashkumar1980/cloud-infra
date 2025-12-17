package client.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import java.security.SecureRandom;

@Component
public class AESEncryptionKeyGenerator {

  private static final int KEY_SIZE_BITS = 256;
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Generates a new random AES-256 encryption key.
   *
   * @return A new 256-bit AES secret key
   */
  public SecretKey generateAESEncryptionKey() {
    try {
      KeyGenerator keyGen = KeyGenerator.getInstance("AES");
      keyGen.init(KEY_SIZE_BITS, SECURE_RANDOM);
      return keyGen.generateKey();
    } catch (Exception e) {
      throw new RuntimeException("Failed to generate AES key", e);
    }
  }
}

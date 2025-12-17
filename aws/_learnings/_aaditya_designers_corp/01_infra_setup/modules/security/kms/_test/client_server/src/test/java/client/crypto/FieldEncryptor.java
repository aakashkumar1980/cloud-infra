package client.crypto;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Field Encryptor - Encrypts individual fields using AES-256-GCM.
 *
 * <h2>STEP 2 & 4 (CLIENT): Generate DEK and Encrypt PII Fields</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  CLIENT ENCRYPTION FLOW                                                │
 * │                                                                        │
 * │  STEP 2: generateKey()                                                 │
 * │  ┌─────────────────────────────────────────────────────────────────┐  │
 * │  │  Generate DEK (Data Encryption Key)                             │  │
 * │  │  ► KeyGenerator.getInstance("AES")                              │  │
 * │  │  ► keyGen.init(256, SecureRandom)                               │  │
 * │  │  Output: 256-bit AES SecretKey                                  │  │
 * │  └─────────────────────────────────────────────────────────────────┘  │
 * │                                                                        │
 * │  STEP 4: encrypt(plaintext, key)                                      │
 * │  ┌─────────────────────────────────────────────────────────────────┐  │
 * │  │  For each PII field (DOB, Credit Card, SSN):                    │  │
 * │  │  1. Generate random 96-bit IV                                   │  │
 * │  │  2. Initialize AES-256-GCM cipher                               │  │
 * │  │  3. Encrypt plaintext → ciphertext + authTag                    │  │
 * │  │  4. Format: BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)       │  │
 * │  │  Output: "abc123.xyz789.def456" (~60 chars)                     │  │
 * │  └─────────────────────────────────────────────────────────────────┘  │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Output Format:</h3>
 * <pre>
 * BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
 * Example: "abc123.xyz789.def456"
 * </pre>
 *
 * <h3>Security Properties:</h3>
 * <ul>
 *   <li>AES-256: 256-bit key strength (military grade)</li>
 *   <li>GCM Mode: Provides both confidentiality and integrity</li>
 *   <li>Random IV: Ensures same plaintext encrypts differently each time</li>
 *   <li>Auth Tag: Detects if ciphertext was tampered with</li>
 * </ul>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * SecretKey key = FieldEncryptor.generateKey();
 * String encrypted = FieldEncryptor.encrypt("4111111111111234", key);
 * // encrypted = "AAAA.BBBB.CCCC" (iv.ciphertext.authTag)
 * }</pre>
 */
public class FieldEncryptor {

  /** AES key size in bits (256-bit for maximum security) */
  private static final int KEY_SIZE_BITS = 256;

  /** GCM IV size in bytes (96 bits as recommended by NIST) */
  private static final int IV_SIZE_BYTES = 12;

  /** GCM authentication tag size in bits */
  private static final int AUTH_TAG_SIZE_BITS = 128;

  /** Secure random number generator for IV generation */
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Generates a new random AES-256 encryption key.
   *
   * <p>This key should be generated once per request and used to encrypt
   * all sensitive fields in that request. The key is then wrapped using
   * RSA and sent in the X-Encryption-Key header.</p>
   *
   * @return A new 256-bit AES secret key
   * @throws RuntimeException if key generation fails
   */
  public static SecretKey generateKey() {
    try {
      KeyGenerator keyGen = KeyGenerator.getInstance("AES");
      keyGen.init(KEY_SIZE_BITS, SECURE_RANDOM);
      return keyGen.generateKey();
    } catch (Exception e) {
      throw new RuntimeException("Failed to generate AES key", e);
    }
  }

  /**
   * Encrypts a plaintext field using AES-256-GCM.
   *
   * <p>Each call generates a unique random IV, ensuring that encrypting
   * the same value twice produces different ciphertexts. This prevents
   * attackers from detecting patterns in encrypted data.</p>
   *
   * @param plaintext The sensitive data to encrypt (e.g., "4111111111111234")
   * @param key       The AES secret key (from {@link #generateKey()})
   * @return Encrypted string in format: BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
   * @throws RuntimeException if encryption fails
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * String creditCard = "4111111111111234";
   * String encrypted = FieldEncryptor.encrypt(creditCard, key);
   * // Result: "rAnDoMiV.eNcRyPtEdDaTa.aUtHtAg"
   * }</pre>
   */
  public static String encrypt(String plaintext, SecretKey key) {
    try {
      // Generate random IV for this encryption
      byte[] iv = new byte[IV_SIZE_BYTES];
      SECURE_RANDOM.nextBytes(iv);

      // Initialize cipher with AES-GCM
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.ENCRYPT_MODE, key, gcmSpec);

      // Encrypt the plaintext
      byte[] plaintextBytes = plaintext.getBytes(StandardCharsets.UTF_8);
      byte[] ciphertextWithTag = cipher.doFinal(plaintextBytes);

      // Split ciphertext and auth tag (GCM appends 16-byte tag at the end)
      int tagSizeBytes = AUTH_TAG_SIZE_BITS / 8;
      int ciphertextLength = ciphertextWithTag.length - tagSizeBytes;

      byte[] ciphertext = new byte[ciphertextLength];
      byte[] authTag = new byte[tagSizeBytes];
      System.arraycopy(ciphertextWithTag, 0, ciphertext, 0, ciphertextLength);
      System.arraycopy(ciphertextWithTag, ciphertextLength, authTag, 0, tagSizeBytes);

      // Format: IV.Ciphertext.AuthTag (all Base64 encoded)
      return Base64.getEncoder().encodeToString(iv) + "." +
             Base64.getEncoder().encodeToString(ciphertext) + "." +
             Base64.getEncoder().encodeToString(authTag);

    } catch (Exception e) {
      throw new RuntimeException("Failed to encrypt field", e);
    }
  }
}

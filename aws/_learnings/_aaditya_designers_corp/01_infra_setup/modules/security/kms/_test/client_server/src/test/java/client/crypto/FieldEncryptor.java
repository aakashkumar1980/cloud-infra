package client.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Field Encryptor - Encrypts individual PII fields using AES-256-GCM.
 *
 * <h2>STEP 4 (CLIENT): Encrypt PII Fields</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  FIELD ENCRYPTION                                                      │
 * │                                                                        │
 * │  Input: plainText, aesDataEncryptionKey (DEK)                         │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Generate random 96-bit IV (12 bytes)                              │
 * │  2. Initialize AES-256-GCM cipher with DEK                            │
 * │  3. Encrypt plainText → encryptedText + authTag (16 bytes)            │
 * │                                                                        │
 * │  Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"           │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Sample Encrypted Field Values:</h3>
 * <pre>
 * Input:  "1990-05-15" (Date of Birth)
 * Output: "rK8xMzQ1Njc4OTAx.YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo=.dGFnMTIzNDU2Nzg5MDEyMzQ1Ng=="
 *         └─────────────┘ └─────────────────────────────────────┘ └──────────────────────────────┘
 *              IV (12B)              EncryptedText (variable)            AuthTag (16B)
 *
 * Input:  "4111111111111234" (Credit Card)
 * Output: "c2FtcGxlSVYxMjM=.ZW5jcnlwdGVkQ3JlZGl0Q2FyZERhdGE=.YXV0aFRhZzEyMzQ1Njc4OTAxMg=="
 *
 * Input:  "123-45-6789" (SSN)
 * Output: "aXZGb3JTU04xMjM=.ZW5jcnlwdGVkU1NOVmFsdWVIZXJl.c3NuQXV0aFRhZzEyMzQ1Njc4"
 * </pre>
 *
 * <p><b>Note:</b> Each encryption generates a unique IV, so the same plaintext
 * will produce different ciphertext each time (this is good for security!).</p>
 */
@Component
public class FieldEncryptor {

  private static final int IV_SIZE_BYTES = 12;
  private static final int AUTH_TAG_SIZE_BITS = 128;
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Encrypts a plaintext field using AES-256-GCM.
   *
   * @param plainText            The sensitive data to encrypt (e.g., "1990-05-15", "4111111111111234")
   * @param aesDataEncryptionKey The AES DEK (Data Encryption Key) - 256-bit key
   * @return Encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   *         Example: "rK8xMzQ1Njc4OTAx.YWJjZGVm...eXo=.dGFnMTIz...NTY="
   */
  public String encrypt(String plainText, SecretKey aesDataEncryptionKey) {
    try {
      // Generate random IV (12 bytes = 96 bits for GCM)
      byte[] iv = new byte[IV_SIZE_BYTES];
      SECURE_RANDOM.nextBytes(iv);

      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.ENCRYPT_MODE, aesDataEncryptionKey, gcmSpec);
      byte[] encryptedTextWithTag = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

      // Split encryptedText and authTag, then format output
      int tagSizeBytes = AUTH_TAG_SIZE_BITS / 8;
      int encryptedTextLength = encryptedTextWithTag.length - tagSizeBytes;
      byte[] encryptedText = new byte[encryptedTextLength];
      byte[] authTag = new byte[tagSizeBytes];
      System.arraycopy(encryptedTextWithTag, 0, encryptedText, 0, encryptedTextLength);
      System.arraycopy(encryptedTextWithTag, encryptedTextLength, authTag, 0, tagSizeBytes);

      return Base64.getEncoder().encodeToString(iv) + "." +
             Base64.getEncoder().encodeToString(encryptedText) + "." +
             Base64.getEncoder().encodeToString(authTag);

    } catch (Exception e) {
      throw new RuntimeException("Failed to encrypt field", e);
    }
  }
}

package client.restapi.encryption.multi_fields_in_payload.crypto;

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
 * │  Input: plainText (e.g., "1990-05-15", "4111111111111234")             │
 * │  Key:   aesDataEncryptionKey (DEK from Step 2)                         │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Generate random IV (12 bytes)                                      │
 * │  2. Encrypt plainText using AES-256-GCM                                │
 * │  3. Combine: BASE64(IV) + "." + BASE64(ciphertext) + "." + BASE64(tag) │
 * │                                                                        │
 * │  Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"            │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class FieldEncryptor {

  private static final int IV_SIZE_BYTES = 12;
  private static final int AUTH_TAG_SIZE_BITS = 128;

  private final SecureRandom secureRandom = new SecureRandom();

  /**
   * Encrypts a sensitive field value using AES-256-GCM.
   *
   * <h3>ENCRYPT-AES (AES-256-GCM):</h3>
   * <pre>
   * ┌───────────────────────┐
   * │      plainText        │────┐
   * │ "1990-05-15"          │    │
   * └───────────────────────┘    │        ┌─────────────────────────────────────┐
   *                              │        │                                     │
   * ┌───────────────────────┐    │        │        AES-256-GCM ENCRYPT          │
   * │ dataEncryptionKey  │────┼───────►│                                     │
   * │ (DEK - 32 bytes)      │    │        │  Output: encryptedText + authTag    │
   * └───────────────────────┘    │        │                                     │
   *                              │        └─────────────────────────────────────┘
   * ┌───────────────────────┐    │
   * │         iv            │────┘
   * │ (12 bytes)            │
   * └───────────────────────┘
   * </pre>
   *
   * @param plainText            The sensitive data to encrypt
   * @param dataEncryptionKey The AES DEK (Data Encryption Key) - 256-bit key
   * @return Encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   */
  public String encrypt(String plainText, SecretKey dataEncryptionKey) {
    try {
      // Generate random IV
      byte[] iv = new byte[IV_SIZE_BYTES];
      secureRandom.nextBytes(iv);

      // Initialize cipher
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.ENCRYPT_MODE, dataEncryptionKey, gcmSpec);

      // Encrypt
      byte[] encryptedWithTag = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

      // GCM appends auth tag to ciphertext, split them
      int ciphertextLength = encryptedWithTag.length - (AUTH_TAG_SIZE_BITS / 8);
      byte[] encryptedText = new byte[ciphertextLength];
      byte[] authTag = new byte[AUTH_TAG_SIZE_BITS / 8];
      System.arraycopy(encryptedWithTag, 0, encryptedText, 0, ciphertextLength);
      System.arraycopy(encryptedWithTag, ciphertextLength, authTag, 0, authTag.length);

      // Combine as dot-separated Base64 strings
      return Base64.getEncoder().encodeToString(iv) + "." +
          Base64.getEncoder().encodeToString(encryptedText) + "." +
          Base64.getEncoder().encodeToString(authTag);

    } catch (Exception e) {
      throw new RuntimeException("Failed to encrypt field: " + e.getMessage(), e);
    }
  }
}

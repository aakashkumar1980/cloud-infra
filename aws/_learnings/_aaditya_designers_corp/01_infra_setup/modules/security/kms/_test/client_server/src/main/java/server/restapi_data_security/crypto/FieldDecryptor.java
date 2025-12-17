package server.restapi_data_security.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Field Decryptor - Decrypts individual fields using AES-256-GCM.
 *
 * <h2>STEP 7 (BACKEND): Decrypt PII Fields Locally</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  FIELD DECRYPTION                                                      │
 * │                                                                        │
 * │  Input: "iv.ciphertext.authTag" (encrypted field from client)         │
 * │  Key:   randomAESEncryptionKey (unwrapped via KMS in Step 6)          │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Split encrypted string → iv, encryptedText, authTag               │
 * │  2. Decode each part from Base64                                       │
 * │  3. Initialize AES-256-GCM cipher with IV                             │
 * │  4. Decrypt encryptedText and verify authTag                          │
 * │                                                                        │
 * │  Output: Plaintext (e.g., "4111111111111234")                         │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Expected Input Format:</h3>
 * <pre>
 * BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
 * Example: "abc123.xyz789.def456"
 * </pre>
 *
 * <h3>Security Properties:</h3>
 * <ul>
 *   <li><b>Integrity Check:</b> The auth tag verifies data wasn't tampered with</li>
 *   <li><b>No KMS Call:</b> Decryption happens locally using the unwrapped key</li>
 *   <li><b>Fast:</b> AES decryption is very fast (~GB/sec)</li>
 * </ul>
 */
@Component
public class FieldDecryptor {

  /** GCM authentication tag size in bits */
  private static final int AUTH_TAG_SIZE_BITS = 128;

  /**
   * Decrypts an encrypted field value.
   *
   * @param encryptedField The encrypted string in format: iv.encryptedText.authTag
   * @param randomAESEncryptionKey The AES secret key (unwrapped from JWE via KMS)
   * @return The decrypted plaintext string
   * @throws IllegalArgumentException if the format is invalid
   * @throws RuntimeException if decryption fails (wrong key or tampered data)
   */
  public String decrypt(String encryptedField, SecretKey randomAESEncryptionKey) {
    // Validate and split the encrypted field
    String[] parts = encryptedField.split("\\.");
    if (parts.length != 3) {
      throw new IllegalArgumentException(
          "Invalid encrypted field format. Expected: IV.EncryptedText.AuthTag, got " + parts.length + " parts");
    }

    try {
      /**
       * STEP 1: Decode each part from Base64
       */
      byte[] iv = Base64.getDecoder().decode(parts[0]);
      byte[] encryptedText = Base64.getDecoder().decode(parts[1]);
      byte[] authTag = Base64.getDecoder().decode(parts[2]);

      /**
       * STEP 2: Combine encryptedText and authTag (GCM expects them together)
       * Then decrypt using the randomAESEncryptionKey + IV
       */
      byte[] encryptedTextWithTag = new byte[encryptedText.length + authTag.length];
      System.arraycopy(encryptedText, 0, encryptedTextWithTag, 0, encryptedText.length);
      System.arraycopy(authTag, 0, encryptedTextWithTag, encryptedText.length, authTag.length);

      // Initialize cipher for decryption
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.DECRYPT_MODE, randomAESEncryptionKey, gcmSpec);

      // Decrypt and return plaintext
      byte[] plainText = cipher.doFinal(encryptedTextWithTag);
      return new String(plainText, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt field: " + e.getMessage(), e);
    }
  }
}

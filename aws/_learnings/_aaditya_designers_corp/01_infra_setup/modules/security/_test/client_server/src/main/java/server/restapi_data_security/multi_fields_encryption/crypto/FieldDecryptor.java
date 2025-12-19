package server.restapi_data_security.multi_fields_encryption.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Field Decryptor - Decrypts individual PII fields using AES-256-GCM.
 *
 * <h2>STEP 6 (SERVER): Decrypt PII Fields Locally</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  FIELD DECRYPTION                                                      │
 * │                                                                        │
 * │  Input: encryptedField, aesDataEncryptionKey (DEK from Step 5)         │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Parse: iv, encryptedText, authTag from dot-separated string        │
 * │  2. Decode each part from Base64                                       │
 * │  3. Decrypt using AES-256-GCM with DEK                                 │
 * │                                                                        │
 * │  Output: plainText (e.g., "1990-05-15", "4111111111111234")             │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Security:</h3>
 * <ul>
 *   <li><b>No KMS Call:</b> Decryption happens locally using the AES DEK</li>
 *   <li><b>Fast:</b> AES decryption is extremely fast (~GB/sec)</li>
 *   <li><b>Integrity:</b> AuthTag verifies data wasn't tampered</li>
 * </ul>
 */
@Component("multiFieldsFieldDecryptor")
public class FieldDecryptor {

  private static final int AUTH_TAG_SIZE_BITS = 128;

  /**
   * Decrypts an encrypted field value.
   *
   * <h3>DECRYPT-AES (AES-256-GCM):</h3>
   * <pre>
   * ┌───────────────────────┐
   * │    encryptedText      │────┐
   * │ (variable size)       │    │
   * └───────────────────────┘    │        ┌─────────────────────────────────────┐
   *                              │        │                                     │
   * ┌───────────────────────┐    │        │        AES-256-GCM DECRYPT          │
   * │ dataEncryptionKey  │────┼───────►│                                     │
   * │ (DEK - 32 bytes)      │    │        │  // authTag validates integrity     │
   * └───────────────────────┘    │        │  // Throws if tampered!             │
   *                              │        │                                     │
   * ┌───────────────────────┐    │        └──────────────────┬──────────────────┘
   * │         iv            │────┤                           │
   * │ (12 bytes)            │    │                           ▼
   * └───────────────────────┘    │        ┌─────────────────────────────────────┐
   *                              │        │ plainText = "1990-05-15"            │
   * ┌───────────────────────┐    │        └─────────────────────────────────────┘
   * │       authTag         │────┘
   * │ (16 bytes)            │
   * └───────────────────────┘
   * </pre>
   *
   * @param encryptedField       Format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   * @param dataEncryptionKey The AES DEK from KMS decryption
   * @return The decrypted plaintext string
   */
  public String decrypt(String encryptedField, SecretKey dataEncryptionKey) {
    String[] parts = encryptedField.split("\\.");
    if (parts.length != 3) {
      throw new IllegalArgumentException(
          "Invalid format. Expected: IV.EncryptedText.AuthTag, got " + parts.length + " parts");
    }

    try {
      byte[] iv = Base64.getDecoder().decode(parts[0]);
      byte[] encryptedText = Base64.getDecoder().decode(parts[1]);
      byte[] authTag = Base64.getDecoder().decode(parts[2]);

      // Combine encryptedText and authTag (GCM expects them together)
      byte[] encryptedWithTag = new byte[encryptedText.length + authTag.length];
      System.arraycopy(encryptedText, 0, encryptedWithTag, 0, encryptedText.length);
      System.arraycopy(authTag, 0, encryptedWithTag, encryptedText.length, authTag.length);

      // Decrypt
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.DECRYPT_MODE, dataEncryptionKey, gcmSpec);

      byte[] plainText = cipher.doFinal(encryptedWithTag);
      return new String(plainText, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt field: " + e.getMessage(), e);
    }
  }
}

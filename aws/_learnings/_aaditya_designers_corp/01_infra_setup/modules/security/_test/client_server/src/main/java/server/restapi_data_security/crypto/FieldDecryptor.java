package server.restapi_data_security.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Field Decryptor - Decrypts individual PII fields using AES-256-GCM.
 *
 * <h2>STEP 7 (SERVER): Decrypt PII Fields Locally</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  FIELD DECRYPTION                                                      │
 * │                                                                        │
 * │  Input: encryptedField, aesDataEncryptionKey (DEK from Step 6)        │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Parse encrypted string → iv, encryptedText, authTag               │
 * │  2. Decode each part from Base64                                       │
 * │  3. Initialize AES-256-GCM cipher with IV                             │
 * │  4. Decrypt encryptedText and verify authTag                          │
 * │                                                                        │
 * │  Output: plainText (e.g., "1990-05-15", "4111111111111234")            │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Sample Encrypted Field Values (Input):</h3>
 * <pre>
 * Encrypted DOB:    "rK8xMzQ1Njc4OTAx.YWJjZGVmZ2hpamts...eXo=.dGFnMTIzNDU2Nzg5MDEyMzQ1Ng=="
 * Encrypted Card:   "c2FtcGxlSVYxMjM=.ZW5jcnlwdGVkQ3Jl...GE=.YXV0aFRhZzEyMzQ1Njc4OTAxMg=="
 * Encrypted SSN:    "aXZGb3JTU04xMjM=.ZW5jcnlwdGVkU1NO...Jl.c3NuQXV0aFRhZzEyMzQ1Njc4"
 *                   └───────────────┘ └────────────────────┘ └─────────────────────────────┘
 *                       IV (12B)        EncryptedText            AuthTag (16B)
 * </pre>
 *
 * <h3>Security Properties:</h3>
 * <ul>
 *   <li><b>Integrity Check:</b> Auth tag verifies data wasn't tampered with</li>
 *   <li><b>No KMS Call:</b> Decryption happens locally using the AES DEK</li>
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
   * <h3>Internal Steps (DECRYPT-AES):</h3>
   * <pre>
   * ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   * │  INPUT                                                                                      │
   * │  ├── encryptedField: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"                    │
   * │  └── aesDataEncryptionKey (DEK): 32 bytes (extracted in Step 6)                            │
   * │                                                                                             │
   * │  STEP 1: Parse encrypted field                                                             │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │  parts = encryptedField.split(".")                                                         │
   * │  iv            = Base64.decode(parts[0])  // 12 bytes                                      │
   * │  encryptedText = Base64.decode(parts[1])  // variable size                                 │
   * │  authTag       = Base64.decode(parts[2])  // 16 bytes                                      │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 2: DECRYPT-AES (AES-256-GCM) - Decrypt field using DEK                               │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────┐                                                              │
   * │      │    encryptedText      │────┐                                                         │
   * │      │ (variable size)       │    │                                                         │
   * │      └───────────────────────┘    │        ┌─────────────────────────────────────────────┐  │
   * │                                   │        │                                             │  │
   * │      ┌───────────────────────┐    │        │            AES-256-GCM DECRYPT              │  │
   * │      │ aesDataEncryptionKey  │────┼───────►│                                             │  │
   * │      │ (DEK - 32 bytes)      │    │        │  Cipher cipher = Cipher.getInstance(        │  │
   * │      └───────────────────────┘    │        │      "AES/GCM/NoPadding");                  │  │
   * │                                   │        │  cipher.init(DECRYPT_MODE, dek, iv);        │  │
   * │      ┌───────────────────────┐    │        │  plainText = cipher.doFinal(                │  │
   * │      │         iv            │────┼───────►│      encryptedText + authTag);              │  │
   * │      │ (12 bytes)            │    │        │                                             │  │
   * │      └───────────────────────┘    │        │  // authTag validates data integrity        │  │
   * │                                   │        │  // Throws exception if tampered!           │  │
   * │      ┌───────────────────────┐    │        │                                             │  │
   * │      │       authTag         │────┘        └──────────────────────┬──────────────────────┘  │
   * │      │ (16 bytes)            │                                    │                         │
   * │      └───────────────────────┘                                    │                         │
   * │                                                                   ▼                         │
   * │                                             ┌─────────────────────────────────────────────┐ │
   * │                                             │ plainText = "1990-05-15"                    │ │
   * │                                             │ (or credit card, SSN, etc.)                 │ │
   * │                                             └─────────────────────────────────────────────┘ │
   * │                                                                                             │
   * │  OUTPUT                                                                                     │
   * │  └── String (plainText) - the decrypted PII value                                          │
   * └─────────────────────────────────────────────────────────────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────┬─────────────────┬───────────────────────────────────┬──────────────────────────────┐
   * │ Operation      │ Algorithm       │ Input                             │ Output                       │
   * ├────────────────┼─────────────────┼───────────────────────────────────┼──────────────────────────────┤
   * │ DECRYPT-AES    │ AES-256-GCM     │ aesDataEncryptionKey (DEK),       │ plainText                    │
   * │                │                 │ iv, encryptedText, authTag        │                              │
   * └────────────────┴─────────────────┴───────────────────────────────────┴──────────────────────────────┘
   * </pre>
   *
   * <h3>Sample Decryption:</h3>
   * <pre>
   * Input:  "rK8xMzQ1Njc4OTAx.YWJjZGVmZ2hpamts...eXo=.dGFnMTIzNDU2Nzg5MDEyMzQ1Ng=="
   *          └───────────────┘ └────────────────────────┘ └──────────────────────────────┘
   *               IV (12B)          EncryptedText              AuthTag (16B)
   *
   * Output: "1990-05-15"
   * </pre>
   *
   * @param encryptedField       The encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   * @param aesDataEncryptionKey The AES DEK (Data Encryption Key) extracted from JWE via KMS
   * @return The decrypted plaintext string (e.g., "1990-05-15", "4111111111111234")
   * @throws IllegalArgumentException if the format is invalid
   * @throws RuntimeException if decryption fails (wrong key or tampered data)
   */
  public String decrypt(String encryptedField, SecretKey aesDataEncryptionKey) {
    // Validate and split the encrypted field
    String[] parts = encryptedField.split("\\.");
    if (parts.length != 3) {
      throw new IllegalArgumentException(
          "Invalid encrypted field format. Expected: IV.EncryptedText.AuthTag, got " + parts.length + " parts");
    }

    try {
      // Decode each part from Base64
      byte[] iv = Base64.getDecoder().decode(parts[0]);
      byte[] encryptedText = Base64.getDecoder().decode(parts[1]);
      byte[] authTag = Base64.getDecoder().decode(parts[2]);

      // Combine encryptedText and authTag (GCM expects them together)
      byte[] encryptedTextWithTag = new byte[encryptedText.length + authTag.length];
      System.arraycopy(encryptedText, 0, encryptedTextWithTag, 0, encryptedText.length);
      System.arraycopy(authTag, 0, encryptedTextWithTag, encryptedText.length, authTag.length);

      // Initialize cipher for decryption
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.DECRYPT_MODE, aesDataEncryptionKey, gcmSpec);

      // Decrypt and return plaintext
      byte[] plainText = cipher.doFinal(encryptedTextWithTag);
      return new String(plainText, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt field: " + e.getMessage(), e);
    }
  }
}

package company_backend.rest_api_security.crypto;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Field Decryptor - Decrypts individual fields using AES-256-GCM.
 *
 * <p>This utility decrypts sensitive data fields that were encrypted by the
 * client using the {@code FieldEncryptor}. It uses the same AES-256-GCM
 * algorithm to ensure compatibility.</p>
 *
 * <h3>Expected Input Format:</h3>
 * <pre>
 * BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
 * Example: "abc123.xyz789.def456"
 * </pre>
 *
 * <h3>Security Properties:</h3>
 * <ul>
 *   <li><b>Integrity Check:</b> The auth tag verifies data wasn't tampered with</li>
 *   <li><b>No KMS Call:</b> Decryption happens locally using the unwrapped key</li>
 *   <li><b>Fast:</b> AES decryption is very fast (~GB/sec)</li>
 * </ul>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * SecretKey key = KmsKeyUnwrapper.unwrap(encryptedKey);
 * String creditCard = FieldDecryptor.decrypt("abc.xyz.def", key);
 * // creditCard = "4111111111111234"
 * }</pre>
 */
public class FieldDecryptor {

  /** GCM authentication tag size in bits */
  private static final int AUTH_TAG_SIZE_BITS = 128;

  /**
   * Decrypts an encrypted field value.
   *
   * <p>Parses the encrypted string, extracts the IV, ciphertext, and auth tag,
   * then decrypts using AES-256-GCM. If the data was tampered with, decryption
   * will fail with an authentication error.</p>
   *
   * @param encryptedField The encrypted string in format: iv.ciphertext.authTag
   * @param key            The AES secret key (unwrapped from JWE)
   * @return The decrypted plaintext string
   * @throws IllegalArgumentException if the format is invalid
   * @throws RuntimeException if decryption fails (wrong key or tampered data)
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * String encrypted = "AAAA.BBBB.CCCC";
   * String plaintext = FieldDecryptor.decrypt(encrypted, key);
   * // plaintext = "4111111111111234"
   * }</pre>
   */
  public static String decrypt(String encryptedField, SecretKey key) {
    // Validate and split the encrypted field
    String[] parts = encryptedField.split("\\.");
    if (parts.length != 3) {
      throw new IllegalArgumentException(
          "Invalid encrypted field format. Expected: IV.Ciphertext.AuthTag, got " + parts.length + " parts");
    }

    try {
      // Decode each part from Base64
      byte[] iv = Base64.getDecoder().decode(parts[0]);
      byte[] ciphertext = Base64.getDecoder().decode(parts[1]);
      byte[] authTag = Base64.getDecoder().decode(parts[2]);

      // Combine ciphertext and auth tag (GCM expects them together)
      byte[] ciphertextWithTag = new byte[ciphertext.length + authTag.length];
      System.arraycopy(ciphertext, 0, ciphertextWithTag, 0, ciphertext.length);
      System.arraycopy(authTag, 0, ciphertextWithTag, ciphertext.length, authTag.length);

      // Initialize cipher for decryption
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.DECRYPT_MODE, key, gcmSpec);

      // Decrypt and return plaintext
      byte[] plaintext = cipher.doFinal(ciphertextWithTag);
      return new String(plaintext, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt field: " + e.getMessage(), e);
    }
  }
}

package company_backend.rest_api_security.crypto;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;

/**
 * Hybrid Decryption Helper - Main utility for decrypting REST API requests.
 *
 * <p>This helper orchestrates the hybrid decryption flow, coordinating between
 * JWE parsing, KMS key unwrapping, and field decryption. It provides a simple
 * API for decrypting sensitive fields received from clients.</p>
 *
 * <h3>Decryption Flow:</h3>
 * <ol>
 *   <li>Parse the JWE header to extract the encrypted key</li>
 *   <li>Send encrypted key to AWS KMS for unwrapping (1 API call)</li>
 *   <li>Use the unwrapped key to decrypt each field locally (no more KMS calls)</li>
 * </ol>
 *
 * <h3>Performance:</h3>
 * <ul>
 *   <li><b>1 KMS Call:</b> Only one network call to AWS, regardless of field count</li>
 *   <li><b>Fast Local Decryption:</b> AES decryption is extremely fast</li>
 *   <li><b>Efficient:</b> Key is cached for all fields in the same request</li>
 * </ul>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * // In your service or controller
 * String header = request.getHeader("X-Encryption-Key");
 *
 * // Decrypt all fields at once
 * DecryptedFields fields = decryptionHelper.decryptAll(
 *     header,
 *     encryptedDob,
 *     encryptedCreditCard,
 *     encryptedSsn
 * );
 *
 * // Or decrypt individually
 * String dob = decryptionHelper.decryptField(header, encryptedDob);
 * }</pre>
 */
@Component
public class HybridDecryptionHelper {

  private static final Logger log = LoggerFactory.getLogger(HybridDecryptionHelper.class);

  private final KmsKeyUnwrapper kmsKeyUnwrapper;

  /**
   * Creates a new Hybrid Decryption Helper.
   *
   * @param kmsKeyUnwrapper The KMS key unwrapper (injected by Spring)
   */
  public HybridDecryptionHelper(KmsKeyUnwrapper kmsKeyUnwrapper) {
    this.kmsKeyUnwrapper = kmsKeyUnwrapper;
  }

  /**
   * Decrypts a single encrypted field.
   *
   * <p>Extracts the key from the JWE header, unwraps it via KMS, then
   * decrypts the field. For multiple fields, use {@link #decryptAll} instead
   * to avoid redundant KMS calls.</p>
   *
   * @param encryptionHeader The X-Encryption-Key header value (JWE format)
   * @param encryptedField   The encrypted field (iv.ciphertext.authTag format)
   * @return The decrypted plaintext value
   * @throws RuntimeException if decryption fails
   */
  public String decryptField(String encryptionHeader, String encryptedField) {
    SecretKey key = unwrapKeyFromHeader(encryptionHeader);
    return FieldDecryptor.decrypt(encryptedField, key);
  }

  /**
   * Decrypts multiple fields using a single KMS call.
   *
   * <p>This is the recommended method when you have multiple encrypted fields.
   * It extracts and unwraps the key once, then decrypts all fields locally.</p>
   *
   * @param encryptionHeader  The X-Encryption-Key header value (JWE format)
   * @param encryptedDob      Encrypted date of birth
   * @param encryptedCreditCard Encrypted credit card number
   * @param encryptedSsn      Encrypted SSN
   * @return A record containing all decrypted values
   * @throws RuntimeException if decryption fails
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * DecryptedFields fields = helper.decryptAll(header, dob, card, ssn);
   * System.out.println(fields.creditCard()); // "4111111111111234"
   * }</pre>
   */
  public DecryptedFields decryptAll(
      String encryptionHeader,
      String encryptedDob,
      String encryptedCreditCard,
      String encryptedSsn
  ) {
    log.info("Decrypting all PII fields");

    // Step 1: Unwrap the key (1 KMS call)
    SecretKey key = unwrapKeyFromHeader(encryptionHeader);

    // Step 2: Decrypt each field locally (no KMS calls)
    log.debug("Decrypting individual fields with unwrapped key");

    String dob = FieldDecryptor.decrypt(encryptedDob, key);
    String creditCard = FieldDecryptor.decrypt(encryptedCreditCard, key);
    String ssn = FieldDecryptor.decrypt(encryptedSsn, key);

    log.info("All fields decrypted successfully");

    return new DecryptedFields(dob, creditCard, ssn);
  }

  /**
   * Extracts and unwraps the encryption key from the JWE header.
   *
   * @param encryptionHeader The X-Encryption-Key header value
   * @return The unwrapped AES secret key
   */
  private SecretKey unwrapKeyFromHeader(String encryptionHeader) {
    if (encryptionHeader == null || encryptionHeader.isBlank()) {
      throw new IllegalArgumentException("X-Encryption-Key header is missing or empty");
    }

    log.debug("Parsing JWE header and unwrapping key");

    // Parse JWE to extract encrypted key bytes
    byte[] encryptedKey = JweParser.extractEncryptedKey(encryptionHeader);

    // Unwrap via KMS (this is the only KMS API call)
    return kmsKeyUnwrapper.unwrap(encryptedKey);
  }

  /**
   * Record containing decrypted PII field values.
   *
   * @param dateOfBirth  The decrypted date of birth
   * @param creditCard   The decrypted credit card number
   * @param ssn          The decrypted SSN
   */
  public record DecryptedFields(
      String dateOfBirth,
      String creditCard,
      String ssn
  ) {}
}

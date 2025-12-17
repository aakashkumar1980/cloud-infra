package server.restapi_data_security.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import server.restapi_data_security.crypto.AwsKmsDecryptionService;
import server.restapi_data_security.crypto.FieldDecryptor;
import server.restapi_data_security.crypto.JwtParser;

import javax.crypto.SecretKey;

/**
 * Hybrid Decryption Service - Main utility for decrypting REST API requests.
 *
 * <h2>BACKEND STEPS 5-7: Complete Server-Side Decryption Flow</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │                    SERVER DECRYPTION ORCHESTRATION                     │
 * │                                                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 5: extractEncryptedAESKeyFromJwtMetadata()                  │ │
 * │  │ ► JwtParser.extractAESEncryptionKey(jwtEncryptionMetadata)        │ │
 * │  │ ► Output: byte[] encryptedAESKey                                 │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 6: unwrapAESKeyViaKMS()                                     │ │
 * │  │ ► awsKmsDecryptionService.decryptEncryptedAESEncryptionKeyByAWSKMS(encryptedKey)  │ │
 * │  │ ► 1 KMS API call to decrypt using RSA private key in HSM        │ │
 * │  │ ► Output: SecretKey randomAESEncryptionKey                       │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 7: decryptField()                                           │ │
 * │  │ ► FieldDecryptor.decrypt(encryptedField, randomAESEncryptionKey) │ │
 * │  │ ► Local AES-256-GCM decryption (no additional KMS calls)         │ │
 * │  │ ► Output: plaintext value                                        │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                                                                        │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Performance:</h3>
 * <ul>
 *   <li><b>1 KMS Call:</b> Only one network call to AWS, regardless of field count</li>
 *   <li><b>Fast Local Decryption:</b> AES decryption is extremely fast</li>
 *   <li><b>Efficient:</b> Key is cached for all fields in the same request</li>
 * </ul>
 */
@Service
public class HybridDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(HybridDecryptionService.class);

  private final JwtParser jwtParser;
  private final AwsKmsDecryptionService awsKmsDecryptionService;
  private final FieldDecryptor fieldDecryptor;

  public HybridDecryptionService(
      JwtParser jwtParser,
      AwsKmsDecryptionService awsKmsDecryptionService,
      FieldDecryptor fieldDecryptor
  ) {
    this.jwtParser = jwtParser;
    this.awsKmsDecryptionService = awsKmsDecryptionService;
    this.fieldDecryptor = fieldDecryptor;
  }

  /**
   * Decrypts multiple fields using a single KMS call.
   *
   * @param jwtEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @param encryptedDob          Encrypted date of birth
   * @param encryptedCreditCard   Encrypted credit card number
   * @param encryptedSsn          Encrypted SSN
   * @return A record containing all decrypted values
   */
  public DecryptedFields decryptAll(
      String jwtEncryptionMetadata,
      String encryptedDob,
      String encryptedCreditCard,
      String encryptedSsn
  ) {
    log.info("Decrypting all PII fields (1 KMS call for all fields)");

    // STEP 5+6: Extract and unwrap the AES key (1 KMS call)
    SecretKey aesEncryptionKey = extractAESEncryptionKeyFromJwtMetadata(jwtEncryptionMetadata);

    // STEP 7: Decrypt each field locally (no additional KMS calls)
    String dob = fieldDecryptor.decrypt(encryptedDob, aesEncryptionKey);
    String creditCard = fieldDecryptor.decrypt(encryptedCreditCard, aesEncryptionKey);
    String ssn = fieldDecryptor.decrypt(encryptedSsn, aesEncryptionKey);

    log.info("All fields decrypted successfully");
    return new DecryptedFields(dob, creditCard, ssn);
  }

  /**
   * Decrypts a single encrypted field.
   *
   * @param jwtEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @param encryptedField        The encrypted field (iv.encryptedText.authTag format)
   * @return The decrypted plaintext value
   */
  public String decryptField(String jwtEncryptionMetadata, String encryptedField) {
    SecretKey randomAESEncryptionKey = extractAESEncryptionKeyFromJwtMetadata(jwtEncryptionMetadata);
    return fieldDecryptor.decrypt(encryptedField, randomAESEncryptionKey);
  }

  /**
   * Extracts and unwraps the AES encryption key from the JWT metadata header.
   */
  private SecretKey extractAESEncryptionKeyFromJwtMetadata(String jwtEncryptionMetadata) {
    if (jwtEncryptionMetadata == null || jwtEncryptionMetadata.isBlank()) {
      throw new IllegalArgumentException("X-Encryption-Key header is missing or empty");
    }

    // STEP 5: Parse JWT metadata to extract encrypted key bytes
    byte[] encryptedAESEncryptionKey = jwtParser.extractAESEncryptionKey(jwtEncryptionMetadata);

    // STEP 6: Unwrap via KMS (this is the only KMS API call)
    return awsKmsDecryptionService.decryptEncryptedAESEncryptionKeyByAWSKMS(encryptedAESEncryptionKey);
  }

  /**
   * Record containing decrypted PII field values.
   */
  public record DecryptedFields(String dateOfBirth, String creditCard, String ssn) {}
}

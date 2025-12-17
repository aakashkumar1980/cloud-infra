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
 * │  │ STEP 5: extractJweComponents()                                   │ │
 * │  │ ► JwtParser.extractJweComponents(jwtEncryptionMetadata)          │ │
 * │  │ ► Output: JweComponents (aesCekEncryptedKey, iv, ciphertext...)  │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 6: decryptAesCekAndExtractAesKey()                          │ │
 * │  │ ► awsKmsDecryptionService.decryptAesCekAndExtractAesKey(jweComp) │ │
 * │  │ ► 1 KMS API call to decrypt aesCekEncryptedKey in HSM            │ │
 * │  │ ► Output: SecretKey aesEncryptionKey                             │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 7: decryptField()                                           │ │
 * │  │ ► FieldDecryptor.decrypt(encryptedField, aesEncryptionKey)       │ │
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

    // STEP 5+6: Extract JWE components and decrypt AES CEK to get aesEncryptionKey (1 KMS call)
    SecretKey aesEncryptionKey = extractAesEncryptionKeyFromJwtMetadata(jwtEncryptionMetadata);

    // STEP 7: Decrypt each field locally using aesEncryptionKey (no additional KMS calls)
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
    SecretKey aesEncryptionKey = extractAesEncryptionKeyFromJwtMetadata(jwtEncryptionMetadata);
    return fieldDecryptor.decrypt(encryptedField, aesEncryptionKey);
  }

  /**
   * Extracts and decrypts the AES encryption key from the JWT metadata header.
   *
   * <p>This method:</p>
   * <ol>
   *   <li>Parses the JWE to extract aesCekEncryptedKey, iv, ciphertext, authTag, aad</li>
   *   <li>Decrypts aesCekEncryptedKey via KMS to get aesCekEncryptionKey</li>
   *   <li>Uses aesCekEncryptionKey to decrypt the JWE payload → aesEncryptionKey</li>
   * </ol>
   *
   * @param jwtEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @return The decrypted AES encryption key for field decryption
   */
  private SecretKey extractAesEncryptionKeyFromJwtMetadata(String jwtEncryptionMetadata) {
    if (jwtEncryptionMetadata == null || jwtEncryptionMetadata.isBlank()) {
      throw new IllegalArgumentException("X-Encryption-Key header is missing or empty");
    }

    // STEP 5: Parse JWT metadata to extract JWE components (aesCekEncryptedKey, iv, ciphertext, authTag, aad)
    JwtParser.JweComponents jweComponents = jwtParser.extractJweComponents(jwtEncryptionMetadata);

    // STEP 6: Decrypt aesCekEncryptedKey via KMS, then decrypt JWE payload to get aesEncryptionKey
    return awsKmsDecryptionService.decryptAesCekAndExtractAesKey(jweComponents);
  }

  /**
   * Record containing decrypted PII field values.
   */
  public record DecryptedFields(String dateOfBirth, String creditCard, String ssn) {}
}

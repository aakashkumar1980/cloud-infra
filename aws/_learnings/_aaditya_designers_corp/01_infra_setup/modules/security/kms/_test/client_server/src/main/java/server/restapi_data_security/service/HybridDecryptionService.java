package server.restapi_data_security.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import server.restapi_data_security.crypto.AwsKmsDecryptionService;
import server.restapi_data_security.crypto.FieldDecryptor;
import server.restapi_data_security.crypto.JwtParser;

import javax.crypto.SecretKey;

/**
 * Hybrid Decryption Service - Orchestrates server-side decryption.
 *
 * <h2>BACKEND STEPS 5-7: Server-Side Decryption Flow</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │                    SERVER DECRYPTION ORCHESTRATION                     │
 * │                                                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 5: Extract JWE Components                                   │ │
 * │  │ ► JwtParser.extractJweComponents(jwtEncryptionMetadata)          │ │
 * │  │ ► Output: JweComponents (encryptedCek, iv, ciphertext...)        │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 6: Extract DEK via KMS                                      │ │
 * │  │ ► awsKmsDecryptionService.extractDataEncryptionKey(jweComp)      │ │
 * │  │ ► 1 KMS API call to decrypt encryptedCek in HSM                  │ │
 * │  │ ► Output: SecretKey dataEncryptionKey (DEK)                      │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 7: Decrypt Fields                                           │ │
 * │  │ ► FieldDecryptor.decrypt(encryptedField, dataEncryptionKey)      │ │
 * │  │ ► Local AES-256-GCM decryption (no additional KMS calls)         │ │
 * │  │ ► Output: plaintext value                                        │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                                                                        │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Performance:</h3>
 * <ul>
 *   <li><b>1 KMS Call:</b> Only one network call to AWS per request</li>
 *   <li><b>Fast Local Decryption:</b> AES decryption is extremely fast</li>
 *   <li><b>Efficient:</b> DEK is reused for all fields in the same request</li>
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

    // STEP 5+6: Extract DEK from JWE via KMS (1 KMS call)
    SecretKey dataEncryptionKey = extractDataEncryptionKey(jwtEncryptionMetadata);

    // STEP 7: Decrypt each field locally using DEK (no additional KMS calls)
    String dob = fieldDecryptor.decrypt(encryptedDob, dataEncryptionKey);
    String creditCard = fieldDecryptor.decrypt(encryptedCreditCard, dataEncryptionKey);
    String ssn = fieldDecryptor.decrypt(encryptedSsn, dataEncryptionKey);

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
    SecretKey dataEncryptionKey = extractDataEncryptionKey(jwtEncryptionMetadata);
    return fieldDecryptor.decrypt(encryptedField, dataEncryptionKey);
  }

  /**
   * Extracts the Data Encryption Key (DEK) from the JWT metadata header.
   *
   * <p>Two-step process:</p>
   * <ol>
   *   <li>Parse JWE to extract encryptedCek, iv, ciphertext, authTag, aad</li>
   *   <li>Decrypt encryptedCek via KMS, then decrypt payload → dataEncryptionKey</li>
   * </ol>
   *
   * @param jwtEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @return The Data Encryption Key (DEK) for field decryption
   */
  private SecretKey extractDataEncryptionKey(String jwtEncryptionMetadata) {
    if (jwtEncryptionMetadata == null || jwtEncryptionMetadata.isBlank()) {
      throw new IllegalArgumentException("X-Encryption-Key header is missing or empty");
    }

    // STEP 5: Parse JWT metadata to extract JWE components
    JwtParser.JweComponents jweComponents = jwtParser.extractJweComponents(jwtEncryptionMetadata);

    // STEP 6: Extract DEK via KMS
    return awsKmsDecryptionService.extractDataEncryptionKey(jweComponents);
  }

  /**
   * Record containing decrypted PII field values.
   */
  public record DecryptedFields(String dateOfBirth, String creditCard, String ssn) {}
}

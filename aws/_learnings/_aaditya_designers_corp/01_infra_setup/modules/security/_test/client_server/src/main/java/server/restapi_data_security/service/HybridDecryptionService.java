package server.restapi_data_security.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import server.restapi_data_security.crypto.AwsKmsDecryptionService;
import server.restapi_data_security.crypto.FieldDecryptor;
import server.restapi_data_security.crypto.JweParser;

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
 * │  │ ► JweParser.extractJweComponents(jweEncryptionMetadata)          │ │
 * │  │ ► Output: JweComponents (encryptedCek, iv, ciphertext...)        │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 6: Extract AES DEK via KMS                                  │ │
 * │  │ ► awsKmsDecryptionService.extractAesDataEncryptionKey(jweComp)   │ │
 * │  │ ► 1 KMS API call to decrypt encryptedCek in HSM                  │ │
 * │  │ ► Output: SecretKey aesDataEncryptionKey (DEK)                   │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 7: Decrypt Fields                                           │ │
 * │  │ ► FieldDecryptor.decrypt(encryptedField, aesDataEncryptionKey)   │ │
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
 *   <li><b>Efficient:</b> AES DEK is reused for all fields in the same request</li>
 * </ul>
 */
@Service
public class HybridDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(HybridDecryptionService.class);

  private final JweParser jweParser;
  private final AwsKmsDecryptionService awsKmsDecryptionService;
  private final FieldDecryptor fieldDecryptor;

  public HybridDecryptionService(
      JweParser jweParser,
      AwsKmsDecryptionService awsKmsDecryptionService,
      FieldDecryptor fieldDecryptor
  ) {
    this.jweParser = jweParser;
    this.awsKmsDecryptionService = awsKmsDecryptionService;
    this.fieldDecryptor = fieldDecryptor;
  }

  /**
   * Decrypts multiple fields using a single KMS call.
   *
   * @param jweEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @param encryptedDob          Encrypted date of birth
   * @param encryptedCreditCard   Encrypted credit card number
   * @param encryptedSsn          Encrypted SSN
   * @return A record containing all decrypted values
   */
  public DecryptedFields decryptAll(
      String jweEncryptionMetadata,
      String encryptedDob,
      String encryptedCreditCard,
      String encryptedSsn
  ) {
    log.info("Decrypting all PII fields (1 KMS call for all fields)");

    // STEP 5+6: Extract AES DEK from JWE via KMS (1 KMS call)
    SecretKey aesDataEncryptionKey = extractAesDataEncryptionKey(jweEncryptionMetadata);

    // STEP 7: Decrypt each field locally using AES DEK (no additional KMS calls)
    String dob = fieldDecryptor.decrypt(encryptedDob, aesDataEncryptionKey);
    String creditCard = fieldDecryptor.decrypt(encryptedCreditCard, aesDataEncryptionKey);
    String ssn = fieldDecryptor.decrypt(encryptedSsn, aesDataEncryptionKey);

    log.info("All fields decrypted successfully");
    return new DecryptedFields(dob, creditCard, ssn);
  }

  /**
   * Decrypts a single encrypted field.
   *
   * @param jweEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @param encryptedField        The encrypted field (BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag))
   * @return The decrypted plaintext value
   */
  public String decryptField(String jweEncryptionMetadata, String encryptedField) {
    SecretKey aesDataEncryptionKey = extractAesDataEncryptionKey(jweEncryptionMetadata);
    return fieldDecryptor.decrypt(encryptedField, aesDataEncryptionKey);
  }

  /**
   * Extracts the AES Data Encryption Key (DEK) from the JWE metadata header.
   *
   * <p>Two-step process:</p>
   * <ol>
   *   <li>Parse JWE to extract encryptedCek, iv, ciphertext, authTag, aad</li>
   *   <li>Decrypt encryptedCek via KMS, then decrypt payload → aesDataEncryptionKey</li>
   * </ol>
   *
   * @param jweEncryptionMetadata The X-Encryption-Key header value (JWE format)
   * @return The AES Data Encryption Key (DEK) for field decryption
   */
  private SecretKey extractAesDataEncryptionKey(String jweEncryptionMetadata) {
    if (jweEncryptionMetadata == null || jweEncryptionMetadata.isBlank()) {
      throw new IllegalArgumentException("X-Encryption-Key header is missing or empty");
    }

    // STEP 5: Parse JWE metadata to extract JWE components
    JweParser.JweComponents jweComponents = jweParser.extractJweComponents(jweEncryptionMetadata);

    // STEP 6: Extract AES DEK via KMS
    return awsKmsDecryptionService.extractAesDataEncryptionKey(jweComponents);
  }

  /**
   * Record containing decrypted PII field values.
   */
  public record DecryptedFields(String dateOfBirth, String creditCard, String ssn) {}
}

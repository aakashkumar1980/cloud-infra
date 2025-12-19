package server.restapi_data_security.multi_fields_encryption.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import server.restapi_data_security.multi_fields_encryption.crypto.DEKDecryptorAndUnwrapper;
import server.restapi_data_security.multi_fields_encryption.crypto.FieldDecryptor;

import javax.crypto.SecretKey;

/**
 * Hybrid Decryption Service (Multi-Fields) - Server-side decryption orchestration.
 *
 * <h2>SERVER STEPS 5-6: Multi-Field Decryption Flow</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │            MULTI-FIELD DECRYPTION (NO JWE/CEK)                         │
 * │                                                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 5: Unwrap DEK via KMS (1 API call)                          │ │
 * │  │ ► dekDecryptorAndUnwrapper.unwrapAndDecryptDataEncryptionKeyViaAWSKMS(encryptedDekBase64)                  │ │
 * │  │ ► KMS decrypts encryptedDek directly → aesDataEncryptionKey      │ │
 * │  │ ► NO CEK, NO JWE parsing!                                        │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 6: Decrypt Fields Locally                                   │ │
 * │  │ ► fieldDecryptor.decrypt(encryptedField, aesDataEncryptionKey)   │ │
 * │  │ ► Local AES-256-GCM decryption (no additional KMS calls)         │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                                                                        │
 * │  Comparison with JWE approach:                                        │
 * │  ─────────────────────────────────────────────────────────────────    │
 * │  JWE:        encryptedCek → (KMS) → cek → (AES) → DEK                │
 * │  Direct RSA: encryptedDek → (KMS) → DEK                              │
 * │              ↑ Simpler! One less decryption step                      │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Service("multiFieldsHybridDecryptionService")
public class HybridDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(HybridDecryptionService.class);

  private final DEKDecryptorAndUnwrapper dekDecryptorAndUnwrapper;
  private final FieldDecryptor fieldDecryptor;

  public HybridDecryptionService(
      @Qualifier("multiFieldsRsaKeyUnwrapper") DEKDecryptorAndUnwrapper dekDecryptorAndUnwrapper,
      @Qualifier("multiFieldsFieldDecryptor") FieldDecryptor fieldDecryptor
  ) {
    this.dekDecryptorAndUnwrapper = dekDecryptorAndUnwrapper;
    this.fieldDecryptor = fieldDecryptor;
  }

  /**
   * Decrypts multiple fields using a single KMS call.
   *
   * @param encryptedDataEncryptionKey  The X-Encryption-Key header value (BASE64 RSA-encrypted DEK)
   * @param encryptedDob        Encrypted date of birth
   * @param encryptedCreditCard Encrypted credit card number
   * @param encryptedSsn        Encrypted SSN
   * @return A record containing all decrypted values
   */
  public DecryptedFields decryptAll(
      String encryptedDataEncryptionKey,
      String encryptedDob,
      String encryptedCreditCard,
      String encryptedSsn
  ) {
    log.info("Decrypting all PII fields (1 KMS call - direct RSA, no CEK)");

    // STEP 5: Unwrap DEK via KMS (direct RSA decryption)
    SecretKey dataEncryptionKey = dekDecryptorAndUnwrapper.unwrapAndDecryptDataEncryptionKeyViaAWSKMS(encryptedDataEncryptionKey);

    // STEP 6: Decrypt each field locally using DEK
    String dob = fieldDecryptor.decrypt(encryptedDob, dataEncryptionKey);
    String creditCard = fieldDecryptor.decrypt(encryptedCreditCard, dataEncryptionKey);
    String ssn = fieldDecryptor.decrypt(encryptedSsn, dataEncryptionKey);

    log.info("All fields decrypted successfully");
    return new DecryptedFields(dob, creditCard, ssn);
  }

  /**
   * Decrypts a single encrypted field.
   *
   * @param encryptedDataEncryptionKey The X-Encryption-Key header value
   * @param encryptedField     The encrypted field
   * @return The decrypted plaintext value
   */
  public String decryptField(String encryptedDataEncryptionKey, String encryptedField) {
    SecretKey aesDataEncryptionKey = dekDecryptorAndUnwrapper.unwrapAndDecryptDataEncryptionKeyViaAWSKMS(encryptedDataEncryptionKey);
    return fieldDecryptor.decrypt(encryptedField, aesDataEncryptionKey);
  }

  /**
   * Record containing decrypted PII field values.
   */
  public record DecryptedFields(String dateOfBirth, String creditCard, String ssn) {}
}

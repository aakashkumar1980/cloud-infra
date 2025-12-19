package server.restapi_data_security.all_fields_encryption.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import server.restapi_data_security.all_fields_encryption.crypto.JWEDecryptor;

/**
 * Hybrid Decryption Service (All-Fields) - Server-side JWE decryption.
 *
 * <h2>SERVER STEPS 3-4: All-Fields JWE Decryption Flow</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │              ALL-FIELDS DECRYPTION (WITH CEK)                          │
 * │                                                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 3: Decrypt CEK via KMS (1 API call)                         │ │
 * │  │ ► Parse JWE to extract encryptedCek                              │ │
 * │  │ ► KMS decrypts encryptedCek → aesContentEncryptionKey (CEK)      │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                              ▼                                        │
 * │  ┌──────────────────────────────────────────────────────────────────┐ │
 * │  │ STEP 4: Decrypt Payload Locally                                  │ │
 * │  │ ► AES-256-GCM decrypt ciphertext with CEK                        │ │
 * │  │ ► Output: Original JSON payload                                  │ │
 * │  └──────────────────────────────────────────────────────────────────┘ │
 * │                                                                        │
 * │  Comparison with Multi-Fields:                                        │
 * │  ─────────────────────────────────────────────────────────────────    │
 * │  Multi-Fields: Header=encryptedDek, Body=encrypted fields            │
 * │  All-Fields:   Body=JWE (entire encrypted payload)                   │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Service("allFieldsHybridDecryptionService")
public class HybridDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(HybridDecryptionService.class);

  private final JWEDecryptor jweDecryptor;

  public HybridDecryptionService(
      @Qualifier("allFieldsJweDecryptor") JWEDecryptor jweDecryptor
  ) {
    this.jweDecryptor = jweDecryptor;
  }

  /**
   * Decrypts a JWE request body and returns the original JSON payload.
   *
   * @param jweString The JWE compact serialization (entire request body)
   * @return The decrypted JSON payload string
   */
  public String decryptPayload(String jweString) {
    log.info("Decrypting JWE payload (1 KMS call for CEK, then local AES)");

    String jsonPayload = jweDecryptor.decrypt(jweString);

    log.info("Payload decrypted successfully");
    return jsonPayload;
  }
}

package company_backend.rest_api_security.service;

import company_backend.rest_api_security.filter.EncryptionContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * API Decryption Service (Hybrid Encryption)
 *
 * Decrypts individual PII fields using AES-256-GCM with the DEK from EncryptionContext.
 *
 * Field Format: BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
 *
 * Flow:
 * 1. Get DEK from EncryptionContext (set by EncryptionFilter)
 * 2. Parse encrypted field: split into IV, ciphertext, authTag
 * 3. Decrypt using AES-256-GCM (local operation, no KMS call)
 *
 * Note: The DEK was already unwrapped from the X-Encryption-Key header by the
 * EncryptionFilter. This service only performs local AES decryption.
 */
@Service
public class APIDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(APIDecryptionService.class);

  private static final String AES_GCM_ALGORITHM = "AES/GCM/NoPadding";
  private static final int GCM_TAG_LENGTH_BITS = 128;  // 16 bytes

  /**
   * Decrypt an AES-GCM encrypted field
   *
   * @param encryptedField Field in format: BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
   * @return Decrypted plaintext string
   */
  public String decryptField(String encryptedField) {
    log.debug("Decrypting field with AES-GCM");

    // Get DEK from thread-local context
    SecretKey dek = EncryptionContext.getDek();
    if (dek == null) {
      throw new IllegalStateException("DEK not found in EncryptionContext. " +
          "Ensure X-Encryption-Key header is provided.");
    }

    try {
      // Parse field: IV.Ciphertext.AuthTag
      String[] parts = encryptedField.split("\\.");
      if (parts.length != 3) {
        throw new IllegalArgumentException(
            "Invalid encrypted field format. Expected: IV.Ciphertext.AuthTag");
      }

      byte[] iv = Base64.getDecoder().decode(parts[0]);
      byte[] ciphertext = Base64.getDecoder().decode(parts[1]);
      byte[] authTag = Base64.getDecoder().decode(parts[2]);

      log.debug("Parsed encrypted field - IV: {} bytes, Ciphertext: {} bytes, AuthTag: {} bytes",
          iv.length, ciphertext.length, authTag.length);

      // Combine ciphertext and authTag (GCM expects them together)
      byte[] ciphertextWithTag = new byte[ciphertext.length + authTag.length];
      System.arraycopy(ciphertext, 0, ciphertextWithTag, 0, ciphertext.length);
      System.arraycopy(authTag, 0, ciphertextWithTag, ciphertext.length, authTag.length);

      // Decrypt with AES-GCM
      Cipher cipher = Cipher.getInstance(AES_GCM_ALGORITHM);
      GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv);
      cipher.init(Cipher.DECRYPT_MODE, dek, gcmSpec);

      byte[] plaintext = cipher.doFinal(ciphertextWithTag);

      log.debug("Field decrypted successfully");
      return new String(plaintext, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt field: " + e.getMessage(), e);
    }
  }
}

package server.restapi_data_security.multi_fields_encryption.crypto;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.DecryptRequest;
import software.amazon.awssdk.services.kms.model.DecryptResponse;
import software.amazon.awssdk.services.kms.model.EncryptionAlgorithmSpec;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;

/**
 * DEK Decryptor and Unwrapper - Decrypts and unwraps AES DEK using AWS KMS RSA decryption.
 *
 * <h2>STEP 5 (SERVER): Unwrap DEK via AWS KMS</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  DIRECT RSA DECRYPTION (NO JWE/CEK)                                    │
 * │                                                                        │
 * │  Input: BASE64(encryptedDataEncryptionKey) from X-Encryption-Key header│
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Decode Base64 → encryptedDataEncryptionKey bytes                   │
 * │  2. Send to KMS for RSA-OAEP-256 decryption                            │
 * │  3. KMS decrypts using private key (never leaves HSM)                  │
 * │                                                                        │
 * │  Output: dataEncryptionKey (DEK) - 32 bytes                            │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Security:</h3>
 * <ul>
 *   <li>RSA private key <b>never leaves AWS KMS HSM</b></li>
 *   <li>This is the <b>ONLY KMS API call</b> per request</li>
 *   <li>Simpler than JWE: No CEK, no AES decryption of DEK</li>
 * </ul>
 */
@Component("multiFieldsDEKDecryptorAndUnwrapper")
public class DEKDecryptorAndUnwrapper {

  private final KmsClient kmsClient;
  private final String keyArn;

  public DEKDecryptorAndUnwrapper(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String keyArn
  ) {
    this.kmsClient = kmsClient;
    this.keyArn = keyArn;
  }

  /**
   * Unwraps the AES Data Encryption Key using AWS KMS.
   *
   * <h3>DECRYPT-RSA (RSA-OAEP-256 via AWS KMS):</h3>
   * <pre>
   * ┌─────────────────────────────────┐    ┌─────────────────────────────────────┐
   * │ encryptedDataEncryptionKey      │    │                                     │
   * │ (~512 bytes)                    │───►│           AWS KMS                   │
   * └─────────────────────────────────┘    │                                     │
   *                                        │  DecryptRequest:                    │
   * ┌─────────────────────────────────┐    │    keyId = keyArn                   │
   * │      keyArn                     │───►│    ciphertextBlob = encrypted DEK   │
   * │ (KMS key reference)             │    │    algorithm = RSAES_OAEP_SHA_256   │
   * └─────────────────────────────────┘    │                                     │
   *                                        │  ┌─────────────────────────────┐    │
   *                                        │  │ RSA Private Key (in HSM)   │    │
   *                                        │  │ NEVER leaves hardware!     │    │
   *                                        │  └─────────────────────────────┘    │
   *                                        │                                     │
   *                                        └──────────────────┬──────────────────┘
   *                                                           │
   *                                                           ▼
   *                                        ┌─────────────────────────────────────┐
   *                                        │ dataEncryptionKey (DEK)             │
   *                                        │ = 32 bytes (256-bit AES key)        │
   *                                        └─────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────┬─────────────────┬─────────────────────────────────────┬──────────────────────────┐
   * │ Operation      │ Algorithm       │ Input                               │ Output                   │
   * ├────────────────┼─────────────────┼─────────────────────────────────────┼──────────────────────────┤
   * │ DECRYPT-RSA    │ RSA-OAEP-256    │ encryptedDataEncryptionKey, keyArn  │ dataEncryptionKey (DEK)  │
   * │                │ (via AWS KMS)   │                                     │ (32 bytes)               │
   * └────────────────┴─────────────────┴─────────────────────────────────────┴──────────────────────────┘
   * </pre>
   *
   * <p><b>NOTE:</b> This is the ONLY KMS API call per request!</p>
   *
   * @param encryptedDataEncryptionKey BASE64-encoded RSA-encrypted DEK from header
   * @return The AES Data Encryption Key (DEK) for field decryption
   * @throws RuntimeException if decryption fails
   */
  public SecretKey unwrapAndDecryptDataEncryptionKeyViaAWSKMS(String encryptedDataEncryptionKey) {
    try {
      // Decode Base64 to get encrypted DEK bytes
      byte[] encryptedDataEncryptionKeyBytes = Base64.getDecoder().decode(encryptedDataEncryptionKey);

      // Build KMS decrypt request
      DecryptRequest request = DecryptRequest.builder()
          .keyId(keyArn)
          .ciphertextBlob(SdkBytes.fromByteArray(encryptedDataEncryptionKeyBytes))
          .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
          .build();

      // Decrypt via KMS (private key never leaves HSM)
      DecryptResponse response = kmsClient.decrypt(request);
      byte[] dekBytes = response.plaintext().asByteArray();

      // Return as SecretKey
      return new SecretKeySpec(dekBytes, "AES");

    } catch (Exception e) {
      throw new RuntimeException("Failed to unwrap DEK via KMS: " + e.getMessage(), e);
    }
  }
}

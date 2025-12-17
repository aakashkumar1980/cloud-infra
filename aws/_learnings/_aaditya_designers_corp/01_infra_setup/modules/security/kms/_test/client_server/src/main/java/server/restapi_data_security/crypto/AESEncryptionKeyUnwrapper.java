package server.restapi_data_security.crypto;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.DecryptRequest;
import software.amazon.awssdk.services.kms.model.DecryptResponse;
import software.amazon.awssdk.services.kms.model.EncryptionAlgorithmSpec;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

/**
 * AES Encryption Key Unwrapper - Unwraps the AES encryption key using AWS KMS.
 *
 * <h2>STEP 6 (BACKEND): Unwrap AES Key via AWS KMS (1 API Call)</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  AES KEY UNWRAPPING VIA KMS                                            │
 * │                                                                        │
 * │  SERVER                               AWS KMS                          │
 * │    │                                    │                              │
 * │    │ ─── DecryptRequest ──────────────► │                              │
 * │    │     (encryptedAESKey, keyArn,      │                              │
 * │    │      RSAES_OAEP_SHA_256)           │                              │
 * │    │                                    │                              │
 * │    │                                    │  ┌────────────────────────┐  │
 * │    │                                    │  │ RSA Private Key        │  │
 * │    │                                    │  │ (NEVER leaves HSM)     │  │
 * │    │                                    │  └────────────────────────┘  │
 * │    │                                    │                              │
 * │    │ ◄── DecryptResponse ────────────── │                              │
 * │    │     (plaintext AES key: 256-bit)   │                              │
 * │    │                                    │                              │
 * │                                                                        │
 * │  Input:  byte[] encryptedAESKey (from JwtParser Step 5)               │
 * │  Output: SecretKey randomAESEncryptionKey (for field decryption)      │
 * │                                                                        │
 * │  NOTE: This is the ONLY KMS API call per request!                     │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Use KMS?</h3>
 * <ul>
 *   <li><b>Security:</b> Private key NEVER leaves AWS KMS hardware (HSM)</li>
 *   <li><b>Audit:</b> All key usage is logged in CloudTrail</li>
 *   <li><b>Compliance:</b> Meets regulatory requirements (PCI-DSS, HIPAA)</li>
 * </ul>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * byte[] encryptedKey = jwtParser.extractEncryptedAESKey(jwtEncryptionMetadata);
 * SecretKey aesKey = aesEncryptionKeyUnwrapper.unwrapEncryptedAESKey(encryptedKey);
 * String plaintext = fieldDecryptor.decrypt(encryptedField, aesKey);
 * }</pre>
 */
@Component
public class AESEncryptionKeyUnwrapper {

  private static final Logger log = LoggerFactory.getLogger(AESEncryptionKeyUnwrapper.class);

  private final KmsClient kmsClient;
  private final String keyArn;

  /**
   * Creates a new AES Encryption Key Unwrapper.
   *
   * @param kmsClient The AWS KMS client (injected by Spring)
   * @param keyArn    The ARN of the asymmetric KMS key (from application.yml)
   */
  public AESEncryptionKeyUnwrapper(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String keyArn
  ) {
    this.kmsClient = kmsClient;
    this.keyArn = keyArn;
  }

  /**
   * Unwraps an encrypted AES key using AWS KMS.
   *
   * @param encryptedAESKey The RSA-encrypted AES key bytes (from JwtParser)
   * @return The unwrapped AES-256 secret key
   * @throws RuntimeException if KMS decryption fails
   */
  public SecretKey unwrapEncryptedAESKey(byte[] encryptedAESKey) {
    log.debug("Unwrapping key via KMS (encrypted key size: {} bytes)", encryptedAESKey.length);

    try {
      // Build KMS decrypt request
      DecryptRequest request = DecryptRequest.builder()
          .keyId(keyArn)
          .ciphertextBlob(SdkBytes.fromByteArray(encryptedAESKey))
          .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
          .build();

      // Call KMS to unwrap the key
      DecryptResponse response = kmsClient.decrypt(request);
      byte[] keyBytes = response.plaintext().asByteArray();

      log.debug("Key unwrapped successfully (key size: {} bytes)", keyBytes.length);

      // Convert raw bytes to AES SecretKey
      return new SecretKeySpec(keyBytes, "AES");

    } catch (Exception e) {
      log.error("Failed to unwrap key via KMS: {}", e.getMessage());
      throw new RuntimeException("KMS key unwrap failed: " + e.getMessage(), e);
    }
  }
}

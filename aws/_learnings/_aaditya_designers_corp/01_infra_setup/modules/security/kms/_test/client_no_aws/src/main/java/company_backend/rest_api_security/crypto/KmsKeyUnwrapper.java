package company_backend.rest_api_security.crypto;

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
 * KMS Key Unwrapper - Unwraps the encryption key using AWS KMS.
 *
 * <p>When a client sends an encrypted request, they wrap the AES encryption
 * key using the server's RSA public key. This utility sends that wrapped key
 * to AWS KMS, which uses the private RSA key (stored securely in hardware)
 * to unwrap it.</p>
 *
 * <h3>Why Use KMS?</h3>
 * <ul>
 *   <li><b>Security:</b> Private key NEVER leaves AWS KMS hardware (HSM)</li>
 *   <li><b>Audit:</b> All key usage is logged in CloudTrail</li>
 *   <li><b>Compliance:</b> Meets regulatory requirements (PCI-DSS, HIPAA)</li>
 * </ul>
 *
 * <h3>Flow:</h3>
 * <pre>
 * Client                    Server                    AWS KMS
 *   │                         │                          │
 *   │ ─── encrypted key ────► │                          │
 *   │                         │ ─── unwrap request ────► │
 *   │                         │                          │ (uses private key
 *   │                         │ ◄─── plaintext key ───── │  in HSM hardware)
 *   │                         │                          │
 * </pre>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * byte[] encryptedKey = JweParser.extractEncryptedKey(jweHeader);
 * SecretKey aesKey = kmsKeyUnwrapper.unwrap(encryptedKey);
 * String plaintext = FieldDecryptor.decrypt(encryptedField, aesKey);
 * }</pre>
 */
@Component
public class KmsKeyUnwrapper {

  private static final Logger log = LoggerFactory.getLogger(KmsKeyUnwrapper.class);

  private final KmsClient kmsClient;
  private final String keyArn;

  /**
   * Creates a new KMS Key Unwrapper.
   *
   * @param kmsClient The AWS KMS client (injected by Spring)
   * @param keyArn    The ARN of the asymmetric KMS key (from application.yml)
   */
  public KmsKeyUnwrapper(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String keyArn
  ) {
    this.kmsClient = kmsClient;
    this.keyArn = keyArn;
  }

  /**
   * Unwraps an encrypted AES key using AWS KMS.
   *
   * <p>Sends the RSA-encrypted key bytes to AWS KMS, which decrypts them
   * using the private key stored in the HSM. Returns a usable AES SecretKey
   * for decrypting the actual data fields.</p>
   *
   * <h4>Algorithm:</h4>
   * <p>Uses RSA-OAEP with SHA-256 (RSAES_OAEP_SHA_256), which matches
   * the algorithm used by the client to wrap the key.</p>
   *
   * @param encryptedKey The RSA-encrypted AES key bytes (from JweParser)
   * @return The unwrapped AES-256 secret key
   * @throws RuntimeException if KMS decryption fails
   *
   * <h4>KMS API Call:</h4>
   * <p>This method makes exactly ONE call to AWS KMS. The returned key can
   * then be used to decrypt multiple fields locally without additional
   * KMS calls.</p>
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * byte[] wrapped = JweParser.extractEncryptedKey(jweHeader);
   * SecretKey key = kmsKeyUnwrapper.unwrap(wrapped);
   * // key is now a 256-bit AES key
   * }</pre>
   */
  public SecretKey unwrap(byte[] encryptedKey) {
    log.debug("Unwrapping key via KMS (encrypted key size: {} bytes)", encryptedKey.length);

    try {
      // Build KMS decrypt request
      DecryptRequest request = DecryptRequest.builder()
          .keyId(keyArn)
          .ciphertextBlob(SdkBytes.fromByteArray(encryptedKey))
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

package company_backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.DecryptRequest;
import software.amazon.awssdk.services.kms.model.DecryptResponse;
import software.amazon.awssdk.services.kms.model.EncryptionAlgorithmSpec;

import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Decryption Service
 *
 * Decrypts data that was encrypted with the company's RSA public key.
 * Uses AWS KMS to decrypt with the private key (which never leaves KMS).
 *
 * Algorithm: RSA-OAEP with SHA-256 (RSAES_OAEP_SHA_256)
 */
@Service
public class DecryptionService {

  private static final Logger log = LoggerFactory.getLogger(DecryptionService.class);

  private final KmsClient kmsClient;
  private final String asymmetricKeyArn;

  public DecryptionService(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String asymmetricKeyArn
  ) {
    this.kmsClient = kmsClient;
    this.asymmetricKeyArn = asymmetricKeyArn;
  }

  /**
   * Decrypt RSA-encrypted data using KMS
   *
   * @param encryptedDataBase64 Data encrypted with public key (Base64 encoded)
   * @return Decrypted plaintext string
   */
  public String decrypt(String encryptedDataBase64) {
    log.info("Decrypting data with KMS");

    byte[] encryptedData = Base64.getDecoder().decode(encryptedDataBase64);
    log.debug("Encrypted data size: {} bytes", encryptedData.length);

    DecryptRequest decryptRequest = DecryptRequest.builder()
        .keyId(asymmetricKeyArn)
        .ciphertextBlob(SdkBytes.fromByteArray(encryptedData))
        .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
        .build();

    DecryptResponse response = kmsClient.decrypt(decryptRequest);

    String plaintext = new String(response.plaintext().asByteArray(), StandardCharsets.UTF_8);
    log.info("Data decrypted successfully");

    return plaintext;
  }
}

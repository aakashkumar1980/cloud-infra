package company_backend.rest_api_security.service;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import com.nimbusds.jose.util.Base64URL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.DecryptRequest;
import software.amazon.awssdk.services.kms.model.DecryptResponse;
import software.amazon.awssdk.services.kms.model.EncryptionAlgorithmSpec;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

/**
 * JWE Decryption Service
 *
 * Unwraps the DEK (Data Encryption Key) from a JWE token.
 *
 * JWE Structure: Header.EncryptedKey.IV.Ciphertext.AuthTag
 * - We only need the EncryptedKey part (DEK encrypted with RSA)
 * - Send EncryptedKey to KMS for decryption
 * - Return plaintext DEK for use with AES decryption
 *
 * Note: This is a "Key Unwrapping" operation - we're not decrypting the
 * JWE payload here, just extracting and decrypting the DEK.
 */
@Service
public class JweDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(JweDecryptionService.class);

  private final KmsClient kmsClient;
  private final String asymmetricKeyArn;

  public JweDecryptionService(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String asymmetricKeyArn
  ) {
    this.kmsClient = kmsClient;
    this.asymmetricKeyArn = asymmetricKeyArn;
  }

  /**
   * Unwrap DEK from JWE token using KMS
   *
   * @param jweToken The JWE token from X-Encryption-Key header
   * @return The plaintext DEK (AES-256 key) for decrypting fields
   */
  public SecretKey unwrapDek(String jweToken) throws Exception {
    log.debug("Parsing JWE token to extract encrypted DEK");

    // Parse JWE token (5 parts: Header.EncryptedKey.IV.Ciphertext.AuthTag)
    JWEObject jweObject = JWEObject.parse(jweToken);
    JWEHeader header = jweObject.getHeader();

    // Validate algorithm
    String alg = header.getAlgorithm().getName();
    if (!"RSA-OAEP-256".equals(alg)) {
      throw new IllegalArgumentException("Unsupported key encryption algorithm: " + alg + ". Expected RSA-OAEP-256");
    }

    log.debug("JWE Header - alg: {}, enc: {}", alg, header.getEncryptionMethod());

    // Extract encrypted DEK (second part of JWE)
    Base64URL encryptedKeyBase64 = jweObject.getEncryptedKey();
    byte[] encryptedDek = encryptedKeyBase64.decode();

    log.info("Unwrapping DEK via KMS (encrypted DEK size: {} bytes)", encryptedDek.length);

    // Decrypt DEK using KMS (RSA-OAEP-256)
    DecryptRequest decryptRequest = DecryptRequest.builder()
        .keyId(asymmetricKeyArn)
        .ciphertextBlob(SdkBytes.fromByteArray(encryptedDek))
        .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
        .build();

    DecryptResponse response = kmsClient.decrypt(decryptRequest);
    byte[] dekBytes = response.plaintext().asByteArray();

    log.info("DEK unwrapped successfully (DEK size: {} bytes)", dekBytes.length);

    // Create AES SecretKey from decrypted bytes
    return new SecretKeySpec(dekBytes, "AES");
  }
}

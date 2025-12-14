package company_backend.service;

import company_backend.dto.DecryptRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.DecryptRequest.Builder;
import software.amazon.awssdk.services.kms.model.DecryptResponse;
import software.amazon.awssdk.services.kms.model.EncryptionAlgorithmSpec;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * Decryption Service
 *
 * Handles the two-step decryption process:
 * 1. Decrypt the DEK using KMS (RSA private key in KMS)
 * 2. Decrypt the data using DEK (AES-GCM locally)
 */
@Service
public class DecryptionService {

    private static final Logger log = LoggerFactory.getLogger(DecryptionService.class);
    private static final int GCM_TAG_LENGTH_BITS = 128;

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
     * Decrypt data from 3rd party
     *
     * @param request Contains encrypted DEK, encrypted data, IV, and auth tag
     * @return Decrypted plaintext
     */
    public String decrypt(DecryptRequest request) throws Exception {
        log.info("Starting decryption process");

        // Step 1: Decrypt DEK using KMS
        byte[] encryptedDek = Base64.getDecoder().decode(request.encryptedDek());
        byte[] plaintextDek = decryptDekWithKms(encryptedDek);
        log.debug("DEK decrypted successfully, length: {} bytes", plaintextDek.length);

        // Step 2: Decrypt data using DEK (AES-GCM)
        byte[] encryptedData = Base64.getDecoder().decode(request.encryptedData());
        byte[] iv = Base64.getDecoder().decode(request.iv());
        byte[] authTag = Base64.getDecoder().decode(request.authTag());

        String plaintext = decryptDataWithDek(encryptedData, plaintextDek, iv, authTag);
        log.info("Data decrypted successfully");

        return plaintext;
    }

    /**
     * Step 1: Decrypt DEK using KMS asymmetric key
     * KMS uses the private key (which never leaves KMS) to decrypt
     */
    private byte[] decryptDekWithKms(byte[] encryptedDek) {
        log.debug("Decrypting DEK with KMS, encrypted DEK size: {} bytes", encryptedDek.length);

        Builder requestBuilder = software.amazon.awssdk.services.kms.model.DecryptRequest.builder()
                .keyId(asymmetricKeyArn)
                .ciphertextBlob(SdkBytes.fromByteArray(encryptedDek))
                .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256);

        DecryptResponse response = kmsClient.decrypt(requestBuilder.build());

        return response.plaintext().asByteArray();
    }

    /**
     * Step 2: Decrypt data using DEK (AES-GCM)
     * This happens locally, not in KMS
     */
    private String decryptDataWithDek(byte[] encryptedData, byte[] dek, byte[] iv, byte[] authTag)
            throws Exception {

        // Combine encrypted data with auth tag (GCM expects them together)
        ByteBuffer combined = ByteBuffer.allocate(encryptedData.length + authTag.length);
        combined.put(encryptedData);
        combined.put(authTag);
        byte[] cipherTextWithTag = combined.array();

        // Initialize AES-GCM cipher
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        SecretKeySpec keySpec = new SecretKeySpec(dek, "AES");
        GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv);

        cipher.init(Cipher.DECRYPT_MODE, keySpec, gcmSpec);

        byte[] plaintext = cipher.doFinal(cipherTextWithTag);

        return new String(plaintext, StandardCharsets.UTF_8);
    }
}

package com.aadityadesigners.kms.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.GetPublicKeyRequest;
import software.amazon.awssdk.services.kms.model.GetPublicKeyResponse;

import java.util.Base64;

/**
 * Service to export public key from KMS
 *
 * The public key is used by 3rd party clients to encrypt their DEK.
 * This key can be safely shared - it cannot be used for decryption.
 */
@Service
public class PublicKeyService {

    private static final Logger log = LoggerFactory.getLogger(PublicKeyService.class);

    private final KmsClient kmsClient;
    private final String asymmetricKeyArn;

    // Cache the public key (it doesn't change)
    private String cachedPublicKeyPem;
    private String cachedKeyId;

    public PublicKeyService(
            KmsClient kmsClient,
            @Value("${aws.kms.asymmetric-key-arn}") String asymmetricKeyArn
    ) {
        this.kmsClient = kmsClient;
        this.asymmetricKeyArn = asymmetricKeyArn;
    }

    /**
     * Get public key in PEM format
     * 3rd party uses this to encrypt their DEK
     */
    public String getPublicKeyPem() {
        if (cachedPublicKeyPem == null) {
            fetchPublicKey();
        }
        return cachedPublicKeyPem;
    }

    public String getKeyId() {
        if (cachedKeyId == null) {
            fetchPublicKey();
        }
        return cachedKeyId;
    }

    private void fetchPublicKey() {
        log.info("Fetching public key from KMS: {}", asymmetricKeyArn);

        GetPublicKeyRequest request = GetPublicKeyRequest.builder()
                .keyId(asymmetricKeyArn)
                .build();

        GetPublicKeyResponse response = kmsClient.getPublicKey(request);

        // Convert to PEM format
        byte[] publicKeyDer = response.publicKey().asByteArray();
        String base64Key = Base64.getEncoder().encodeToString(publicKeyDer);

        // Format as PEM
        StringBuilder pem = new StringBuilder();
        pem.append("-----BEGIN PUBLIC KEY-----\n");
        // Split into 64-character lines
        for (int i = 0; i < base64Key.length(); i += 64) {
            pem.append(base64Key, i, Math.min(i + 64, base64Key.length()));
            pem.append("\n");
        }
        pem.append("-----END PUBLIC KEY-----");

        cachedPublicKeyPem = pem.toString();
        cachedKeyId = response.keyId();

        log.info("Public key fetched successfully. KeyId: {}", cachedKeyId);
        log.debug("Key spec: {}, Algorithm: {}",
                response.keySpec(),
                response.encryptionAlgorithms());
    }
}

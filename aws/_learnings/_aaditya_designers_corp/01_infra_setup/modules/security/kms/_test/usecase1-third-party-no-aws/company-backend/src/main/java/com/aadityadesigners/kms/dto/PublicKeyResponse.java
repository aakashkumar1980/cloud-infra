package com.aadityadesigners.kms.dto;

/**
 * Response containing the public key for 3rd party clients
 */
public record PublicKeyResponse(
        String publicKeyPem,
        String keyId,
        String algorithm,
        String instructions
) {
    public static PublicKeyResponse of(String publicKeyPem, String keyId) {
        return new PublicKeyResponse(
                publicKeyPem,
                keyId,
                "RSA_4096 with OAEP_SHA_256",
                "Use this public key to encrypt your DEK (Data Encryption Key). " +
                "Encrypt your data with AES-GCM using the DEK, then send both encrypted DEK and encrypted data to POST /api/v1/decrypt"
        );
    }
}

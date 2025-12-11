package com.aadityadesigners.kms.service;

import com.amazonaws.encryptionsdk.AwsCrypto;
import com.amazonaws.encryptionsdk.CryptoResult;
import com.amazonaws.encryptionsdk.kmssdkv2.KmsMasterKeyProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Map;

/**
 * KMS Encryption Service using AWS Encryption SDK
 *
 * This service implements ENVELOPE ENCRYPTION:
 *
 * ┌─────────────────────────────────────────────────────────────────┐
 * │ ENCRYPTION FLOW:                                                │
 * │                                                                 │
 * │ 1. SDK calls KMS → GenerateDataKey                             │
 * │    └── Returns: Plaintext DEK + Encrypted DEK                  │
 * │                                                                 │
 * │ 2. SDK encrypts your data locally using Plaintext DEK (AES)    │
 * │                                                                 │
 * │ 3. SDK packages: Encrypted Data + Encrypted DEK + Metadata     │
 * │    └── Plaintext DEK is discarded (never stored)               │
 * │                                                                 │
 * │ Result: Single blob containing everything needed for decryption│
 * └─────────────────────────────────────────────────────────────────┘
 *
 * ┌─────────────────────────────────────────────────────────────────┐
 * │ DECRYPTION FLOW:                                                │
 * │                                                                 │
 * │ 1. SDK extracts Encrypted DEK from the blob                    │
 * │                                                                 │
 * │ 2. SDK calls KMS → Decrypt(Encrypted DEK)                      │
 * │    └── Returns: Plaintext DEK                                  │
 * │                                                                 │
 * │ 3. SDK decrypts data locally using Plaintext DEK               │
 * │                                                                 │
 * │ Result: Original plaintext data                                 │
 * └─────────────────────────────────────────────────────────────────┘
 */
@Service
public class KmsEncryptionService {

    private static final Logger log = LoggerFactory.getLogger(KmsEncryptionService.class);

    private final AwsCrypto crypto;
    private final KmsMasterKeyProvider keyProvider;

    public KmsEncryptionService(AwsCrypto crypto, KmsMasterKeyProvider keyProvider) {
        this.crypto = crypto;
        this.keyProvider = keyProvider;
    }

    /**
     * Encrypt string data using AWS Encryption SDK with KMS
     *
     * @param plaintext The data to encrypt
     * @return Encrypted bytes (includes encrypted DEK + metadata)
     */
    public byte[] encrypt(String plaintext) {
        return encrypt(plaintext, Collections.emptyMap());
    }

    /**
     * Encrypt string data with encryption context
     *
     * Encryption context is additional authenticated data (AAD) that:
     * - Is NOT encrypted (stored in plaintext in the message)
     * - IS cryptographically bound to the ciphertext
     * - Must match exactly during decryption
     * - Useful for: tenant ID, purpose, data classification
     *
     * @param plaintext The data to encrypt
     * @param encryptionContext Key-value pairs for context
     * @return Encrypted bytes
     */
    public byte[] encrypt(String plaintext, Map<String, String> encryptionContext) {
        log.debug("Encrypting {} bytes with context: {}", plaintext.length(), encryptionContext);

        CryptoResult<byte[], ?> result = crypto.encryptData(
                keyProvider,
                plaintext.getBytes(StandardCharsets.UTF_8),
                encryptionContext
        );

        log.debug("Encryption complete. Output size: {} bytes", result.getResult().length);
        log.debug("Master key ARNs used: {}", result.getMasterKeyIds());

        return result.getResult();
    }

    /**
     * Decrypt data that was encrypted with this service
     *
     * @param ciphertext The encrypted bytes from encrypt()
     * @return Original plaintext string
     */
    public String decrypt(byte[] ciphertext) {
        return decrypt(ciphertext, Collections.emptyMap());
    }

    /**
     * Decrypt data with encryption context verification
     *
     * @param ciphertext The encrypted bytes
     * @param expectedContext Context that must match (subset check)
     * @return Original plaintext string
     * @throws RuntimeException if context doesn't match
     */
    public String decrypt(byte[] ciphertext, Map<String, String> expectedContext) {
        log.debug("Decrypting {} bytes", ciphertext.length);

        CryptoResult<byte[], ?> result = crypto.decryptData(keyProvider, ciphertext);

        // Verify encryption context if provided
        if (!expectedContext.isEmpty()) {
            Map<String, String> actualContext = result.getEncryptionContext();
            for (Map.Entry<String, String> expected : expectedContext.entrySet()) {
                String actual = actualContext.get(expected.getKey());
                if (!expected.getValue().equals(actual)) {
                    throw new RuntimeException(
                            "Encryption context mismatch for key '" + expected.getKey() +
                                    "': expected '" + expected.getValue() + "' but got '" + actual + "'"
                    );
                }
            }
            log.debug("Encryption context verified: {}", expectedContext);
        }

        String plaintext = new String(result.getResult(), StandardCharsets.UTF_8);
        log.debug("Decryption complete. Output size: {} chars", plaintext.length());

        return plaintext;
    }

    /**
     * Encrypt with tenant isolation context
     *
     * Example of using encryption context for multi-tenant applications
     */
    public byte[] encryptForTenant(String plaintext, String tenantId) {
        Map<String, String> context = Map.of(
                "tenant", tenantId,
                "purpose", "data-encryption"
        );
        return encrypt(plaintext, context);
    }

    /**
     * Decrypt with tenant verification
     */
    public String decryptForTenant(byte[] ciphertext, String tenantId) {
        Map<String, String> expectedContext = Map.of("tenant", tenantId);
        return decrypt(ciphertext, expectedContext);
    }
}

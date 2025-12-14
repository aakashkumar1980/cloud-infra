package com.thirdparty.client;

import com.thirdparty.client.api.CompanyApiClient;
import com.thirdparty.client.crypto.AesEncryptor;
import com.thirdparty.client.crypto.RsaEncryptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 3rd Party Client Simulator
 *
 * Simulates a 3rd party client WITHOUT AWS account.
 *
 * This application:
 * 1. Gets public key from Aaditya Corp API (one-time)
 * 2. Generates a random DEK (Data Encryption Key)
 * 3. Encrypts sensitive data with DEK (AES-GCM)
 * 4. Encrypts DEK with public key (RSA-OAEP)
 * 5. Sends encrypted payload to Aaditya Corp API
 * 6. Receives decrypted data back
 *
 * NOTE: This application uses NO AWS SDK!
 * It only uses standard Java crypto libraries.
 */
public class ClientSimulatorApplication {

    private static final Logger log = LoggerFactory.getLogger(ClientSimulatorApplication.class);

    // Company backend URL (change if running on different port/host)
    private static final String COMPANY_API_URL = "http://localhost:8080";

    public static void main(String[] args) {
        log.info("═══════════════════════════════════════════════════════════════");
        log.info("  3rd Party Client Simulator (NO AWS SDK)");
        log.info("  Use-Case 1: Third party WITHOUT AWS account");
        log.info("═══════════════════════════════════════════════════════════════");

        try {
            new ClientSimulatorApplication().run();
        } catch (Exception e) {
            log.error("Simulation failed", e);
            System.exit(1);
        }
    }

    public void run() throws Exception {
        CompanyApiClient apiClient = new CompanyApiClient(COMPANY_API_URL);
        AesEncryptor aesEncryptor = new AesEncryptor();
        RsaEncryptor rsaEncryptor = new RsaEncryptor();

        // ═══════════════════════════════════════════════════════════════
        // Step 1: Get public key from company (one-time setup)
        // ═══════════════════════════════════════════════════════════════
        log.info("\n[STEP 1] Fetching public key from Aaditya Corp...");
        String publicKeyPem = apiClient.getPublicKey();
        rsaEncryptor.loadPublicKey(publicKeyPem);
        log.info("✓ Public key loaded successfully\n");

        // ═══════════════════════════════════════════════════════════════
        // Step 2: Prepare sensitive data to encrypt
        // ═══════════════════════════════════════════════════════════════
        String sensitiveData = "SSN: 123-45-6789, Credit Card: 4111-1111-1111-1111, " +
                "Medical Record: Patient has condition XYZ";

        log.info("[STEP 2] Sensitive data to encrypt:");
        log.info("         \"{}\"", sensitiveData);
        log.info("         Length: {} characters\n", sensitiveData.length());

        // ═══════════════════════════════════════════════════════════════
        // Step 3: Generate DEK and encrypt data locally (AES-GCM)
        // ═══════════════════════════════════════════════════════════════
        log.info("[STEP 3] Encrypting data locally with AES-GCM...");
        byte[] dek = aesEncryptor.generateDek();
        AesEncryptor.EncryptionResult encryptionResult = aesEncryptor.encrypt(sensitiveData, dek);
        log.info("✓ Data encrypted with random DEK");
        log.info("  DEK size: {} bits", dek.length * 8);
        log.info("  Encrypted data: {} bytes", encryptionResult.encryptedData().length);
        log.info("  IV: {} bytes", encryptionResult.iv().length);
        log.info("  Auth tag: {} bytes\n", encryptionResult.authTag().length);

        // ═══════════════════════════════════════════════════════════════
        // Step 4: Encrypt DEK with company's public key (RSA-OAEP)
        // ═══════════════════════════════════════════════════════════════
        log.info("[STEP 4] Encrypting DEK with company's public key (RSA-OAEP)...");
        String encryptedDek = rsaEncryptor.encryptDek(dek);
        log.info("✓ DEK encrypted with public key");
        log.info("  Encrypted DEK length: {} chars (Base64)\n", encryptedDek.length());

        // ═══════════════════════════════════════════════════════════════
        // Step 5: Send encrypted payload to company API
        // ═══════════════════════════════════════════════════════════════
        log.info("[STEP 5] Sending encrypted payload to Aaditya Corp API...");
        log.info("         (Sensitive data is NEVER sent in plaintext!)");
        String decryptedData = apiClient.sendEncryptedData(encryptedDek, encryptionResult);

        // ═══════════════════════════════════════════════════════════════
        // Step 6: Verify result
        // ═══════════════════════════════════════════════════════════════
        log.info("\n[STEP 6] Response from server:");
        log.info("         \"{}\"", decryptedData);

        boolean success = sensitiveData.equals(decryptedData);
        log.info("\n═══════════════════════════════════════════════════════════════");
        if (success) {
            log.info("  ✓ SUCCESS! Data round-trip verified.");
            log.info("  ✓ Sensitive data was encrypted locally.");
            log.info("  ✓ Only encrypted data traveled over the network.");
            log.info("  ✓ Decryption happened server-side using KMS.");
        } else {
            log.error("  ✗ FAILED! Decrypted data does not match original.");
        }
        log.info("═══════════════════════════════════════════════════════════════");
    }
}

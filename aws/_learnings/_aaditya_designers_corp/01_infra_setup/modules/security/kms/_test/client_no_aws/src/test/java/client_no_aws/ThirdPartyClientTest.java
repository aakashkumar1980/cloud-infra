package client_no_aws;

import client_no_aws.crypto.AesEncryptor;
import client_no_aws.crypto.RsaEncryptor;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Third Party Client Test (Use-Case 1)
 *
 * Simulates a 3rd party client WITHOUT AWS account.
 * Uses standard Java crypto (NO AWS SDK).
 *
 * Flow:
 * 1. Load public key from resources (received via secure email from company)
 * 2. Generate random DEK and encrypt data with AES-GCM
 * 3. Encrypt DEK with public key (RSA-OAEP)
 * 4. Send encrypted package to company API for decryption
 * 5. Verify decrypted data matches original
 *
 * Prerequisites:
 * - Download public key from AWS KMS and place in src/test/resources/public-key.pem
 * - Command: aws kms get-public-key --key-id alias/test_asymmetric_kms-... --region us-east-1 --profile dev --output text --query PublicKey | base64 -d > public-key.der
 *   Then convert to PEM format or use AWS Console to download
 */
@SpringBootTest(
        classes = company_backend.CompanyBackendApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ThirdPartyClientTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    private final Gson gson = new Gson();
    private final AesEncryptor aesEncryptor = new AesEncryptor();
    private final RsaEncryptor rsaEncryptor = new RsaEncryptor();

    private String baseUrl() {
        return "http://localhost:" + port + "/api/v1";
    }

    @Test
    @Order(1)
    @DisplayName("Health check - API is running")
    void testHealthCheck() {
        ResponseEntity<String> response = restTemplate.getForEntity(
                baseUrl() + "/health",
                String.class
        );

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("OK", response.getBody());
    }

    @Test
    @Order(2)
    @DisplayName("Load public key from resources - PEM file exists")
    void testLoadPublicKeyFromResources() throws Exception {
        rsaEncryptor.loadPublicKeyFromResources();
        System.out.println("✓ Public key loaded from src/test/resources/public-key.pem");
    }

    @Test
    @Order(3)
    @DisplayName("Full encryption/decryption flow - End to end test")
    void testFullEncryptionFlow() throws Exception {
        // === Step 1: Load public key from resources ===
        System.out.println("\n=== Step 1: Load Public Key from Resources ===");

        rsaEncryptor.loadPublicKeyFromResources();
        System.out.println("✓ Public key loaded from src/test/resources/public-key.pem");

        // === Step 2: Encrypt data with AES-GCM ===
        System.out.println("\n=== Step 2: Encrypt Data (AES-GCM) ===");

        String sensitiveData = "This is confidential data from 3rd party client!";
        System.out.println("Original data: \"" + sensitiveData + "\"");

        // Generate random DEK
        byte[] dek = aesEncryptor.generateDek();
        System.out.println("✓ Generated random 256-bit DEK");

        // Encrypt data with DEK
        AesEncryptor.EncryptionResult aesResult = aesEncryptor.encrypt(sensitiveData, dek);
        System.out.println("✓ Data encrypted with AES-GCM");
        System.out.println("  Encrypted data (Base64): " + truncate(aesResult.encryptedDataBase64(), 50));
        System.out.println("  IV (Base64): " + aesResult.ivBase64());
        System.out.println("  Auth Tag (Base64): " + aesResult.authTagBase64());

        // === Step 3: Encrypt DEK with public key (RSA-OAEP) ===
        System.out.println("\n=== Step 3: Encrypt DEK (RSA-OAEP) ===");

        String encryptedDek = rsaEncryptor.encryptDek(dek);
        System.out.println("✓ DEK encrypted with company's public key");
        System.out.println("  Encrypted DEK (Base64): " + truncate(encryptedDek, 50));

        // === Step 4: Send to company API for decryption ===
        System.out.println("\n=== Step 4: Send to Company API ===");

        JsonObject decryptRequest = new JsonObject();
        decryptRequest.addProperty("encryptedDek", encryptedDek);
        decryptRequest.addProperty("encryptedData", aesResult.encryptedDataBase64());
        decryptRequest.addProperty("iv", aesResult.ivBase64());
        decryptRequest.addProperty("authTag", aesResult.authTagBase64());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(gson.toJson(decryptRequest), headers);

        ResponseEntity<String> decryptResponse = restTemplate.postForEntity(
                baseUrl() + "/decrypt",
                request,
                String.class
        );

        assertEquals(HttpStatus.OK, decryptResponse.getStatusCode());
        System.out.println("✓ Decrypt request successful");

        // === Step 5: Verify decrypted data ===
        System.out.println("\n=== Step 5: Verify Result ===");

        JsonObject resultJson = gson.fromJson(decryptResponse.getBody(), JsonObject.class);
        assertTrue(resultJson.get("success").getAsBoolean());
        String decryptedData = resultJson.get("plaintext").getAsString();

        System.out.println("Decrypted data: \"" + decryptedData + "\"");
        assertEquals(sensitiveData, decryptedData);
        System.out.println("✓ SUCCESS: Decrypted data matches original!");
    }

    @Test
    @Order(4)
    @DisplayName("Invalid encrypted DEK - Should fail decryption")
    void testInvalidEncryptedDek() throws Exception {
        // Load public key from resources
        rsaEncryptor.loadPublicKeyFromResources();

        byte[] dek = aesEncryptor.generateDek();
        AesEncryptor.EncryptionResult aesResult = aesEncryptor.encrypt("test data", dek);

        // Send with invalid (corrupted) encrypted DEK
        JsonObject decryptRequest = new JsonObject();
        decryptRequest.addProperty("encryptedDek", "InvalidBase64DEK==");
        decryptRequest.addProperty("encryptedData", aesResult.encryptedDataBase64());
        decryptRequest.addProperty("iv", aesResult.ivBase64());
        decryptRequest.addProperty("authTag", aesResult.authTagBase64());

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(gson.toJson(decryptRequest), headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
                baseUrl() + "/decrypt",
                request,
                String.class
        );

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        System.out.println("✓ Invalid DEK correctly rejected");
    }

    @Test
    @Order(5)
    @DisplayName("Tampered auth tag - Should fail integrity check")
    void testTamperedAuthTag() throws Exception {
        // Load public key from resources
        rsaEncryptor.loadPublicKeyFromResources();

        byte[] dek = aesEncryptor.generateDek();
        AesEncryptor.EncryptionResult aesResult = aesEncryptor.encrypt("secret message", dek);
        String encryptedDek = rsaEncryptor.encryptDek(dek);

        // Tamper with auth tag (flip a character)
        String tamperedAuthTag = aesResult.authTagBase64().substring(0, 5) + "X" +
                aesResult.authTagBase64().substring(6);

        JsonObject decryptRequest = new JsonObject();
        decryptRequest.addProperty("encryptedDek", encryptedDek);
        decryptRequest.addProperty("encryptedData", aesResult.encryptedDataBase64());
        decryptRequest.addProperty("iv", aesResult.ivBase64());
        decryptRequest.addProperty("authTag", tamperedAuthTag);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(gson.toJson(decryptRequest), headers);

        ResponseEntity<String> response = restTemplate.postForEntity(
                baseUrl() + "/decrypt",
                request,
                String.class
        );

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        System.out.println("✓ Tampered auth tag correctly rejected (integrity check passed)");
    }

    private String truncate(String str, int maxLen) {
        return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
    }
}

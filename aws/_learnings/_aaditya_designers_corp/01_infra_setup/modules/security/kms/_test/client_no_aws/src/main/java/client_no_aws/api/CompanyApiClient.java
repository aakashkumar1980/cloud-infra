package client_no_aws.api;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import client_no_aws.crypto.AesEncryptor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * HTTP Client for Company Backend API
 *
 * Handles communication with Aaditya Corp's encryption API.
 * Uses standard Java HttpClient (no external dependencies).
 */
public class CompanyApiClient {

    private static final Logger log = LoggerFactory.getLogger(CompanyApiClient.class);

    private final String baseUrl;
    private final HttpClient httpClient;
    private final Gson gson;

    public CompanyApiClient(String baseUrl) {
        this.baseUrl = baseUrl;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        this.gson = new Gson();
    }

    /**
     * Get public key from company API
     *
     * @return PEM-encoded public key
     */
    public String getPublicKey() throws Exception {
        log.info("Fetching public key from {}/api/v1/public-key", baseUrl);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/v1/public-key"))
                .GET()
                .header("Accept", "application/json")
                .timeout(Duration.ofSeconds(30))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            throw new RuntimeException("Failed to get public key. Status: " + response.statusCode());
        }

        JsonObject json = gson.fromJson(response.body(), JsonObject.class);
        String publicKeyPem = json.get("publicKeyPem").getAsString();

        log.info("Public key received successfully");
        log.debug("Key ID: {}", json.get("keyId").getAsString());

        return publicKeyPem;
    }

    /**
     * Send encrypted data to company API for decryption
     *
     * @param encryptedDek    DEK encrypted with public key (Base64)
     * @param encryptionResult AES encryption result containing encrypted data, IV, auth tag
     * @return Decrypted plaintext from server
     */
    public String sendEncryptedData(String encryptedDek, AesEncryptor.EncryptionResult encryptionResult)
            throws Exception {

        log.info("Sending encrypted data to {}/api/v1/decrypt", baseUrl);

        // Build request body
        JsonObject body = new JsonObject();
        body.addProperty("encryptedDek", encryptedDek);
        body.addProperty("encryptedData", encryptionResult.encryptedDataBase64());
        body.addProperty("iv", encryptionResult.ivBase64());
        body.addProperty("authTag", encryptionResult.authTagBase64());

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/v1/decrypt"))
                .POST(HttpRequest.BodyPublishers.ofString(gson.toJson(body)))
                .header("Content-Type", "application/json")
                .header("Accept", "application/json")
                .timeout(Duration.ofSeconds(30))
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        log.debug("Response status: {}", response.statusCode());
        log.debug("Response body: {}", response.body());

        JsonObject json = gson.fromJson(response.body(), JsonObject.class);

        if (response.statusCode() != 200 || !"SUCCESS".equals(json.get("status").getAsString())) {
            String errorMsg = json.has("message") ? json.get("message").getAsString() : "Unknown error";
            throw new RuntimeException("Decryption failed: " + errorMsg);
        }

        String plaintext = json.get("plaintext").getAsString();
        log.info("Data decrypted successfully by server");

        return plaintext;
    }
}

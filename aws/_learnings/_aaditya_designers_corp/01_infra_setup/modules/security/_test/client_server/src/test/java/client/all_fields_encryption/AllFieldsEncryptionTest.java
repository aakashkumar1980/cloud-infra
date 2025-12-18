package client.all_fields_encryption;

import client.all_fields_encryption.service.HybridEncryptionService;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

import static org.junit.jupiter.api.Assertions.*;

/**
 * End-to-End Test: All-Fields JWE Encryption (Proper CEK Usage)
 *
 * <h3>Client Flow:</h3>
 * <ol>
 *   <li>Load RSA public key</li>
 *   <li>Build JSON payload with plaintext PII</li>
 *   <li>Encrypt entire payload as JWE (CEK encrypts payload, RSA encrypts CEK)</li>
 *   <li>Send JWE as request body</li>
 * </ol>
 *
 * <h3>Server Flow:</h3>
 * <ol>
 *   <li>Parse JWE from request body</li>
 *   <li>KMS decrypt encryptedCek → CEK (1 API call)</li>
 *   <li>Local AES decrypt ciphertext → JSON payload</li>
 * </ol>
 */
@SpringBootTest(
    classes = {server.ServerApplication.class, client.all_fields_encryption.TestConfig.class},
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AllFieldsEncryptionTest {

  private static final Logger log = LoggerFactory.getLogger(AllFieldsEncryptionTest.class);

  @LocalServerPort
  private int port;

  @Autowired
  private TestRestTemplate restTemplate;

  @Autowired
  @Qualifier("allFieldsHybridEncryptionService")
  private HybridEncryptionService hybridEncryptionService;

  private final Gson gson = new Gson();

  private String baseUrl() {
    return "http://localhost:" + port + "/api/v1/all-fields";
  }

  @Test
  @Order(1)
  @DisplayName("All-Fields: Submit order with JWE-encrypted payload (proper CEK usage)")
  void testSubmitOrderWithJweEncryption() {
    String jwePayload = prepareJwePayload();
    submitAndVerifyOrder(jwePayload);
  }

  private JsonObject loadSampleOrder() {
    try (var reader = new InputStreamReader(
        Objects.requireNonNull(getClass().getClassLoader().getResourceAsStream("sample-order.json")),
        StandardCharsets.UTF_8)) {
      return gson.fromJson(reader, JsonObject.class);
    } catch (Exception e) {
      throw new RuntimeException("Failed to load sample-order.json", e);
    }
  }

  private String prepareJwePayload() {
    // Step 1: Load RSA public key
    log.info("\n=== Step 1: Load RSA Public Key ===");
    hybridEncryptionService.loadRSAPublicKey();
    log.info("Loaded RSA-4096 public key");

    // Step 2: Load JSON payload from file (plaintext PII)
    log.info("\n=== Step 2: Load JSON Payload (from sample-order.json) ===");
    JsonObject orderRequest = loadSampleOrder();
    String jsonPayload = gson.toJson(orderRequest);
    log.info("JSON payload: {}", truncate(jsonPayload, 60));

    // Step 3: Encrypt entire payload as JWE
    log.info("\n=== Step 3: Encrypt Entire Payload as JWE ===");
    String jweString = hybridEncryptionService.encryptPayload(jsonPayload);
    log.info("JWE created (length={}): {}", jweString.length(), truncate(jweString, 60));
    log.info("JWE internally uses CEK (aesContentEncryptionKey) to encrypt entire payload");

    return jweString;
  }

  private void submitAndVerifyOrder(String jwePayload) {
    log.info("\n=== Step 4: Submit JWE to API ===");

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.TEXT_PLAIN);
    HttpEntity<String> request = new HttpEntity<>(jwePayload, headers);
    log.info("POST /api/v1/all-fields/orders (body=JWE)");

    ResponseEntity<String> response = restTemplate.postForEntity(baseUrl() + "/orders", request, String.class);

    // Verify response
    log.info("\n=== Step 5: Verify Response ===");
    assertEquals(HttpStatus.OK, response.getStatusCode(), "Expected 200 OK");

    JsonObject result = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(result.get("success").getAsBoolean(), "Expected success=true");

    String dob = result.get("dateOfBirth").getAsString();
    JsonObject cardDetails = result.getAsJsonObject("cardDetails");
    String maskedCard = cardDetails.get("creditCardNumber").getAsString();
    String maskedSsn = cardDetails.get("ssn").getAsString();

    log.info("Response - DOB={} | Card={} | SSN={}", dob, maskedCard, maskedSsn);

    // Verify decryption worked
    assertEquals("1990-05-15", dob, "DOB should be decrypted");
    assertTrue(maskedCard.endsWith("1234"), "Card should show last 4 digits");
    assertTrue(maskedSsn.endsWith("6789"), "SSN should show last 4 digits");

    log.info("\n=== SUCCESS === (1 KMS call to decrypt CEK, then local AES for payload)");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }
}

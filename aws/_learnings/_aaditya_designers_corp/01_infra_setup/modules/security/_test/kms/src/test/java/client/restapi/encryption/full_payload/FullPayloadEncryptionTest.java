package client.restapi.encryption.full_payload;

import client._common.Utils;
import client.restapi.encryption.full_payload.service.HybridEncryptionService;
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
    classes = {server.ServerApplication.class, TestConfig.class},
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class FullPayloadEncryptionTest {

  private static final Logger log = LoggerFactory.getLogger(FullPayloadEncryptionTest.class);

  @LocalServerPort
  private int port;
  private String baseUrl() {
    return "http://localhost:" + port + "/api/v1/all-fields";
  }

  @Autowired
  private TestRestTemplate restTemplate;

  @Autowired
  @Qualifier("allFieldsHybridEncryptionService")
  private HybridEncryptionService hybridEncryptionService;

  @Autowired
  @Qualifier("clientUtils")
  private Utils utils;
  private final Gson gson = new Gson();

  @Test
  @DisplayName("All-Fields: Submit order with JWE-encrypted payload (proper CEK usage)")
  void testSubmitOrder() {
    Order orderString = prepareOrder();
    submitAndVerifyOrder(orderString);
  }
  public record Order(String payload) {}

  /**
   * Prepares a JWE-encrypted payload for submission.
   * Here the whole JSON payload is encrypted.
   *
   * @return JWE string
   */
  private Order prepareOrder() {
    log.info("\n=== Step 1: Load RSA Public Key ===");
    hybridEncryptionService.loadPublicKey();

    log.info("\n=== Step 2: Encrypt Entire Payload as JWE ===");
    JsonObject order = utils.loadSampleOrder();
    String orderJson = gson.toJson(order);
    String payload = hybridEncryptionService.encryptPayload(orderJson);

    return new Order(payload);
  }

  /**
   * Submits the JWE payload to the API and verifies the response.
   *
   * @param order JWE string to submit
   */
  private void submitAndVerifyOrder(Order order) {
    log.info("\n=== Step 3: Submit Order to API ===");
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.TEXT_PLAIN);
    HttpEntity<String> request = new HttpEntity<>(order.payload(), headers);
    log.info("POST /api/v1/all-fields/orders");
    log.info("Request Body: {}", utils.truncate(order.payload(), 60));

    ResponseEntity<String> response = restTemplate.postForEntity(baseUrl() + "/orders", request, String.class);
    log.info("\n=== Verify Response ===");
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

}

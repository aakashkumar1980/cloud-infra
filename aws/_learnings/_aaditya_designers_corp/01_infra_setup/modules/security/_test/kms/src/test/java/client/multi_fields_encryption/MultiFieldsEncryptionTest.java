package client.multi_fields_encryption;

import client._common_utils.Utils;
import client.multi_fields_encryption.service.HybridEncryptionService;
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
 * End-to-End Test: Multi-Fields Encryption (Direct RSA, No JWE/CEK)
 *
 * <h3>Client Flow:</h3>
 * <ol>
 *   <li>Load RSA public key</li>
 *   <li>Generate AES DEK, RSA-encrypt it directly (no CEK)</li>
 *   <li>Encrypt each PII field with DEK</li>
 *   <li>Send: Header=BASE64(encryptedDek), Body=encrypted fields</li>
 * </ol>
 *
 * <h3>Server Flow:</h3>
 * <ol>
 *   <li>KMS decrypt header → DEK (1 API call, direct RSA)</li>
 *   <li>Local AES decrypt each field using DEK</li>
 * </ol>
 */
@SpringBootTest(
    classes = {server.ServerApplication.class, client.multi_fields_encryption.TestConfig.class},
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class MultiFieldsEncryptionTest {

  private static final Logger log = LoggerFactory.getLogger(MultiFieldsEncryptionTest.class);

  @LocalServerPort
  private int port;
  private String baseUrl() {
    return "http://localhost:" + port + "/api/v1/multi-fields";
  }

  @Autowired
  private TestRestTemplate restTemplate;

  @Autowired
  @Qualifier("multiFieldsHybridEncryptionService")
  private HybridEncryptionService hybridEncryptionService;

  @Autowired
  private Utils utils;
  private final Gson gson = new Gson();

  @Test
  @DisplayName("Multi-Fields: Submit order with direct RSA encryption (no JWE/CEK)")
  void testSubmitOrder() {
    Order order = prepareOrder();
    submitAndVerifyOrder(order);
  }
  public record Order(String header, JsonObject jsonPayload) {}

  /**
   * Prepares an encrypted order by performing the following steps:
   * 1. Loads the RSA public key.
   * 2. Generates an AES DEK and wraps it with RSA (no CEK).
   * 3. Loads order data from a JSON file.
   * 4. Encrypts PII fields using the DEK.
   * 5. Retrieves the encrypted DEK for the request header.
   *
   * @return An EncryptedOrder containing the encrypted DEK and payload.
   */
  private Order prepareOrder() {
    hybridEncryptionService.clear();

    // Step 1: Load RSA public key
    log.info("\n=== Step 1: Load RSA Public Key ===");
    hybridEncryptionService.loadPublicKey();
    log.info("Loaded RSA-4096 public key");

    // Step 2: Generate AES DEK and wrap with RSA (NO CEK!)
    log.info("\n=== Step 2: Generate DEK & Wrap with RSA (Direct, No CEK) ===");
    hybridEncryptionService.generateEncryptAndWrapDataEncryptionKey();
    log.info("Generated 256-bit AES DEK, RSA-encrypted directly (no intermediate CEK)");

    // Step 3: Load order data from JSON file
    log.info("\n=== Step 3: Order Data (from sample-order.json) ===");
    JsonObject order = utils.loadSampleOrder();
    JsonObject cardDetails = order.getAsJsonObject("cardDetails");

    // Step 4: Encrypt PII fields with DEK
    log.info("\n=== Step 4: Encrypt PII Fields with DEK ===");
    String encryptedDob = hybridEncryptionService.encryptField(order.get("dateOfBirth").getAsString());
    String encryptedCreditCard = hybridEncryptionService.encryptField(cardDetails.get("creditCardNumber").getAsString());
    String encryptedSsn = hybridEncryptionService.encryptField(cardDetails.get("ssn").getAsString());
    log.info("Encrypted DOB={} | Card={} | SSN={}",
        utils.truncate(encryptedDob, 25), utils.truncate(encryptedCreditCard, 25), utils.truncate(encryptedSsn, 25));

    // Step 5: Get encrypted DEK for header
    log.info("\n=== Step 5: Get Encrypted DEK for Header ===");
    String encryptedDataEncryptionKey = hybridEncryptionService.getEncryptedDataEncryptionKey();
    log.info("X-Encryption-Key: {} (BASE64 RSA-encrypted DEK)", utils.truncate(encryptedDataEncryptionKey, 40));

    // Build JSON payload with encrypted fields
    JsonObject encryptedCardDetails = new JsonObject();
    encryptedCardDetails.addProperty("creditCardNumber", encryptedCreditCard);
    encryptedCardDetails.addProperty("ssn", encryptedSsn);
    JsonObject jsonPayload = new JsonObject();
    jsonPayload.addProperty("name", order.get("name").getAsString());
    jsonPayload.addProperty("address", order.get("address").getAsString());
    jsonPayload.addProperty("dateOfBirth", encryptedDob);
    jsonPayload.addProperty("orderAmount", order.get("orderAmount").getAsDouble());
    jsonPayload.add("cardDetails", encryptedCardDetails);

    return new Order(encryptedDataEncryptionKey, jsonPayload);
  }


  /**
   * Submits the encrypted order to the API and verifies the response.
   *
   * @param order The encrypted order containing the header and payload.
   */
  private void submitAndVerifyOrder(Order order) {
    log.info("\n=== Step 6: Submit Order to API ===");
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("X-Encryption-Key", order.header());
    HttpEntity<String> jsonPayload = new HttpEntity<>(gson.toJson(order.jsonPayload()), headers);
    log.info("POST /api/v1/multi-fields/orders");

    ResponseEntity<String> response = restTemplate.postForEntity(baseUrl() + "/orders", jsonPayload, String.class);
    // Verify response
    log.info("\n=== Step 7: Verify Response ===");
    assertEquals(HttpStatus.OK, response.getStatusCode(), "Expected 200 OK");

    JsonObject jsonPayloadWithPlainFields = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(jsonPayloadWithPlainFields.get("success").getAsBoolean(), "Expected success=true");

    String dob = jsonPayloadWithPlainFields.get("dateOfBirth").getAsString();
    JsonObject cardDetails = jsonPayloadWithPlainFields.getAsJsonObject("cardDetails");
    String maskedCard = cardDetails.get("creditCardNumber").getAsString();
    String maskedSsn = cardDetails.get("ssn").getAsString();
    log.info("Response - DOB={} | Card={} | SSN={}", dob, maskedCard, maskedSsn);

    // Verify decryption worked
    assertEquals("1990-05-15", dob, "DOB should be decrypted");
    assertTrue(maskedCard.endsWith("1234"), "Card should show last 4 digits");
    assertTrue(maskedSsn.endsWith("6789"), "SSN should show last 4 digits");
    log.info("\n=== SUCCESS === (1 KMS call - direct RSA decrypt, no CEK overhead!)");
  }


}

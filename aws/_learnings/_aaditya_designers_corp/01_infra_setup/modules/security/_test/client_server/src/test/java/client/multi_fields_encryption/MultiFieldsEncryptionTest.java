package client.multi_fields_encryption;

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

  @Autowired
  private TestRestTemplate restTemplate;

  @Autowired
  @Qualifier("multiFieldsHybridEncryptionService")
  private HybridEncryptionService hybridEncryptionService;

  private final Gson gson = new Gson();

  private String baseUrl() {
    return "http://localhost:" + port + "/api/v1/multi-fields";
  }

  @Test
  @Order(1)
  @DisplayName("Multi-Fields: Submit order with direct RSA encryption (no JWE/CEK)")
  void testSubmitOrderWithDirectRsaEncryption() {
    EncryptedOrder encryptedOrder = prepareEncryptedOrder();
    submitAndVerifyOrder(encryptedOrder);
  }

  private EncryptedOrder prepareEncryptedOrder() {
    hybridEncryptionService.clear();

    // Step 1: Load RSA public key
    log.info("\n=== Step 1: Load RSA Public Key ===");
    hybridEncryptionService.loadRSAPublicKey();
    log.info("Loaded RSA-4096 public key");

    // Step 2: Generate AES DEK and wrap with RSA (NO CEK!)
    log.info("\n=== Step 2: Generate DEK & Wrap with RSA (Direct, No CEK) ===");
    hybridEncryptionService.generateAndWrapDek();
    log.info("Generated 256-bit AES DEK, RSA-encrypted directly (no intermediate CEK)");

    // Step 3: Define order data
    log.info("\n=== Step 3: Order Data ===");
    record CardDetails(String creditCardNumber, String ssn) {}
    var cardDetails = new CardDetails("4111111111111234", "123-45-6789");
    record OrderData(String name, String address, String dob, double amount, CardDetails cardDetails) {}
    var order = new OrderData("aakash.kumar", "austin,texas,usa", "1990-05-15", 100.00, cardDetails);
    log.info("OrderData: Name={} | DOB={} | Card={} | SSN={}",
        order.name, order.dob, cardDetails.creditCardNumber, cardDetails.ssn);

    // Step 4: Encrypt PII fields
    log.info("\n=== Step 4: Encrypt PII Fields with DEK ===");
    String encryptedDob = hybridEncryptionService.encryptField(order.dob);
    String encryptedCreditCard = hybridEncryptionService.encryptField(cardDetails.creditCardNumber);
    String encryptedSsn = hybridEncryptionService.encryptField(cardDetails.ssn);
    log.info("Encrypted DOB={} | Card={} | SSN={}",
        truncate(encryptedDob, 25), truncate(encryptedCreditCard, 25), truncate(encryptedSsn, 25));

    // Step 5: Get encrypted DEK for header
    log.info("\n=== Step 5: Get Encrypted DEK for Header ===");
    String encryptedDek = hybridEncryptionService.getEncryptedDek();
    log.info("X-Encryption-Key: {} (BASE64 RSA-encrypted DEK)", truncate(encryptedDek, 40));

    // Build JSON payload
    JsonObject cardDetailsJson = new JsonObject();
    cardDetailsJson.addProperty("creditCardNumber", encryptedCreditCard);
    cardDetailsJson.addProperty("ssn", encryptedSsn);
    JsonObject orderRequestJson = new JsonObject();
    orderRequestJson.addProperty("name", order.name);
    orderRequestJson.addProperty("address", order.address);
    orderRequestJson.addProperty("dateOfBirth", encryptedDob);
    orderRequestJson.addProperty("orderAmount", order.amount);
    orderRequestJson.add("cardDetails", cardDetailsJson);

    return new EncryptedOrder(encryptedDek, orderRequestJson);
  }

  private void submitAndVerifyOrder(EncryptedOrder encryptedOrder) {
    log.info("\n=== Step 6: Submit Order to API ===");

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("X-Encryption-Key", encryptedOrder.header());
    HttpEntity<String> request = new HttpEntity<>(gson.toJson(encryptedOrder.payload()), headers);
    log.info("POST /api/v1/multi-fields/orders");

    ResponseEntity<String> response = restTemplate.postForEntity(baseUrl() + "/orders", request, String.class);

    // Verify response
    log.info("\n=== Step 7: Verify Response ===");
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

    log.info("\n=== SUCCESS === (1 KMS call - direct RSA decrypt, no CEK overhead!)");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }

  private record EncryptedOrder(String header, JsonObject payload) {}
}

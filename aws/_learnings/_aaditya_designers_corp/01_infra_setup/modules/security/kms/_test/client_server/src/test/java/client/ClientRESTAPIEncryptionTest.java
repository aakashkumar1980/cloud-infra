package client;

import client.service.HybridEncryptionService;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.test.context.ActiveProfiles;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.junit.jupiter.api.Assertions.*;

/**
 * End-to-End Test: Hybrid Encryption for REST API
 *
 * <h3>Client Flow (Steps 1-4):</h3>
 * <ol>
 *   <li>Load company's RSA public key → HybridEncryptionService.loadRSAPublicKey()</li>
 *   <li>Generate random encryption key (DEK) → FieldEncryptor.generateAESEncryptionKey()</li>
 *   <li>Wrap DEK in JWE for transport → JwtBuilder.wrapAndEncryptAESEncryptionKeyByRSAPublicKey()</li>
 *   <li>Encrypt PII fields with DEK → FieldEncryptor.encrypt()</li>
 * </ol>
 *
 * <h3>Server Flow (Steps 5-7):</h3>
 * <ol>
 *   <li>Extract encrypted key from JWE → JweParser.extractAESEncryptedKey()</li>
 *   <li>Unwrap DEK via KMS (1 API call) → KmsKeyUnwrapper.decryptAESEncryptedKey()</li>
 *   <li>Decrypt each field locally using DEK → FieldDecryptor.decrypt()</li>
 * </ol>
 */
@SpringBootTest(
    classes = server.ServerApplication.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@org.springframework.context.annotation.ComponentScan(basePackages = {"client", "server"})
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ClientRESTAPIEncryptionTest {

  private static final Logger log = LoggerFactory.getLogger(ClientRESTAPIEncryptionTest.class);

  @LocalServerPort
  private int port;

  @Autowired
  private TestRestTemplate restTemplate;

  @Autowired
  private HybridEncryptionService hybridEncryptionService;

  private final Gson gson = new Gson();

  private String baseUrl() {
    return "http://localhost:" + port + "/api/v1";
  }

  @Test
  @Order(1)
  @DisplayName("Submit order with hybrid-encrypted PII - End to end test")
  void testSubmitOrderWithHybridEncryption() throws Exception {
    EncryptedOrder encryptedOrder = prepareEncryptedOrder();
    submitAndVerifyOrder(encryptedOrder);
  }

  private EncryptedOrder prepareEncryptedOrder() throws Exception {
    // Step 1: Load RSA public key
    log.info("\n=== Step 1: Load RSA Public Key ===");
    hybridEncryptionService.loadRSAPublicKey();
    log.info("Loaded from: src/test/resources/public-key.pem");

    // Step 2: Generate AES encryption key and wrap in JWE
    log.info("\n=== Step 2: Generate AES Key & Create JWE Metadata ===");
    hybridEncryptionService.generateAESEncryptionKeyAndAddItToJWTMetadata();
    log.info("Generated 256-bit AES key and wrapped in JWE by encrypting with RSA-4096 public key");

    // Step 3: Define order data
    log.info("\n=== Step 3: Order Data ===");
    record CardDetails(String creditCardNumber, String ssn) {}
    var cardDetails = new CardDetails("4111111111111234", "123-45-6789");
    record OrderData(String name, String address, String dob, double amount, CardDetails cardDetails) {}
    var order = new OrderData("aakash.kumar", "austin,texas,usa", "1990-05-15", 100.00, cardDetails);
    log.info("OrderData: Name: {} | Address: {} | DOB: {} | Amount: ${} | Card: {} | SSN: {}",
        order.name, order.address, order.dob, order.amount, cardDetails.creditCardNumber, cardDetails.ssn);

    // Step 4: Encrypt PII fields
    log.info("\n=== Step 4: Encrypt PII Fields ===");
    String encryptedDob = hybridEncryptionService.encryptField(order.dob);
    String encryptedCreditCard = hybridEncryptionService.encryptField(cardDetails.creditCardNumber);
    String encryptedSsn = hybridEncryptionService.encryptField(cardDetails.ssn);
    log.info("Encrypted DOB: {} | Card: {} | SSN: {}",
        truncate(encryptedDob, 30), truncate(encryptedCreditCard, 30), truncate(encryptedSsn, 30));

    // Step 5: Get JWE header
    log.info("\n=== Step 5: Get JWT Encryption Metadata ===");
    String jwtEncryptionMetadata = hybridEncryptionService.getJwtEncryptionMetadata();
    log.info("JWE Header: {}", truncate(jwtEncryptionMetadata, 50));

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

    return new EncryptedOrder(jwtEncryptionMetadata, orderRequestJson);
  }

  private void submitAndVerifyOrder(EncryptedOrder encryptedOrder) {
    log.info("\n=== Step 6: Submit Order to API ===");

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("X-Encryption-Key", encryptedOrder.header());
    HttpEntity<String> request = new HttpEntity<>(gson.toJson(encryptedOrder.payload()), headers);
    log.info("POST /api/v1/orders | X-Encryption-Key: {}", truncate(encryptedOrder.header(), 40));

    ResponseEntity<String> response = restTemplate.postForEntity(baseUrl() + "/orders", request, String.class);
    // Verify response
    log.info("\n=== Step 7: Verify Response ===");
    assertEquals(HttpStatus.OK, response.getStatusCode(), "Expected 200 OK");

    JsonObject result = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(result.get("success").getAsBoolean(), "Expected success=true");

    String orderId = result.get("orderId").getAsString();
    String dob = result.get("dateOfBirth").getAsString();
    JsonObject cardDetails = result.getAsJsonObject("cardDetails");
    String maskedCard = cardDetails.get("creditCardNumber").getAsString();
    String maskedSsn = cardDetails.get("ssn").getAsString();

    log.info("Response - Status: {} | OrderId: {} | DOB: {} | Card: {} | SSN: {}",
        response.getStatusCode(), orderId, dob, maskedCard, maskedSsn);

    // Verify decryption worked
    assertEquals("1990-05-15", dob, "DOB should be decrypted");
    assertTrue(maskedCard.endsWith("1234"), "Card should show last 4 digits");
    assertTrue(maskedSsn.endsWith("6789"), "SSN should show last 4 digits");

    log.info("\n=== SUCCESS === (1 KMS call to unwrap key, 3 local decryptions)");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }

  private record EncryptedOrder(String header, JsonObject payload) {}
}

package client_no_aws;

import client_no_aws.crypto.HybridEncryptionHelper;
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
 * <p>Simulates a 3rd party client (NO AWS SDK) submitting an order with
 * encrypted PII fields using hybrid encryption.</p>
 *
 * <h3>Client Flow:</h3>
 * <ol>
 *   <li>Load company's RSA public key</li>
 *   <li>Generate random encryption key (DEK)</li>
 *   <li>Encrypt PII fields with DEK</li>
 *   <li>Wrap DEK in JWE for transport</li>
 *   <li>Send: X-Encryption-Key header + encrypted body</li>
 * </ol>
 *
 * <h3>Server Flow:</h3>
 * <ol>
 *   <li>Extract JWE from header, unwrap DEK via KMS (1 API call)</li>
 *   <li>Decrypt each field locally using DEK</li>
 *   <li>Process order and return masked response</li>
 * </ol>
 */
@SpringBootTest(
    classes = company_backend.CompanyBackendApplication.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ClientRESTAPIEncryptionTest {

  private static final Logger log = LoggerFactory.getLogger(ClientRESTAPIEncryptionTest.class);

  @LocalServerPort
  private int port;

  @Autowired
  private TestRestTemplate restTemplate;

  private final Gson gson = new Gson();
  private final HybridEncryptionHelper encryptionHelper = new HybridEncryptionHelper();

  private String baseUrl() {
    return "http://localhost:" + port + "/api/v1";
  }

  @Test
  @Order(1)
  @DisplayName("Submit order with hybrid-encrypted PII - End to end test")
  void testSubmitOrderWithHybridEncryption() throws Exception {
    // Prepare encrypted order and JWE header
    EncryptedOrder encryptedOrder = prepareEncryptedOrder();

    // Submit and verify
    submitAndVerifyOrder(encryptedOrder);
  }

  /**
   * Prepares an order with encrypted PII fields.
   *
   * <p>Uses the HybridEncryptionHelper to:</p>
   * <ul>
   *   <li>Load the public key</li>
   *   <li>Generate a fresh encryption key</li>
   *   <li>Encrypt all PII fields</li>
   *   <li>Create the JWE header</li>
   * </ul>
   */
  private EncryptedOrder prepareEncryptedOrder() throws Exception {
    // Step 1: Load public key
    log.info("\n=== Step 1: Load Public Key from Resources ===");
    encryptionHelper.loadPublicKeyFromResources();
    log.info("Public key loaded from src/test/resources/public-key.pem");

    // Step 2: Prepare for new request (generates encryption key)
    log.info("\n=== Step 2: Generate Encryption Key ===");
    encryptionHelper.prepareForNewRequest();
    log.info("Encryption key generated (256-bit AES)");

    // Step 3: Define order data
    log.info("\n=== Step 3: Create Order Data ===");
    String customerName = "aakash.kumar";
    String customerAddress = "austin,texas,usa";
    String dateOfBirth = "1990-05-15";
    String creditCardNumber = "4111111111111234";
    String ssn = "123-45-6789";
    double orderAmount = 100.00;

    log.info("Order Details:");
    log.info("  Name: {}", customerName);
    log.info("  Address: {}", customerAddress);
    log.info("  DOB: {}", dateOfBirth);
    log.info("  Credit Card: {}", creditCardNumber);
    log.info("  SSN: {}", ssn);
    log.info("  Order Amount: ${}", orderAmount);

    // Step 4: Encrypt PII fields
    log.info("\n=== Step 4: Encrypt PII Fields ===");
    String encryptedDob = encryptionHelper.encryptField(dateOfBirth);
    String encryptedCreditCard = encryptionHelper.encryptField(creditCardNumber);
    String encryptedSsn = encryptionHelper.encryptField(ssn);

    log.info("Encrypted DOB: {}", truncate(encryptedDob, 40));
    log.info("Encrypted Credit Card: {}", truncate(encryptedCreditCard, 40));
    log.info("Encrypted SSN: {}", truncate(encryptedSsn, 40));

    // Step 5: Get the encryption header (JWE with wrapped key)
    log.info("\n=== Step 5: Get Encryption Header ===");
    String encryptionHeader = encryptionHelper.getEncryptionHeader();
    log.info("Header value: {}", truncate(encryptionHeader, 50));

    // Build JSON payload
    JsonObject cardDetails = new JsonObject();
    cardDetails.addProperty("creditCardNumber", encryptedCreditCard);
    cardDetails.addProperty("ssn", encryptedSsn);

    JsonObject orderRequest = new JsonObject();
    orderRequest.addProperty("name", customerName);
    orderRequest.addProperty("address", customerAddress);
    orderRequest.addProperty("dateOfBirth", encryptedDob);
    orderRequest.addProperty("orderAmount", orderAmount);
    orderRequest.add("cardDetails", cardDetails);

    return new EncryptedOrder(encryptionHeader, orderRequest);
  }

  /**
   * Submits the order to the API and verifies the response.
   */
  private void submitAndVerifyOrder(EncryptedOrder encryptedOrder) {
    log.info("\n=== Step 6: Submit Order to API ===");

    // Build HTTP request with encryption header
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("X-Encryption-Key", encryptedOrder.header());

    HttpEntity<String> request = new HttpEntity<>(
        gson.toJson(encryptedOrder.payload()),
        headers
    );

    log.info("Request Headers:");
    log.info("  Content-Type: application/json");
    log.info("  X-Encryption-Key: {}", truncate(encryptedOrder.header(), 50));

    // Send request
    ResponseEntity<String> response = restTemplate.postForEntity(
        baseUrl() + "/orders",
        request,
        String.class
    );

    // Verify response
    log.info("\n=== Step 7: Verify Response ===");
    log.info("Response Status: {}", response.getStatusCode());

    assertEquals(HttpStatus.OK, response.getStatusCode(), "Expected 200 OK");

    JsonObject resultJson = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(resultJson.get("success").getAsBoolean(), "Expected success=true");

    // Extract response fields
    String orderId = resultJson.get("orderId").getAsString();
    String dateOfBirth = resultJson.get("dateOfBirth").getAsString();
    JsonObject cardDetails = resultJson.getAsJsonObject("cardDetails");
    String maskedCreditCard = cardDetails.get("creditCardNumber").getAsString();
    String maskedSsn = cardDetails.get("ssn").getAsString();

    // Log response
    log.info("\nOrder Response:");
    log.info("  Order ID: {}", orderId);
    log.info("  Name: {}", resultJson.get("name").getAsString());
    log.info("  Address: {}", resultJson.get("address").getAsString());
    log.info("  DOB: {}", dateOfBirth);
    log.info("  Order Amount: ${}", resultJson.get("orderAmount").getAsDouble());
    log.info("  Masked Credit Card: {}", maskedCreditCard);
    log.info("  Masked SSN: {}", maskedSsn);

    // Verify decryption worked correctly
    assertEquals("1990-05-15", dateOfBirth, "DOB should be decrypted");
    assertTrue(maskedCreditCard.endsWith("1234"), "Credit card should show last 4 digits");
    assertTrue(maskedSsn.endsWith("6789"), "SSN should show last 4 digits");

    log.info("\n=== SUCCESS ===");
    log.info("Order processed with hybrid encryption:");
    log.info("  - 1 KMS API call (to unwrap key)");
    log.info("  - 3 local decryptions (no additional KMS calls)");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }

  /**
   * Helper record to hold the encryption header and payload together.
   */
  private record EncryptedOrder(String header, JsonObject payload) {}
}

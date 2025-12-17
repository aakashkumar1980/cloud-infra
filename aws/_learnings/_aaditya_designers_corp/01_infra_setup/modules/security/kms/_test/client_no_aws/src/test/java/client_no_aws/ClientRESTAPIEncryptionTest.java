package client_no_aws;

import client_no_aws.crypto.HybridEncryptor;
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
 * Simulates a 3rd party client (NO AWS SDK) submitting an order with
 * encrypted PII fields using hybrid encryption.
 *
 * Encryption Flow (Client):
 * 1. Load company's RSA public key
 * 2. Generate random DEK (AES-256 key)
 * 3. Encrypt PII fields with DEK using AES-256-GCM
 * 4. Wrap DEK in JWE using RSA public key
 * 5. Send: X-Encryption-Key header (JWE) + body with encrypted fields
 *
 * Decryption Flow (Server):
 * 1. EncryptionFilter extracts JWE, unwraps DEK via KMS (1 API call)
 * 2. Controller decrypts each field locally using DEK
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
  private final HybridEncryptor hybridEncryptor = new HybridEncryptor();

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
   * Prepare order with encrypted PII fields
   *
   * Steps:
   * 1. Load RSA public key
   * 2. Generate DEK
   * 3. Encrypt each PII field with AES-GCM
   * 4. Create JWE containing DEK
   */
  private EncryptedOrder prepareEncryptedOrder() throws Exception {
    log.info("\n=== Step 1: Load Public Key from Resources ===");
    hybridEncryptor.loadPublicKeyFromResources();
    log.info("Public key loaded from src/test/resources/public-key.pem");

    log.info("\n=== Step 2: Generate DEK (AES-256 key) ===");
    hybridEncryptor.generateDek();
    log.info("DEK generated (256-bit AES key)");

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

    log.info("\n=== Step 4: Encrypt PII Fields (AES-256-GCM) ===");
    String encryptedDob = hybridEncryptor.encryptField(dateOfBirth);
    String encryptedCreditCard = hybridEncryptor.encryptField(creditCardNumber);
    String encryptedSsn = hybridEncryptor.encryptField(ssn);

    log.info("Encrypted DOB: {}", truncate(encryptedDob, 40));
    log.info("Encrypted Credit Card: {}", truncate(encryptedCreditCard, 40));
    log.info("Encrypted SSN: {}", truncate(encryptedSsn, 40));

    log.info("\n=== Step 5: Create JWE with DEK ===");
    String jwe = hybridEncryptor.createJweWithDek();
    log.info("JWE created: {}", truncate(jwe, 50));

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

    return new EncryptedOrder(jwe, orderRequest);
  }

  /**
   * Submit order and verify response
   */
  private void submitAndVerifyOrder(EncryptedOrder encryptedOrder) {
    log.info("\n=== Step 6: Submit Order to API ===");

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.set("X-Encryption-Key", encryptedOrder.jwe());

    HttpEntity<String> request = new HttpEntity<>(
        gson.toJson(encryptedOrder.payload()),
        headers
    );

    log.info("Request Headers:");
    log.info("  Content-Type: application/json");
    log.info("  X-Encryption-Key: {}", truncate(encryptedOrder.jwe(), 50));

    ResponseEntity<String> response = restTemplate.postForEntity(
        baseUrl() + "/orders",
        request,
        String.class
    );

    log.info("\n=== Step 7: Verify Response ===");
    log.info("Response Status: {}", response.getStatusCode());

    assertEquals(HttpStatus.OK, response.getStatusCode(), "Expected 200 OK");

    JsonObject resultJson = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(resultJson.get("success").getAsBoolean(), "Expected success=true");

    String orderId = resultJson.get("orderId").getAsString();
    String dateOfBirth = resultJson.get("dateOfBirth").getAsString();
    JsonObject cardDetails = resultJson.getAsJsonObject("cardDetails");
    String maskedCreditCard = cardDetails.get("creditCardNumber").getAsString();
    String maskedSsn = cardDetails.get("ssn").getAsString();

    log.info("\nOrder Response:");
    log.info("  Order ID: {}", orderId);
    log.info("  Name: {}", resultJson.get("name").getAsString());
    log.info("  Address: {}", resultJson.get("address").getAsString());
    log.info("  DOB: {}", dateOfBirth);
    log.info("  Order Amount: ${}", resultJson.get("orderAmount").getAsDouble());
    log.info("  Masked Credit Card: {}", maskedCreditCard);
    log.info("  Masked SSN: {}", maskedSsn);

    // Verify decryption worked (check masked values)
    assertEquals("1990-05-15", dateOfBirth, "DOB should be decrypted");
    assertTrue(maskedCreditCard.endsWith("1234"), "Credit card should show last 4 digits");
    assertTrue(maskedSsn.endsWith("6789"), "SSN should show last 4 digits");

    log.info("\nSUCCESS: Order processed with hybrid-encrypted PII!");
    log.info("  - 1 KMS API call (to unwrap DEK)");
    log.info("  - 3 local AES decryptions (no additional KMS calls)");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }

  /**
   * Helper record to hold JWE and payload together
   */
  private record EncryptedOrder(String jwe, JsonObject payload) {}
}

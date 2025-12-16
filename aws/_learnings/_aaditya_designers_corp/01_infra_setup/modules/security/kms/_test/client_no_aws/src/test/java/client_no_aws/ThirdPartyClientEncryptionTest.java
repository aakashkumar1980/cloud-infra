package client_no_aws;

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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Third Party Client Encryption Test (Use-Case 1)
 *
 * Simulates a 3rd party client WITHOUT AWS account.
 * Uses standard Java crypto (NO AWS SDK).
 *
 * Flow:
 * 1. Load public key from resources (received via secure email from company)
 * 2. Create order data with credit card number
 * 3. Encrypt credit card number directly with RSA public key
 * 4. Submit order to company API
 * 5. Verify order processed successfully
 *
 * Prerequisites:
 * - Download public key from AWS KMS and place in src/test/resources/public-key.pem
 */
@SpringBootTest(
    classes = company_backend.CompanyBackendApplication.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@ActiveProfiles("test")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class ThirdPartyClientEncryptionTest {

  private static final Logger log = LoggerFactory.getLogger(ThirdPartyClientEncryptionTest.class);

  @LocalServerPort
  private int port;

  @Autowired
  private TestRestTemplate restTemplate;

  private final Gson gson = new Gson();
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
    log.info("✓ Health check passed");
  }

  @Test
  @Order(2)
  @DisplayName("Load public key from resources - PEM file exists")
  void testLoadPublicKeyFromResources() throws Exception {
    rsaEncryptor.loadPublicKeyFromResources();
    log.info("✓ Public key loaded from src/test/resources/public-key.pem");
  }

  @Test
  @Order(3)
  @DisplayName("Submit order with encrypted credit card - End to end test")
  void testSubmitOrderWithEncryptedCreditCard() throws Exception {
    // === Step 1: Load public key from resources ===
    log.info("\n=== Step 1: Load Public Key from Resources ===");

    rsaEncryptor.loadPublicKeyFromResources();
    log.info("✓ Public key loaded from src/test/resources/public-key.pem");

    // === Step 2: Create order data ===
    log.info("\n=== Step 2: Create Order Data ===");

    String customerName = "aakash.kumar";
    String customerAddress = "austin,texas,usa";
    String creditCardNumber = "4111111111111234";  // Test credit card number
    double orderAmount = 100.00;

    log.info("Order Details:\n  Name: {}\n  Address: {}\n  Credit Card: {}\n  Order Amount: ${}",
        customerName, customerAddress, creditCardNumber, orderAmount);

    // === Step 3: Encrypt credit card with RSA public key ===
    log.info("\n=== Step 3: Encrypt Credit Card (RSA-OAEP) ===");

    String encryptedCreditCard = rsaEncryptor.encrypt(creditCardNumber);
    log.info("✓ Credit card encrypted with RSA-OAEP SHA-256\n  Encrypted (Base64): {}",
        truncate(encryptedCreditCard, 50));

    // === Step 4: Submit order to company API ===
    log.info("\n=== Step 4: Submit Order to API ===");

    JsonObject orderRequest = new JsonObject();
    orderRequest.addProperty("name", customerName);
    orderRequest.addProperty("address", customerAddress);
    orderRequest.addProperty("creditCardNumber", encryptedCreditCard);
    orderRequest.addProperty("orderAmount", orderAmount);

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    HttpEntity<String> request = new HttpEntity<>(gson.toJson(orderRequest), headers);

    ResponseEntity<String> response = restTemplate.postForEntity(
        baseUrl() + "/orders",
        request,
        String.class
    );

    assertEquals(HttpStatus.OK, response.getStatusCode());
    log.info("✓ Order submitted successfully");

    // === Step 5: Verify response ===
    log.info("\n=== Step 5: Verify Response ===");

    JsonObject resultJson = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(resultJson.get("success").getAsBoolean());

    String orderId = resultJson.get("orderId").getAsString();
    String maskedCard = resultJson.get("creditCardNumber").getAsString();

    log.info("Order Response:\n  Order ID: {}\n  Name: {}\n  Address: {}\n  Masked Credit Card: {}\n  Order Amount: ${}",
        orderId,
        resultJson.get("name").getAsString(),
        resultJson.get("address").getAsString(),
        maskedCard,
        resultJson.get("orderAmount").getAsDouble());

    // Verify masked card shows last 4 digits
    assertTrue(maskedCard.endsWith("1234"), "Masked card should show last 4 digits");
    log.info("\n✓ SUCCESS: Order processed with encrypted credit card!");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }
}

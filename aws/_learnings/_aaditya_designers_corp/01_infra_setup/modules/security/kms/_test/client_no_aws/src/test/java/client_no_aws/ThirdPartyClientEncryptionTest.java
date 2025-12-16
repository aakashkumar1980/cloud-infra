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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static org.junit.jupiter.api.Assertions.*;

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
  @DisplayName("Load public key from resources - PEM file exists")
  void testLoadPublicKeyFromResources() throws Exception {
    rsaEncryptor.loadPublicKeyFromResources();
    log.info("✓ Public key loaded from src/test/resources/public-key.pem");
  }

  @Test
  @Order(2)
  @DisplayName("Submit order with encrypted credit card - End to end test")
  void testSubmitOrderWithEncryptedCreditCard() throws Exception {
    JsonObject orderRequest = prepareEncryptedOrder();
    submitAndVerifyOrder(orderRequest);
  }

  /**
   * Groups Step 1-3:
   * 1. Load public key from resources
   * 2. Create order data
   * 3. Encrypt credit card with RSA public key
   *
   * Returns a JsonObject representing the order payload (with encrypted card).
   */
  private JsonObject prepareEncryptedOrder() throws Exception {
    log.info("\n=== Step 1: Load Public Key from Resources ===");
    rsaEncryptor.loadPublicKeyFromResources();
    log.info("✓ Public key loaded from src/test/resources/public-key.pem");

    log.info("\n=== Step 2: Create Order Data ===");
    String customerName = "aakash.kumar";
    String customerAddress = "austin,texas,usa";
    String creditCardNumber = "4111111111111234";
    double orderAmount = 100.00;

    log.info("Order Details:\n  Name: {}\n  Address: {}\n  Credit Card: {}\n  Order Amount: ${}",
        customerName, customerAddress, creditCardNumber, orderAmount);

    log.info("\n=== Step 3: Encrypt Credit Card (RSA-OAEP) ===");
    String encryptedCreditCard = rsaEncryptor.encrypt(creditCardNumber);
    log.info("✓ Credit card encrypted with RSA-OAEP SHA-256\n  Encrypted (Base64): {}",
        truncate(encryptedCreditCard, 50));

    JsonObject orderRequest = new JsonObject();
    orderRequest.addProperty("name", customerName);
    orderRequest.addProperty("address", customerAddress);
    orderRequest.addProperty("creditCardNumber", encryptedCreditCard);
    orderRequest.addProperty("orderAmount", orderAmount);

    return orderRequest;
  }

  /**
   * Groups Step 4-5:
   * 4. Submit order to company API
   * 5. Verify order processed successfully
   */
  private void submitAndVerifyOrder(JsonObject orderRequest) {
    log.info("\n=== Step 4: Submit Order to API ===");

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

    log.info("\n=== Step 5: Verify Response ===");

    JsonObject resultJson = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(resultJson.get("success").getAsBoolean());

    String orderId = resultJson.get("orderId").getAsString();
    String maskedCard = resultJson.get("creditCardNumber").getAsString();

    log.info("Order Response:");
    log.info("  Order ID: {}", orderId);
    log.info("  Name: {}", resultJson.get("name").getAsString());
    log.info("  Address: {}", resultJson.get("address").getAsString());
    log.info("  Masked Credit Card: {}", maskedCard);
    log.info("  Order Amount: ${}", resultJson.get("orderAmount").getAsDouble());

    assertTrue(maskedCard.endsWith("1234"), "Masked card should show last 4 digits");

    log.info("\n✓ SUCCESS: Order processed with encrypted credit card!");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }
}

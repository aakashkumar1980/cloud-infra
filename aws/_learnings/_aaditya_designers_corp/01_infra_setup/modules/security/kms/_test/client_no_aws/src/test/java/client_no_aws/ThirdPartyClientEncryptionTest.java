package client_no_aws;

import client_no_aws.crypto.AesEncryptor;
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

/**
 * Third Party Client Encryption Test (Use-Case 1)
 *
 * Simulates a 3rd party client WITHOUT AWS account.
 * Uses standard Java crypto (NO AWS SDK).
 *
 * Flow:
 * 1. Load public key from resources (received via secure email from company)
 * 2. Create order data with credit card number
 * 3. Encrypt credit card number with AES-GCM
 * 4. Encrypt DEK with public key (RSA-OAEP)
 * 5. Submit order to company API
 * 6. Verify order processed successfully
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

  @LocalServerPort
  private int port;

  @Autowired
  private TestRestTemplate restTemplate;

  private final Gson gson = new Gson();
  private final AesEncryptor aesEncryptor = new AesEncryptor();
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
    System.out.println("✓ Health check passed");
  }

  @Test
  @Order(2)
  @DisplayName("Load public key from resources - PEM file exists")
  void testLoadPublicKeyFromResources() throws Exception {
    rsaEncryptor.loadPublicKeyFromResources();
    System.out.println("✓ Public key loaded from src/test/resources/public-key.pem");
  }

  @Test
  @Order(3)
  @DisplayName("Submit order with encrypted credit card - End to end test")
  void testSubmitOrderWithEncryptedCreditCard() throws Exception {
    // === Step 1: Load public key from resources ===
    System.out.println("\n=== Step 1: Load Public Key from Resources ===");

    rsaEncryptor.loadPublicKeyFromResources();
    System.out.println("✓ Public key loaded from src/test/resources/public-key.pem");

    // === Step 2: Create order data ===
    System.out.println("\n=== Step 2: Create Order Data ===");

    String customerName = "aakash.kumar";
    String customerAddress = "austin,texas,usa";
    String creditCardNumber = "4111111111111234";  // Test credit card number
    double orderAmount = 100.00;

    System.out.println("Order Details:");
    System.out.println("  Name: " + customerName);
    System.out.println("  Address: " + customerAddress);
    System.out.println("  Credit Card: " + creditCardNumber);
    System.out.println("  Order Amount: $" + orderAmount);

    // === Step 3: Encrypt credit card number with AES-GCM ===
    System.out.println("\n=== Step 3: Encrypt Credit Card (AES-GCM) ===");

    // Generate random DEK
    byte[] dek = aesEncryptor.generateDek();
    System.out.println("✓ Generated random 256-bit DEK");

    // Encrypt credit card with DEK
    AesEncryptor.EncryptionResult aesResult = aesEncryptor.encrypt(creditCardNumber, dek);
    System.out.println("✓ Credit card encrypted with AES-GCM");
    System.out.println("  Encrypted credit card (Base64): " + truncate(aesResult.encryptedDataBase64(), 50));

    // === Step 4: Encrypt DEK with public key (RSA-OAEP) ===
    System.out.println("\n=== Step 4: Encrypt DEK (RSA-OAEP) ===");

    String encryptedDek = rsaEncryptor.encryptDek(dek);
    System.out.println("✓ DEK encrypted with company's public key");
    System.out.println("  Encrypted DEK (Base64): " + truncate(encryptedDek, 50));

    // === Step 5: Submit order to company API ===
    System.out.println("\n=== Step 5: Submit Order to API ===");

    JsonObject orderRequest = new JsonObject();
    orderRequest.addProperty("name", customerName);
    orderRequest.addProperty("address", customerAddress);
    orderRequest.addProperty("creditCardNumber", aesResult.encryptedDataBase64());  // Encrypted
    orderRequest.addProperty("orderAmount", orderAmount);
    orderRequest.addProperty("encryptedDek", encryptedDek);
    orderRequest.addProperty("iv", aesResult.ivBase64());
    orderRequest.addProperty("authTag", aesResult.authTagBase64());

    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    HttpEntity<String> request = new HttpEntity<>(gson.toJson(orderRequest), headers);

    ResponseEntity<String> response = restTemplate.postForEntity(
        baseUrl() + "/orders",
        request,
        String.class
    );

    assertEquals(HttpStatus.OK, response.getStatusCode());
    System.out.println("✓ Order submitted successfully");

    // === Step 6: Verify response ===
    System.out.println("\n=== Step 6: Verify Response ===");

    JsonObject resultJson = gson.fromJson(response.getBody(), JsonObject.class);
    assertTrue(resultJson.get("success").getAsBoolean());

    String orderId = resultJson.get("orderId").getAsString();
    String maskedCard = resultJson.get("creditCardNumber").getAsString();

    System.out.println("Order Response:");
    System.out.println("  Order ID: " + orderId);
    System.out.println("  Name: " + resultJson.get("name").getAsString());
    System.out.println("  Address: " + resultJson.get("address").getAsString());
    System.out.println("  Masked Credit Card: " + maskedCard);
    System.out.println("  Order Amount: $" + resultJson.get("orderAmount").getAsDouble());

    // Verify masked card shows last 4 digits
    assertTrue(maskedCard.endsWith("1234"), "Masked card should show last 4 digits");
    System.out.println("\n✓ SUCCESS: Order processed with encrypted credit card!");
  }

  private String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }
}

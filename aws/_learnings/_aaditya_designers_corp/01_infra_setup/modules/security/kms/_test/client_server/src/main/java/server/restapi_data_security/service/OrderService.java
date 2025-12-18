package server.restapi_data_security.service;

import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Order Service - Processes orders with encrypted PII data.
 */
@Service
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);

  private final HybridDecryptionService hybridDecryptionService;

  public OrderService(HybridDecryptionService hybridDecryptionService) {
    this.hybridDecryptionService = hybridDecryptionService;
  }

  /**
   * Processes an order with encrypted PII fields.
   *
   * @param request               The order request as JsonObject with encrypted fields
   * @param jweEncryptionMetadata The X-Encryption-Key header value (JWE)
   * @return Order response as JsonObject with masked sensitive data
   */
  public JsonObject processOrder(JsonObject request, String jweEncryptionMetadata) {
    String customerName = request.get("name").getAsString();
    log.info("Processing order for: {}", customerName);

    // Extract encrypted fields
    String encryptedDob = request.get("dateOfBirth").getAsString();
    JsonObject cardDetails = request.getAsJsonObject("cardDetails");
    String encryptedCreditCard = cardDetails.get("creditCardNumber").getAsString();
    String encryptedSsn = cardDetails.get("ssn").getAsString();

    // Decrypt all PII fields (1 KMS call for all fields)
    HybridDecryptionService.DecryptedFields decrypted = hybridDecryptionService.decryptAll(
        jweEncryptionMetadata,
        encryptedDob,
        encryptedCreditCard,
        encryptedSsn
    );

    log.debug("Decrypted - DOB: {}, Card: {}..., SSN: {}...",
        decrypted.dateOfBirth(),
        decrypted.creditCard().substring(0, 4),
        decrypted.ssn().substring(0, 3));

    // Process the order and generate order ID
    String orderId = "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    log.info("Order {} created successfully", orderId);

    // Build response with masked sensitive data
    JsonObject cardDetailsResponse = new JsonObject();
    cardDetailsResponse.addProperty("creditCardNumber", maskCreditCard(decrypted.creditCard()));
    cardDetailsResponse.addProperty("ssn", maskSsn(decrypted.ssn()));

    JsonObject response = new JsonObject();
    response.addProperty("success", true);
    response.addProperty("message", "Order submitted successfully");
    response.addProperty("orderId", orderId);
    response.addProperty("name", customerName);
    response.addProperty("address", request.get("address").getAsString());
    response.addProperty("dateOfBirth", decrypted.dateOfBirth());
    response.addProperty("orderAmount", request.get("orderAmount").getAsBigDecimal());
    response.add("cardDetails", cardDetailsResponse);

    return response;
  }

  private String maskCreditCard(String creditCard) {
    if (creditCard == null || creditCard.length() < 4) return "****-****-****-****";
    return "****-****-****-" + creditCard.substring(creditCard.length() - 4);
  }

  private String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) return "***-**-****";
    String cleaned = ssn.replace("-", "");
    if (cleaned.length() < 4) return "***-**-****";
    return "***-**-" + cleaned.substring(cleaned.length() - 4);
  }
}

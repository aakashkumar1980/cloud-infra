package server.restapi_data_security.multi_fields_encryption.service;

import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Order Service (Multi-Fields) - Processes orders with encrypted PII fields.
 */
@Service("multiFieldsOrderService")
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);

  private final HybridDecryptionService hybridDecryptionService;

  public OrderService(
      @Qualifier("multiFieldsHybridDecryptionService") HybridDecryptionService hybridDecryptionService
  ) {
    this.hybridDecryptionService = hybridDecryptionService;
  }

  /**
   * Processes an order with encrypted PII fields.
   *
   * @param orderRequest       The order JSON with encrypted fields
   * @param encryptedDataEncryptionKey The encrypted DEK from X-Encryption-Key header
   * @return Response JSON with decrypted/masked PII
   */
  public JsonObject processOrder(JsonObject orderRequest, String encryptedDataEncryptionKey) {
    // Extract encrypted fields
    String encryptedDob = orderRequest.get("dateOfBirth").getAsString();
    JsonObject cardDetails = orderRequest.getAsJsonObject("cardDetails");
    String encryptedCreditCard = cardDetails.get("creditCardNumber").getAsString();
    String encryptedSsn = cardDetails.get("ssn").getAsString();

    // Decrypt all fields (1 KMS call)
    HybridDecryptionService.DecryptedFields decrypted = hybridDecryptionService.decryptAll(
        encryptedDataEncryptionKey,
        encryptedDob,
        encryptedCreditCard,
        encryptedSsn
    );

    log.info("Decrypted PII - DOB: {} | Card: {} | SSN: {}",
        decrypted.dateOfBirth(),
        maskCard(decrypted.creditCard()),
        maskSsn(decrypted.ssn()));

    // Build response with decrypted/masked data
    JsonObject response = new JsonObject();
    response.addProperty("success", true);
    response.addProperty("orderId", UUID.randomUUID().toString());
    response.addProperty("name", orderRequest.get("name").getAsString());
    response.addProperty("dateOfBirth", decrypted.dateOfBirth());

    JsonObject responseCardDetails = new JsonObject();
    responseCardDetails.addProperty("creditCardNumber", maskCard(decrypted.creditCard()));
    responseCardDetails.addProperty("ssn", maskSsn(decrypted.ssn()));
    response.add("cardDetails", responseCardDetails);

    return response;
  }

  private String maskCard(String card) {
    if (card == null || card.length() < 4) return "****";
    return "****-****-****-" + card.substring(card.length() - 4);
  }

  private String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) return "***-**-****";
    return "***-**-" + ssn.substring(ssn.length() - 4);
  }
}

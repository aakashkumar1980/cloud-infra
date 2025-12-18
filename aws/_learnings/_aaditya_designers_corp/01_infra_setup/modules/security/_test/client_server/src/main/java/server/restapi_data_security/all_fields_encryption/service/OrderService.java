package server.restapi_data_security.all_fields_encryption.service;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Order Service (All-Fields) - Processes orders with JWE-encrypted payload.
 */
@Service("allFieldsOrderService")
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);
  private final Gson gson = new Gson();

  private final HybridDecryptionService hybridDecryptionService;

  public OrderService(
      @Qualifier("allFieldsHybridDecryptionService") HybridDecryptionService hybridDecryptionService
  ) {
    this.hybridDecryptionService = hybridDecryptionService;
  }

  /**
   * Processes an order from JWE-encrypted request body.
   *
   * @param jweRequestBody The JWE compact serialization containing the order JSON
   * @return Response JSON with decrypted/masked PII
   */
  public JsonObject processOrder(String jweRequestBody) {
    // Decrypt JWE to get original JSON payload
    String jsonPayload = hybridDecryptionService.decryptPayload(jweRequestBody);
    JsonObject orderRequest = gson.fromJson(jsonPayload, JsonObject.class);

    // Extract fields (all are now in plaintext)
    String name = orderRequest.get("name").getAsString();
    String dob = orderRequest.get("dateOfBirth").getAsString();
    JsonObject cardDetails = orderRequest.getAsJsonObject("cardDetails");
    String creditCard = cardDetails.get("creditCardNumber").getAsString();
    String ssn = cardDetails.get("ssn").getAsString();

    log.info("Decrypted order - Name: {} | DOB: {} | Card: {} | SSN: {}",
        name, dob, maskCard(creditCard), maskSsn(ssn));

    // Build response
    JsonObject response = new JsonObject();
    response.addProperty("success", true);
    response.addProperty("orderId", UUID.randomUUID().toString());
    response.addProperty("name", name);
    response.addProperty("dateOfBirth", dob);

    JsonObject responseCardDetails = new JsonObject();
    responseCardDetails.addProperty("creditCardNumber", maskCard(creditCard));
    responseCardDetails.addProperty("ssn", maskSsn(ssn));
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

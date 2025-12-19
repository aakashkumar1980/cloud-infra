package server.restapi_data_security.multi_fields_encryption.service;

import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import server.restapi_data_security._common_utils.Utils;

import java.util.UUID;

/**
 * Order Service (Multi-Fields) - Processes orders with encrypted PII fields.
 */
@Service("multiFieldsOrderService")
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);

  private Utils utils;
  private final HybridDecryptionService hybridDecryptionService;

  public OrderService(
      @Qualifier("multiFieldsHybridDecryptionService") HybridDecryptionService hybridDecryptionService,
      Utils utils
  ) {
    this.hybridDecryptionService = hybridDecryptionService;
    this.utils = utils;
  }

  /**
   * Processes an order with encrypted PII fields.
   *
   * @param order       The order JSON with encrypted fields
   * @param encryptedDataEncryptionKey The encrypted DEK from X-Encryption-Key header
   * @return Response JSON with decrypted/masked PII
   */
  public JsonObject processOrder(JsonObject order, String encryptedDataEncryptionKey) {
    // Extract encrypted fields
    String encryptedDob = order.get("dateOfBirth").getAsString();
    JsonObject cardDetails = order.getAsJsonObject("cardDetails");
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
        utils.maskCard(decrypted.creditCard()),
        utils.maskSsn(decrypted.ssn()));

    // Build response with decrypted/masked data
    JsonObject response = new JsonObject();
    response.addProperty("success", true);
    response.addProperty("orderId", UUID.randomUUID().toString());
    response.addProperty("name", order.get("name").getAsString());
    response.addProperty("dateOfBirth", decrypted.dateOfBirth());

    JsonObject responseCardDetails = new JsonObject();
    responseCardDetails.addProperty("creditCardNumber", utils.maskCard(decrypted.creditCard()));
    responseCardDetails.addProperty("ssn", utils.maskSsn(decrypted.ssn()));
    response.add("cardDetails", responseCardDetails);

    return response;
  }

}

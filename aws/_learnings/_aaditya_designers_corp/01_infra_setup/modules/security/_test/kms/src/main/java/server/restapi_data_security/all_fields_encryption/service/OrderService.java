package server.restapi_data_security.all_fields_encryption.service;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import server.restapi_data_security._common_utils.Utils;
import server.restapi_data_security.all_fields_encryption.crypto.PayloadDecryptor;

import java.util.UUID;

/**
 * Order Service (All-Fields) - Processes orders with JWE-encrypted payload.
 *
 * <h2>Server-Side Decryption Flow</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  STEP 3: Decrypt JWE via PayloadDecryptor                              │
 * │  ► payloadDecryptor.decrypt(jweString)                                 │
 * │    ├── Parse JWE to extract encryptedCek, iv, ciphertext, authTag      │
 * │    ├── KMS API call: Decrypt encryptedCek → CEK (1 call)               │
 * │    └── Local AES: Decrypt ciphertext with CEK → JSON payload           │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Service("allFieldsOrderService")
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);
  private final Gson gson = new Gson();

  private final PayloadDecryptor payloadDecryptor;
  private final Utils utils;

  public OrderService(
      PayloadDecryptor payloadDecryptor,
      Utils utils
  ) {
    this.payloadDecryptor = payloadDecryptor;
    this.utils = utils;
  }

  /**
   * Processes an order from JWE-encrypted request body.
   *
   * @param order The JWE compact serialization containing the order JSON
   * @return Response JSON with decrypted/masked PII
   */
  public JsonObject processOrder(String order) {
    // Decrypt JWE to get original JSON payload
    log.info("Decrypting JWE payload (1 KMS call for CEK, then local AES)");
    String decryptedOrder = payloadDecryptor.decrypt(order);
    log.info("Payload decrypted successfully");

    JsonObject orderJson = gson.fromJson(decryptedOrder, JsonObject.class);
    // Extract fields (all are now in plaintext)
    String name = orderJson.get("name").getAsString();
    String dob = orderJson.get("dateOfBirth").getAsString();
    JsonObject cardDetails = orderJson.getAsJsonObject("cardDetails");
    String creditCard = cardDetails.get("creditCardNumber").getAsString();
    String ssn = cardDetails.get("ssn").getAsString();

    log.info("Decrypted order - Name: {} | DOB: {} | Card: {} | SSN: {}",
        name, dob, utils.maskCard(creditCard), utils.maskSsn(ssn));

    // Build response
    JsonObject response = new JsonObject();
    response.addProperty("success", true);
    response.addProperty("orderId", UUID.randomUUID().toString());
    response.addProperty("name", name);
    response.addProperty("dateOfBirth", dob);

    JsonObject responseCardDetails = new JsonObject();
    responseCardDetails.addProperty("creditCardNumber", utils.maskCard(creditCard));
    responseCardDetails.addProperty("ssn", utils.maskSsn(ssn));
    response.add("cardDetails", responseCardDetails);

    return response;
  }

}

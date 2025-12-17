package server.restapi_data_security.controller;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import server.restapi_data_security.service.OrderService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Order Controller - REST endpoints for order operations.
 */
@RestController
@RequestMapping("/api/v1")
public class OrderController {

  private static final Logger log = LoggerFactory.getLogger(OrderController.class);
  private static final String JWT_ENCRYPTION_HEADER = "X-Encryption-Key";

  private final OrderService orderService;
  private final Gson gson = new Gson();

  public OrderController(OrderService orderService) {
    this.orderService = orderService;
  }

  /**
   * Submits an order with encrypted PII fields.
   *
   * @param jwtEncryptionMetadata The JWE-wrapped encryption key (from X-Encryption-Key header)
   * @param requestBody           The order details as JSON with encrypted fields
   * @return Order confirmation with masked PII data
   */
  @PostMapping("/orders")
  public ResponseEntity<String> submitOrder(
      @RequestHeader(value = JWT_ENCRYPTION_HEADER, required = false) String jwtEncryptionMetadata,
      @RequestBody String requestBody
  ) {
    JsonObject orderRequest = gson.fromJson(requestBody, JsonObject.class);

    // Extract all fields for logging
    String name = orderRequest.get("name").getAsString();
    String address = orderRequest.get("address").getAsString();
    String encryptedDob = orderRequest.get("dateOfBirth").getAsString();
    String orderAmount = orderRequest.get("orderAmount").toString();
    JsonObject cardDetails = orderRequest.getAsJsonObject("cardDetails");
    String encryptedCard = cardDetails.get("creditCardNumber").getAsString();
    String encryptedSsn = cardDetails.get("ssn").getAsString();

    log.info("OrderRequest received: Name: {} | Address: {} | Amount: ${} | DOB: {} | Card: {} | SSN: {}",
        name, address, orderAmount, truncate(encryptedDob), truncate(encryptedCard), truncate(encryptedSsn));

    if (jwtEncryptionMetadata == null || jwtEncryptionMetadata.isBlank()) {
      log.warn("Missing X-Encryption-Key header");
      return ResponseEntity.badRequest().body(gson.toJson(errorResponse("Missing X-Encryption-Key header")));
    }

    log.debug("X-Encryption-Key header (truncated): {}", truncate(jwtEncryptionMetadata));

    try {
      JsonObject response = orderService.processOrder(orderRequest, jwtEncryptionMetadata);
      return ResponseEntity.ok(gson.toJson(response));
    } catch (Exception e) {
      log.error("Order processing failed: {}", e.getMessage(), e);
      return ResponseEntity.badRequest().body(gson.toJson(errorResponse("Order processing failed: " + e.getMessage())));
    }
  }

  private String truncate(String str) {
    return str != null && str.length() > 40 ? str.substring(0, 40) + "..." : str;
  }

  private JsonObject errorResponse(String message) {
    JsonObject response = new JsonObject();
    response.addProperty("success", false);
    response.addProperty("message", message);
    return response;
  }

  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK");
  }
}

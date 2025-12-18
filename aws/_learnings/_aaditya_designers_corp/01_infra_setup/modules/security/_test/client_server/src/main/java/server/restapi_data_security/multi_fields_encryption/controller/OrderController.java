package server.restapi_data_security.multi_fields_encryption.controller;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import server.restapi_data_security.multi_fields_encryption.service.OrderService;

/**
 * Order Controller (Multi-Fields) - REST endpoints for orders with field-level encryption.
 *
 * <h2>Multi-Fields Encryption Approach</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  Header: X-Encryption-Key: BASE64(RSA-encrypted DEK)                   │
 * │  Body:   { "field1": "encrypted", "field2": "encrypted", ... }         │
 * │                                                                        │
 * │  Server Flow:                                                          │
 * │  1. KMS decrypt header → DEK (1 KMS call)                              │
 * │  2. Local AES decrypt each field using DEK                             │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@RestController("multiFieldsOrderController")
@RequestMapping("/api/v1/multi-fields")
public class OrderController {

  private static final Logger log = LoggerFactory.getLogger(OrderController.class);
  private static final String ENCRYPTION_KEY_HEADER = "X-Encryption-Key";

  private final OrderService orderService;
  private final Gson gson = new Gson();

  public OrderController(
      @Qualifier("multiFieldsOrderService") OrderService orderService
  ) {
    this.orderService = orderService;
  }

  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK - Multi-Fields Encryption");
  }

  /**
   * Submits an order with encrypted PII fields.
   *
   * <p>Header contains: BASE64(RSA-OAEP-256(aesDataEncryptionKey))</p>
   * <p>Body contains: JSON with individually encrypted fields</p>
   *
   * @param encryptedDekBase64 The RSA-encrypted DEK (from X-Encryption-Key header)
   * @param requestBody        The order details as JSON with encrypted fields
   * @return Order confirmation with masked PII data
   */
  @PostMapping("/orders")
  public ResponseEntity<String> submitOrder(
      @RequestHeader(value = ENCRYPTION_KEY_HEADER, required = false) String encryptedDekBase64,
      @RequestBody String requestBody
  ) {
    JsonObject orderRequest = gson.fromJson(requestBody, JsonObject.class);
    log.info("[Multi-Fields] Order received - Name: {} | Encrypted fields in body",
        orderRequest.get("name").getAsString());

    // Validate presence of encryption header
    if (encryptedDekBase64 == null || encryptedDekBase64.isBlank()) {
      log.warn("Missing X-Encryption-Key header");
      return ResponseEntity.badRequest().body(gson.toJson(errorResponse("Missing X-Encryption-Key header")));
    }

    try {
      JsonObject response = orderService.processOrder(orderRequest, encryptedDekBase64);
      return ResponseEntity.ok(gson.toJson(response));
    } catch (Exception e) {
      log.error("Order processing failed: {}", e.getMessage(), e);
      return ResponseEntity.badRequest().body(gson.toJson(errorResponse("Order processing failed: " + e.getMessage())));
    }
  }

  private JsonObject errorResponse(String message) {
    JsonObject response = new JsonObject();
    response.addProperty("success", false);
    response.addProperty("message", message);
    return response;
  }
}

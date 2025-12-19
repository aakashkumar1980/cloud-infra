package server.restapi_data_security.all_fields_encryption.controller;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import server.restapi_data_security._common_utils.Utils;
import server.restapi_data_security.all_fields_encryption.service.OrderService;

/**
 * Order Controller (All-Fields) - REST endpoints for JWE-encrypted payloads.
 *
 * <h2>All-Fields Encryption Approach</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  Body: JWE string (entire encrypted JSON payload)                      │
 * │                                                                        │
 * │  JWE contains:                                                         │
 * │  - Header (algorithm info)                                             │
 * │  - EncryptedCek (RSA-encrypted CEK)                                    │
 * │  - IV + Ciphertext + AuthTag (AES-encrypted payload)                   │
 * │                                                                        │
 * │  Server Flow:                                                          │
 * │  1. Parse JWE                                                          │
 * │  2. KMS decrypt encryptedCek → CEK (1 KMS call)                        │
 * │  3. Local AES decrypt ciphertext → JSON payload                        │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@RestController("allFieldsOrderController")
@RequestMapping("/api/v1/all-fields")
public class OrderController {

  private static final Logger log = LoggerFactory.getLogger(OrderController.class);

  private final OrderService orderService;
  private final Gson gson = new Gson();
  private Utils utils;

  public OrderController(
      @Qualifier("allFieldsOrderService") OrderService orderService,
      Utils utils
  ) {
    this.orderService = orderService;
    this.utils = utils;
  }

  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK - All-Fields JWE Encryption");
  }

  /**
   * Submits an order with JWE-encrypted request body.
   *
   * <p>Request body is the JWE compact serialization containing the entire
   * encrypted JSON payload.</p>
   *
   * @param requestBody The JWE string (Header.EncryptedCek.IV.Ciphertext.AuthTag)
   * @return Order confirmation with decrypted/masked PII
   */
  @PostMapping(value = "/orders", consumes = "text/plain")
  public ResponseEntity<String> submitOrder(
      @RequestBody String requestBody
  ) {
    log.info("[All-Fields] JWE request received (length={})", requestBody.length());

    if (requestBody == null || requestBody.isBlank()) {
      return ResponseEntity.badRequest().body(gson.toJson(utils.errorResponse("Empty request body")));
    }

    // Validate JWE format (5 dot-separated parts)
    if (requestBody.split("\\.").length != 5) {
      return ResponseEntity.badRequest().body(gson.toJson(utils.errorResponse("Invalid JWE format")));
    }

    try {
      JsonObject response = orderService.processOrder(requestBody);
      return ResponseEntity.ok(gson.toJson(response));
    } catch (Exception e) {
      log.error("Order processing failed: {}", e.getMessage(), e);
      return ResponseEntity.badRequest().body(gson.toJson(utils.errorResponse("Order processing failed: " + e.getMessage())));
    }
  }

}

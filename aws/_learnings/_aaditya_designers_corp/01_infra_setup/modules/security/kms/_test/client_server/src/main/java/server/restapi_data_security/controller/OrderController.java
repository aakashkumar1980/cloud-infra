package server.restapi_data_security.controller;

import server.restapi_data_security.dto.OrderRequest;
import server.restapi_data_security.dto.OrderResponse;
import server.restapi_data_security.service.OrderService;
import jakarta.validation.Valid;
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

  public OrderController(OrderService orderService) {
    this.orderService = orderService;
  }

  /**
   * Submits an order with encrypted PII fields.
   *
   * @param jwtEncryptionMetadata The JWE-wrapped encryption key (from X-Encryption-Key header)
   * @param orderRequest          The order details with encrypted fields
   * @return Order confirmation with masked PII data
   */
  @PostMapping("/orders")
  public ResponseEntity<OrderResponse> submitOrder(
      @RequestHeader(value = JWT_ENCRYPTION_HEADER, required = false) String jwtEncryptionMetadata,
      @Valid @RequestBody OrderRequest orderRequest
  ) {
    log.info("Order request received from: {}", orderRequest.name());

    if (jwtEncryptionMetadata == null || jwtEncryptionMetadata.isBlank()) {
      log.warn("Missing X-Encryption-Key header");
      return ResponseEntity.badRequest().body(OrderResponse.error("Missing X-Encryption-Key header"));
    }

    try {
      OrderResponse response = orderService.processOrder(orderRequest, jwtEncryptionMetadata);
      return ResponseEntity.ok(response);
    } catch (Exception e) {
      log.error("Order processing failed: {}", e.getMessage(), e);
      return ResponseEntity.badRequest().body(OrderResponse.error("Order processing failed: " + e.getMessage()));
    }
  }

  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK");
  }
}

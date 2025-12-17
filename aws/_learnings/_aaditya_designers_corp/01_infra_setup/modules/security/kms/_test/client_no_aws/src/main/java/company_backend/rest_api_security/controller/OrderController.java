package company_backend.rest_api_security.controller;

import company_backend.rest_api_security.dto.OrderRequest;
import company_backend.rest_api_security.dto.OrderResponse;
import company_backend.rest_api_security.service.OrderService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Order Controller - REST endpoints for order operations.
 *
 * <p>This controller handles incoming order requests with encrypted PII data.
 * It extracts the encryption header and delegates to the OrderService for
 * decryption and processing.</p>
 *
 * <h3>Encryption Header:</h3>
 * <p>Clients must include the X-Encryption-Key header containing the JWE-wrapped
 * encryption key. This key is used to decrypt all PII fields in the request.</p>
 *
 * <h3>Endpoints:</h3>
 * <ul>
 *   <li><b>POST /api/v1/orders</b> - Submit order with encrypted PII</li>
 *   <li><b>GET /api/v1/health</b> - Health check</li>
 * </ul>
 *
 * <h3>Example Request:</h3>
 * <pre>
 * POST /api/v1/orders
 * Content-Type: application/json
 * X-Encryption-Key: eyJhbGciOiJSU0EtT0FFUC0yNTYi...
 *
 * {
 *   "name": "John Doe",
 *   "address": "123 Main St",
 *   "dateOfBirth": "abc.xyz.123",
 *   "orderAmount": 100.00,
 *   "cardDetails": {
 *     "creditCardNumber": "def.uvw.456",
 *     "ssn": "ghi.rst.789"
 *   }
 * }
 * </pre>
 */
@RestController
@RequestMapping("/api/v1")
public class OrderController {

  private static final Logger log = LoggerFactory.getLogger(OrderController.class);
  private static final String ENCRYPTION_HEADER = "X-Encryption-Key";

  private final OrderService orderService;

  public OrderController(OrderService orderService) {
    this.orderService = orderService;
  }

  /**
   * Submits an order with encrypted PII fields.
   *
   * <p>The encryption key is extracted from the X-Encryption-Key header and
   * passed to the OrderService for decryption and processing.</p>
   *
   * @param encryptionHeader The JWE-wrapped encryption key (from header)
   * @param orderRequest     The order details with encrypted fields
   * @return Order confirmation with masked PII data
   *
   * <h4>Response Codes:</h4>
   * <ul>
   *   <li><b>200 OK:</b> Order processed successfully</li>
   *   <li><b>400 Bad Request:</b> Missing header, invalid encryption, or validation error</li>
   * </ul>
   */
  @PostMapping("/orders")
  public ResponseEntity<OrderResponse> submitOrder(
      @RequestHeader(value = ENCRYPTION_HEADER, required = false) String encryptionHeader,
      @Valid @RequestBody OrderRequest orderRequest
  ) {
    log.info("Order request received from: {}", orderRequest.name());

    // Validate encryption header
    if (encryptionHeader == null || encryptionHeader.isBlank()) {
      log.warn("Missing X-Encryption-Key header");
      return ResponseEntity.badRequest()
          .body(OrderResponse.error("Missing X-Encryption-Key header"));
    }

    try {
      // Delegate to service for decryption and processing
      OrderResponse response = orderService.processOrder(orderRequest, encryptionHeader);
      return ResponseEntity.ok(response);

    } catch (Exception e) {
      log.error("Order processing failed: {}", e.getMessage(), e);
      return ResponseEntity.badRequest()
          .body(OrderResponse.error("Order processing failed: " + e.getMessage()));
    }
  }

  /**
   * Health check endpoint.
   *
   * @return "OK" if the service is healthy
   */
  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK");
  }
}

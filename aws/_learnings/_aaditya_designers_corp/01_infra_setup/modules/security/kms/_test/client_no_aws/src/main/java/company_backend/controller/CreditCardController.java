package company_backend.controller;

import company_backend.dto.DecryptRequest;
import company_backend.dto.OrderRequest;
import company_backend.dto.OrderResponse;
import company_backend.service.DecryptionService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * REST Controller for Credit Card / Order Operations
 *
 * Use-Case: 3rd Party WITHOUT AWS Account submits orders with encrypted credit card
 *
 * Endpoints:
 * - POST /api/v1/orders : Submit order with encrypted credit card number
 * - GET /api/v1/health : Health check
 */
@RestController
@RequestMapping("/api/v1")
public class CreditCardController {

  private static final Logger log = LoggerFactory.getLogger(CreditCardController.class);

  private final DecryptionService decryptionService;

  public CreditCardController(DecryptionService decryptionService) {
    this.decryptionService = decryptionService;
  }

  /**
   * POST /api/v1/orders
   *
   * Submit an order with encrypted credit card number.
   * The credit card is decrypted server-side using KMS.
   *
   * @param orderRequest Order details with encrypted credit card
   * @return Order confirmation with masked credit card
   */
  @PostMapping("/orders")
  public ResponseEntity<OrderResponse> submitOrder(@Valid @RequestBody OrderRequest orderRequest) {
    log.info("Order received from: {}", orderRequest.name());

    try {
      // Decrypt the credit card number
      DecryptRequest decryptRequest = new DecryptRequest(
          orderRequest.encryptedDek(),
          orderRequest.creditCardNumber(),  // This is the encrypted credit card
          orderRequest.iv(),
          orderRequest.authTag()
      );

      String decryptedCreditCard = decryptionService.decrypt(decryptRequest);
      log.info("Credit card decrypted successfully");

      // Mask the credit card for response (show last 4 digits)
      String maskedCreditCard = maskCreditCard(decryptedCreditCard);

      // Generate order ID
      String orderId = "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

      log.info("Order {} processed successfully", orderId);

      return ResponseEntity.ok(OrderResponse.success(
          orderId,
          orderRequest.name(),
          orderRequest.address(),
          maskedCreditCard,
          orderRequest.orderAmount()
      ));

    } catch (Exception e) {
      log.error("Order processing failed", e);
      return ResponseEntity.badRequest()
          .body(OrderResponse.error("Order processing failed: " + e.getMessage()));
    }
  }

  /**
   * Mask credit card number, showing only last 4 digits
   * Example: 4111111111111111 -> ****-****-****-1111
   */
  private String maskCreditCard(String creditCard) {
    if (creditCard == null || creditCard.length() < 4) {
      return "****";
    }
    String last4 = creditCard.substring(creditCard.length() - 4);
    return "****-****-****-" + last4;
  }

  /**
   * Health check endpoint
   */
  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK");
  }
}

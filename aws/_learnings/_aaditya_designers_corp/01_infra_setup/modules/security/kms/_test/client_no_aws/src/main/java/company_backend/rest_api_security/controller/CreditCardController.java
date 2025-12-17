package company_backend.rest_api_security.controller;

import company_backend.rest_api_security.dto.OrderRequest;
import company_backend.rest_api_security.dto.OrderResponse;
import company_backend.rest_api_security.service.APIDecryptionService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * REST Controller for Order Operations (Hybrid Encryption)
 *
 * Use-Case: 3rd Party WITHOUT AWS Account submits orders with encrypted PII
 *
 * Encryption Flow:
 * 1. Client generates DEK (AES-256 key)
 * 2. Client encrypts PII fields with DEK using AES-256-GCM
 * 3. Client wraps DEK in JWE using company's RSA public key
 * 4. Client sends: X-Encryption-Key header (JWE) + body with encrypted fields
 *
 * Decryption Flow:
 * 1. EncryptionFilter extracts JWE from header, unwraps DEK via KMS (1 API call)
 * 2. Controller receives request, calls APIDecryptionService for each PII field
 * 3. APIDecryptionService decrypts fields locally using DEK (no KMS calls)
 *
 * Endpoints:
 * - POST /api/v1/orders : Submit order with encrypted PII
 * - GET /api/v1/health : Health check
 */
@RestController
@RequestMapping("/api/v1")
public class CreditCardController {

  private static final Logger log = LoggerFactory.getLogger(CreditCardController.class);

  private final APIDecryptionService apiDecryptionService;

  public CreditCardController(APIDecryptionService apiDecryptionService) {
    this.apiDecryptionService = apiDecryptionService;
  }

  /**
   * POST /api/v1/orders
   *
   * Submit an order with AES-encrypted PII fields.
   * Requires X-Encryption-Key header containing the JWE-wrapped DEK.
   *
   * @param orderRequest Order details with encrypted PII fields
   * @return Order confirmation with masked PII
   */
  @PostMapping("/orders")
  public ResponseEntity<OrderResponse> submitOrder(@Valid @RequestBody OrderRequest orderRequest) {
    log.info("Order received from: {}", orderRequest.name());

    try {
      // Decrypt PII fields using DEK from EncryptionContext (set by EncryptionFilter)
      String decryptedDob = apiDecryptionService.decryptField(orderRequest.dateOfBirth());
      String decryptedCreditCard = apiDecryptionService.decryptField(
          orderRequest.cardDetails().creditCardNumber());
      String decryptedSsn = apiDecryptionService.decryptField(
          orderRequest.cardDetails().ssn());

      log.info("PII fields decrypted successfully");
      log.debug("DOB: {}, CreditCard: {}..., SSN: {}...",
          decryptedDob,
          decryptedCreditCard.substring(0, 4),
          decryptedSsn.substring(0, 3));

      // Mask sensitive data for response
      String maskedCreditCard = maskCreditCard(decryptedCreditCard);
      String maskedSsn = maskSsn(decryptedSsn);

      // Generate order ID
      String orderId = "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

      log.info("Order {} processed successfully", orderId);

      return ResponseEntity.ok(OrderResponse.success(
          orderId,
          orderRequest.name(),
          orderRequest.address(),
          decryptedDob,
          orderRequest.orderAmount(),
          maskedCreditCard,
          maskedSsn
      ));

    } catch (Exception e) {
      log.error("Order processing failed", e);
      return ResponseEntity.badRequest()
          .body(OrderResponse.error("Order processing failed: " + e.getMessage()));
    }
  }

  /**
   * Mask credit card number, showing only last 4 digits
   * Example: 4111111111111234 -> ****-****-****-1234
   */
  private String maskCreditCard(String creditCard) {
    if (creditCard == null || creditCard.length() < 4) {
      return "****";
    }
    String last4 = creditCard.substring(creditCard.length() - 4);
    return "****-****-****-" + last4;
  }

  /**
   * Mask SSN, showing only last 4 digits
   * Example: 123-45-6789 -> ***-**-6789
   */
  private String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) {
      return "***-**-****";
    }
    // Remove dashes for processing
    String cleaned = ssn.replace("-", "");
    if (cleaned.length() < 4) {
      return "***-**-****";
    }
    String last4 = cleaned.substring(cleaned.length() - 4);
    return "***-**-" + last4;
  }

  /**
   * Health check endpoint
   */
  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK");
  }
}

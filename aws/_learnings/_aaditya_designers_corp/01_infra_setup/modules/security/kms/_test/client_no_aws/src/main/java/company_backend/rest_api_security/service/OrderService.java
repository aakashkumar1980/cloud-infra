package company_backend.rest_api_security.service;

import company_backend.rest_api_security.crypto.HybridDecryptionHelper;
import company_backend.rest_api_security.dto.CardDetails;
import company_backend.rest_api_security.dto.OrderRequest;
import company_backend.rest_api_security.dto.OrderResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Order Service - Processes orders with encrypted PII data.
 *
 * <p>This service handles the business logic for order processing, including
 * decryption of sensitive fields and masking for response.</p>
 *
 * <h3>Responsibilities:</h3>
 * <ul>
 *   <li>Decrypt PII fields from the request</li>
 *   <li>Process the order (validation, storage, etc.)</li>
 *   <li>Mask sensitive data for the response</li>
 *   <li>Generate order confirmation</li>
 * </ul>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * String header = request.getHeader("X-Encryption-Key");
 * OrderResponse response = orderService.processOrder(orderRequest, header);
 * }</pre>
 */
@Service
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);

  private final HybridDecryptionHelper decryptionHelper;

  public OrderService(HybridDecryptionHelper decryptionHelper) {
    this.decryptionHelper = decryptionHelper;
  }

  /**
   * Processes an order with encrypted PII fields.
   *
   * <p>Decrypts all sensitive fields, processes the order, and returns
   * a response with masked PII data.</p>
   *
   * @param request          The order request with encrypted fields
   * @param encryptionHeader The X-Encryption-Key header value (JWE)
   * @return Order response with masked sensitive data
   * @throws RuntimeException if decryption or processing fails
   */
  public OrderResponse processOrder(OrderRequest request, String encryptionHeader) {
    log.info("Processing order for: {}", request.name());

    // Step 1: Decrypt all PII fields (1 KMS call for all fields)
    CardDetails encryptedCard = request.cardDetails();
    HybridDecryptionHelper.DecryptedFields decrypted = decryptionHelper.decryptAll(
        encryptionHeader,
        request.dateOfBirth(),
        encryptedCard.creditCardNumber(),
        encryptedCard.ssn()
    );

    log.debug("Decrypted DOB: {}, Card: {}..., SSN: {}...",
        decrypted.dateOfBirth(),
        decrypted.creditCard().substring(0, 4),
        decrypted.ssn().substring(0, 3));

    // Step 2: Process the order (business logic would go here)
    // - Validate card number (Luhn check)
    // - Check fraud rules
    // - Process payment
    // - Save to database
    // For now, we just generate an order ID

    String orderId = generateOrderId();
    log.info("Order {} created successfully", orderId);

    // Step 3: Mask sensitive data for response
    String maskedCard = maskCreditCard(decrypted.creditCard());
    String maskedSsn = maskSsn(decrypted.ssn());

    // Step 4: Build and return response
    return OrderResponse.success(
        orderId,
        request.name(),
        request.address(),
        decrypted.dateOfBirth(),
        request.orderAmount(),
        maskedCard,
        maskedSsn
    );
  }

  /**
   * Generates a unique order ID.
   *
   * @return Order ID in format: ORD-XXXXXXXX
   */
  private String generateOrderId() {
    return "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
  }

  /**
   * Masks a credit card number, showing only the last 4 digits.
   *
   * @param creditCard The full credit card number
   * @return Masked card number (e.g., "****-****-****-1234")
   */
  private String maskCreditCard(String creditCard) {
    if (creditCard == null || creditCard.length() < 4) {
      return "****-****-****-****";
    }
    String last4 = creditCard.substring(creditCard.length() - 4);
    return "****-****-****-" + last4;
  }

  /**
   * Masks an SSN, showing only the last 4 digits.
   *
   * @param ssn The full SSN (with or without dashes)
   * @return Masked SSN (e.g., "***-**-6789")
   */
  private String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) {
      return "***-**-****";
    }
    String cleaned = ssn.replace("-", "");
    if (cleaned.length() < 4) {
      return "***-**-****";
    }
    String last4 = cleaned.substring(cleaned.length() - 4);
    return "***-**-" + last4;
  }
}

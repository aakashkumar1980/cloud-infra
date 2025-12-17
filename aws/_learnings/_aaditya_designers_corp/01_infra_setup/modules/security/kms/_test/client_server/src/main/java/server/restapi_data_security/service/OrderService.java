package server.restapi_data_security.service;

import server.restapi_data_security.dto.CardDetails;
import server.restapi_data_security.dto.OrderRequest;
import server.restapi_data_security.dto.OrderResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Order Service - Processes orders with encrypted PII data.
 */
@Service
public class OrderService {

  private static final Logger log = LoggerFactory.getLogger(OrderService.class);

  private final HybridDecryptionService hybridDecryptionService;

  public OrderService(HybridDecryptionService hybridDecryptionService) {
    this.hybridDecryptionService = hybridDecryptionService;
  }

  /**
   * Processes an order with encrypted PII fields.
   *
   * @param request               The order request with encrypted fields
   * @param jwtEncryptionMetadata The X-Encryption-Key header value (JWE)
   * @return Order response with masked sensitive data
   */
  public OrderResponse processOrder(OrderRequest request, String jwtEncryptionMetadata) {
    log.info("Processing order for: {}", request.name());

    // Decrypt all PII fields (1 KMS call for all fields)
    CardDetails encryptedCard = request.cardDetails();
    HybridDecryptionService.DecryptedFields decrypted = hybridDecryptionService.decryptAll(
        jwtEncryptionMetadata,
        request.dateOfBirth(),
        encryptedCard.creditCardNumber(),
        encryptedCard.ssn()
    );

    log.debug("Decrypted - DOB: {}, Card: {}..., SSN: {}...",
        decrypted.dateOfBirth(),
        decrypted.creditCard().substring(0, 4),
        decrypted.ssn().substring(0, 3));

    // Process the order and generate order ID
    String orderId = "ORD-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    log.info("Order {} created successfully", orderId);

    // Mask sensitive data and return response
    return OrderResponse.success(
        orderId,
        request.name(),
        request.address(),
        decrypted.dateOfBirth(),
        request.orderAmount(),
        maskCreditCard(decrypted.creditCard()),
        maskSsn(decrypted.ssn())
    );
  }

  private String maskCreditCard(String creditCard) {
    if (creditCard == null || creditCard.length() < 4) return "****-****-****-****";
    return "****-****-****-" + creditCard.substring(creditCard.length() - 4);
  }

  private String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) return "***-**-****";
    String cleaned = ssn.replace("-", "");
    if (cleaned.length() < 4) return "***-**-****";
    return "***-**-" + cleaned.substring(cleaned.length() - 4);
  }
}

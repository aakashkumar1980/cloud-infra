package server.restapi_data_security.dto;

import java.math.BigDecimal;

/**
 * Order response after processing
 *
 * Contains order confirmation with decrypted PII fields (masked for display).
 */
public record OrderResponse(
    Boolean success,
    String message,
    String orderId,
    String name,
    String address,
    String dateOfBirth,       // Decrypted (could be masked if needed)
    BigDecimal orderAmount,
    CardDetailsResponse cardDetails
) {
  /**
   * Nested response for card details (masked)
   */
  public record CardDetailsResponse(
      String creditCardNumber,  // Masked: ****-****-****-1234
      String ssn                // Masked: ***-**-6789
  ) {}

  public static OrderResponse success(
      String orderId,
      String name,
      String address,
      String dateOfBirth,
      BigDecimal orderAmount,
      String maskedCreditCard,
      String maskedSsn
  ) {
    return new OrderResponse(
        Boolean.TRUE,
        "Order submitted successfully",
        orderId,
        name,
        address,
        dateOfBirth,
        orderAmount,
        new CardDetailsResponse(maskedCreditCard, maskedSsn)
    );
  }

  public static OrderResponse error(String message) {
    return new OrderResponse(Boolean.FALSE, message, null, null, null, null, null, null);
  }
}

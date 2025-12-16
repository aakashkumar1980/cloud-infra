package company_backend.rest_api_security.dto;

import java.math.BigDecimal;

/**
 * Order response after processing
 *
 * Contains order confirmation with decrypted credit card (masked for display).
 */
public record OrderResponse(
    Boolean success,
    String message,
    String orderId,
    String name,
    String address,
    String creditCardNumber,  // Decrypted and masked (e.g., ****-****-****-1234)
    BigDecimal orderAmount
) {
  public static OrderResponse success(String orderId, String name, String address,
                                      String maskedCreditCard, BigDecimal orderAmount) {
    return new OrderResponse(
        Boolean.TRUE,
        "Order submitted successfully",
        orderId,
        name,
        address,
        maskedCreditCard,
        orderAmount
    );
  }

  public static OrderResponse error(String message) {
    return new OrderResponse(Boolean.FALSE, message, null, null, null, null, null);
  }
}

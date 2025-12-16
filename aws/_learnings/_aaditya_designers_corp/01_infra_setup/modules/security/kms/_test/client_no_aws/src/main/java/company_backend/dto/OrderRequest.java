package company_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

/**
 * Order request from 3rd party client
 *
 * Contains order details with RSA-encrypted credit card number.
 * The credit card is encrypted directly with the company's public key (RSA-OAEP SHA-256).
 * Server decrypts using private key in KMS.
 */
public record OrderRequest(
    @NotBlank(message = "name is required")
    String name,

    @NotBlank(message = "address is required")
    String address,

    @NotBlank(message = "creditCardNumber is required")
    String creditCardNumber,  // RSA encrypted, Base64 encoded

    @NotNull(message = "orderAmount is required")
    @Positive(message = "orderAmount must be positive")
    BigDecimal orderAmount
) {}

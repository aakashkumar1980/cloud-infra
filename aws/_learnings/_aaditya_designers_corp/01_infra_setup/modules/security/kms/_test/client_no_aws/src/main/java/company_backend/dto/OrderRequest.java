package company_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

/**
 * Order request from 3rd party client
 *
 * Contains order details with encrypted credit card number.
 * The credit card is encrypted using envelope encryption:
 * - creditCardNumber: Encrypted with AES-GCM (Base64)
 * - encryptedDek: DEK encrypted with RSA public key (Base64)
 * - iv: Initialization vector for AES-GCM (Base64)
 * - authTag: Authentication tag for integrity (Base64)
 */
public record OrderRequest(
    @NotBlank(message = "name is required")
    String name,

    @NotBlank(message = "address is required")
    String address,

    @NotBlank(message = "creditCardNumber is required")
    String creditCardNumber,

    @NotNull(message = "orderAmount is required")
    @Positive(message = "orderAmount must be positive")
    BigDecimal orderAmount,

    @NotBlank(message = "encryptedDek is required")
    String encryptedDek,

    @NotBlank(message = "iv is required")
    String iv,

    @NotBlank(message = "authTag is required")
    String authTag
) {}

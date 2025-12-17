package company_backend.rest_api_security.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

/**
 * Order request from 3rd party client (Hybrid Encryption)
 *
 * Encryption Flow:
 * 1. Client generates random DEK (AES-256 key)
 * 2. Client encrypts each PII field with DEK using AES-256-GCM
 * 3. Client wraps DEK in JWE using company's RSA public key
 * 4. Client sends: JWE in X-Encryption-Key header + encrypted fields in body
 *
 * PII Fields (encrypted):
 * - dateOfBirth: AES encrypted (iv.ciphertext.authTag)
 * - cardDetails.creditCardNumber: AES encrypted
 * - cardDetails.ssn: AES encrypted
 *
 * Non-PII Fields (plaintext):
 * - name, address, orderAmount
 */
public record OrderRequest(
    @NotBlank(message = "name is required")
    String name,

    @NotBlank(message = "address is required")
    String address,

    @NotBlank(message = "dateOfBirth is required")
    String dateOfBirth,  // AES encrypted: iv.ciphertext.authTag

    @NotNull(message = "orderAmount is required")
    @Positive(message = "orderAmount must be positive")
    BigDecimal orderAmount,

    @NotNull(message = "cardDetails is required")
    @Valid
    CardDetails cardDetails
) {}

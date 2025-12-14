package company_backend.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Request payload from 3rd party client
 *
 * Contains:
 * - encryptedDek: DEK encrypted with our public key (RSA-OAEP)
 * - encryptedData: Actual data encrypted with DEK (AES-GCM)
 * - iv: Initialization vector used for AES-GCM
 * - authTag: Authentication tag from AES-GCM (for integrity)
 *
 * All values are Base64 encoded
 */
public record DecryptRequest(
        @NotBlank(message = "encryptedDek is required")
        String encryptedDek,

        @NotBlank(message = "encryptedData is required")
        String encryptedData,

        @NotBlank(message = "iv is required")
        String iv,

        @NotBlank(message = "authTag is required")
        String authTag
) {}

package server.restapi_data_security.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Card details containing sensitive PII fields
 *
 * All fields are AES-256-GCM encrypted by the client using a shared DEK.
 * Format: BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
 *
 * The DEK is sent separately in the X-Encryption-Key header (JWE format).
 */
public record CardDetails(
    @NotBlank(message = "creditCardNumber is required")
    String creditCardNumber,  // AES encrypted: iv.ciphertext.authTag

    @NotBlank(message = "ssn is required")
    String ssn                // AES encrypted: iv.ciphertext.authTag
) {}

package com.aadityadesigners.kms.controller;

import com.aadityadesigners.kms.dto.DecryptRequest;
import com.aadityadesigners.kms.dto.DecryptResponse;
import com.aadityadesigners.kms.dto.PublicKeyResponse;
import com.aadityadesigners.kms.service.DecryptionService;
import com.aadityadesigners.kms.service.PublicKeyService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for Encryption Operations
 *
 * Use-Case 1: 3rd Party WITHOUT AWS Account
 *
 * Endpoints:
 * - GET  /api/v1/public-key : Get public key for 3rd party to encrypt their DEK
 * - POST /api/v1/decrypt    : Decrypt data sent by 3rd party
 */
@RestController
@RequestMapping("/api/v1")
public class EncryptionController {

    private static final Logger log = LoggerFactory.getLogger(EncryptionController.class);

    private final PublicKeyService publicKeyService;
    private final DecryptionService decryptionService;

    public EncryptionController(
            PublicKeyService publicKeyService,
            DecryptionService decryptionService
    ) {
        this.publicKeyService = publicKeyService;
        this.decryptionService = decryptionService;
    }

    /**
     * GET /api/v1/public-key
     *
     * Returns the public key in PEM format.
     * 3rd party clients call this once to get the key for encrypting their DEK.
     */
    @GetMapping("/public-key")
    public ResponseEntity<PublicKeyResponse> getPublicKey() {
        log.info("Public key requested");

        String publicKeyPem = publicKeyService.getPublicKeyPem();
        String keyId = publicKeyService.getKeyId();

        return ResponseEntity.ok(PublicKeyResponse.of(publicKeyPem, keyId));
    }

    /**
     * POST /api/v1/decrypt
     *
     * Decrypts data sent by 3rd party.
     *
     * The request contains:
     * - encryptedDek: DEK encrypted with our public key (RSA-OAEP)
     * - encryptedData: Data encrypted with DEK (AES-GCM)
     * - iv: Initialization vector for AES-GCM
     * - authTag: Authentication tag for AES-GCM integrity
     */
    @PostMapping("/decrypt")
    public ResponseEntity<DecryptResponse> decrypt(@Valid @RequestBody DecryptRequest request) {
        log.info("Decrypt request received");

        try {
            String plaintext = decryptionService.decrypt(request);
            return ResponseEntity.ok(DecryptResponse.success(plaintext));

        } catch (Exception e) {
            log.error("Decryption failed", e);
            return ResponseEntity.badRequest()
                    .body(DecryptResponse.error("Decryption failed: " + e.getMessage()));
        }
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("OK");
    }
}

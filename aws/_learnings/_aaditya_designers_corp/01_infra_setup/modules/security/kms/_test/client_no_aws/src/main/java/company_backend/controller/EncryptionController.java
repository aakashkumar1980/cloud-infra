package company_backend.controller;

import company_backend.dto.DecryptRequest;
import company_backend.dto.DecryptResponse;
import company_backend.service.DecryptionService;
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
 * - POST /api/v1/decrypt : Decrypt data sent by 3rd party
 *
 * Note: Public key is shared manually (downloaded and sent via secure email),
 * NOT exposed via API for security reasons.
 */
@RestController
@RequestMapping("/api/v1")
public class EncryptionController {

    private static final Logger log = LoggerFactory.getLogger(EncryptionController.class);

    private final DecryptionService decryptionService;

    public EncryptionController(DecryptionService decryptionService) {
        this.decryptionService = decryptionService;
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

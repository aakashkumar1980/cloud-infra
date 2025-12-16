package company_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST Controller for Health Check
 *
 * Note: Decryption is now handled directly via DecryptionService
 * (called from CompanyBackendDecryptionTest), not via REST API.
 */
@RestController
@RequestMapping("/api/v1")
public class EncryptionController {

  /**
   * Health check endpoint
   */
  @GetMapping("/health")
  public ResponseEntity<String> health() {
    return ResponseEntity.ok("OK");
  }
}

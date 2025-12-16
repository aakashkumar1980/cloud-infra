package company_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Company Backend Application
 *
 * Packages:
 * - rest_api_security : PII data protection for REST API payloads
 * - file_security     : File encryption/decryption (coming soon)
 *
 * REST API Security (Use-Case: 3rd Party WITHOUT AWS Account):
 * - POST /api/v1/orders : Submit order with RSA-encrypted credit card
 * - GET /api/v1/health  : Health check
 *
 * Flow:
 * 1. 3rd party receives public key via email (one-time)
 * 2. Encrypts PII data (credit card) with public key
 * 3. Sends order to this API
 * 4. Backend decrypts using KMS (private key never leaves KMS)
 */
@SpringBootApplication
public class CompanyBackendApplication {

  public static void main(String[] args) {
    SpringApplication.run(CompanyBackendApplication.class, args);
  }
}

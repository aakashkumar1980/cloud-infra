package company_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Company Backend Application
 *
 * Use-Case 1: 3rd Party WITHOUT AWS Account
 *
 * This backend provides:
 * - GET /api/v1/public-key : Export public key for 3rd party
 * - POST /api/v1/decrypt   : Decrypt data sent by 3rd party
 *
 * The 3rd party client:
 * 1. Gets public key from this API (one-time)
 * 2. Encrypts their data locally using public key
 * 3. Sends encrypted data to this API
 * 4. This backend decrypts using KMS (private key never leaves KMS)
 */
@SpringBootApplication
public class CompanyBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(CompanyBackendApplication.class, args);
    }
}

package com.aadityadesigners.kms;

import com.aadityadesigners.kms.service.KmsEncryptionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * KMS Encryption Demo Application
 *
 * Demonstrates AWS KMS encryption/decryption using AWS Encryption SDK.
 *
 * Prerequisites:
 * 1. AWS credentials configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
 * 2. KMS key created via Terraform (01_infra_setup)
 * 3. Set KMS_KEY_ARN environment variable with your key ARN
 *
 * Run: ./gradlew bootRun
 */
@SpringBootApplication
public class KmsEncryptionDemoApplication {

    private static final Logger log = LoggerFactory.getLogger(KmsEncryptionDemoApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(KmsEncryptionDemoApplication.class, args);
    }

    @Bean
    CommandLineRunner demo(KmsEncryptionService encryptionService) {
        return args -> {
            log.info("=".repeat(60));
            log.info("KMS ENCRYPTION DEMO - AWS Encryption SDK");
            log.info("=".repeat(60));

            // Sample data to encrypt
            String originalText = "Hello, Aaditya Designers! This is sensitive data.";
            log.info("\n[1] Original Text: {}", originalText);

            // Encrypt
            log.info("\n[2] Encrypting with KMS...");
            byte[] encryptedData = encryptionService.encrypt(originalText);
            String encryptedBase64 = java.util.Base64.getEncoder().encodeToString(encryptedData);
            log.info("Encrypted (Base64): {}...", encryptedBase64.substring(0, Math.min(80, encryptedBase64.length())));
            log.info("Encrypted size: {} bytes", encryptedData.length);

            // Decrypt
            log.info("\n[3] Decrypting with KMS...");
            String decryptedText = encryptionService.decrypt(encryptedData);
            log.info("Decrypted Text: {}", decryptedText);

            // Verify
            log.info("\n[4] Verification:");
            boolean match = originalText.equals(decryptedText);
            log.info("Original matches Decrypted: {}", match ? "✓ SUCCESS" : "✗ FAILED");

            log.info("\n" + "=".repeat(60));
            log.info("DEMO COMPLETE");
            log.info("=".repeat(60));
        };
    }
}

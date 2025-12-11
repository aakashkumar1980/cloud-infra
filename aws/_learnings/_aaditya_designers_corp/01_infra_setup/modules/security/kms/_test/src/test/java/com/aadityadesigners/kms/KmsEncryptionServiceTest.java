package com.aadityadesigners.kms;

import com.aadityadesigners.kms.service.KmsEncryptionService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration tests for KMS Encryption Service
 *
 * IMPORTANT: These tests require:
 * 1. Valid AWS credentials
 * 2. KMS_KEY_ARN environment variable set
 * 3. Network access to AWS KMS
 *
 * Run with: ./gradlew test
 */
@SpringBootTest
@ActiveProfiles("test")
class KmsEncryptionServiceTest {

    @Autowired
    private KmsEncryptionService encryptionService;

    @Test
    void shouldEncryptAndDecryptString() {
        // Given
        String original = "Hello, KMS!";

        // When
        byte[] encrypted = encryptionService.encrypt(original);
        String decrypted = encryptionService.decrypt(encrypted);

        // Then
        assertEquals(original, decrypted);
        assertNotEquals(original.getBytes().length, encrypted.length);
    }

    @Test
    void shouldEncryptAndDecryptWithContext() {
        // Given
        String original = "Sensitive data";
        Map<String, String> context = Map.of(
                "purpose", "test",
                "version", "1"
        );

        // When
        byte[] encrypted = encryptionService.encrypt(original, context);
        String decrypted = encryptionService.decrypt(encrypted, context);

        // Then
        assertEquals(original, decrypted);
    }

    @Test
    void shouldFailDecryptionWithWrongContext() {
        // Given
        String original = "Tenant data";
        byte[] encrypted = encryptionService.encryptForTenant(original, "tenant-A");

        // When/Then - Should fail with wrong tenant
        assertThrows(RuntimeException.class, () -> {
            encryptionService.decryptForTenant(encrypted, "tenant-B");
        });
    }

    @Test
    void shouldHandleEmptyString() {
        // Given
        String original = "";

        // When
        byte[] encrypted = encryptionService.encrypt(original);
        String decrypted = encryptionService.decrypt(encrypted);

        // Then
        assertEquals(original, decrypted);
    }

    @Test
    void shouldHandleLargeData() {
        // Given - 1MB of data
        String original = "A".repeat(1024 * 1024);

        // When
        byte[] encrypted = encryptionService.encrypt(original);
        String decrypted = encryptionService.decrypt(encrypted);

        // Then
        assertEquals(original, decrypted);
    }

    @Test
    void shouldHandleUnicodeData() {
        // Given
        String original = "Hello 世界! 🔐 Привет мир!";

        // When
        byte[] encrypted = encryptionService.encrypt(original);
        String decrypted = encryptionService.decrypt(encrypted);

        // Then
        assertEquals(original, decrypted);
    }
}

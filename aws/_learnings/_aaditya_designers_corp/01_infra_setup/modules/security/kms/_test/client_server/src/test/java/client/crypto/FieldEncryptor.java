package client.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Field Encryptor - Encrypts individual fields using AES-256-GCM.
 *
 * <h2>STEP 4 (CLIENT): Encrypt PII Fields</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  FIELD ENCRYPTION                                                      │
 * │                                                                        │
 * │  Input: plainText, dataEncryptionKey (DEK)                            │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Generate random 96-bit IV                                         │
 * │  2. Initialize AES-256-GCM cipher with DEK                            │
 * │  3. Encrypt plainText → encryptedText + authTag                       │
 * │                                                                        │
 * │  Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"           │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class FieldEncryptor {

  private static final int IV_SIZE_BYTES = 12;
  private static final int AUTH_TAG_SIZE_BITS = 128;
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Encrypts a plaintext field using AES-256-GCM.
   *
   * @param plainText         The sensitive data to encrypt
   * @param dataEncryptionKey The DEK (Data Encryption Key)
   * @return Encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   */
  public String encrypt(String plainText, SecretKey dataEncryptionKey) {
    try {
      // Generate random IV and encrypt
      byte[] iv = new byte[IV_SIZE_BYTES];
      SECURE_RANDOM.nextBytes(iv);

      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.ENCRYPT_MODE, dataEncryptionKey, gcmSpec);
      byte[] encryptedTextWithTag = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

      // Split encryptedText and authTag, then format output
      int tagSizeBytes = AUTH_TAG_SIZE_BITS / 8;
      int encryptedTextLength = encryptedTextWithTag.length - tagSizeBytes;
      byte[] encryptedText = new byte[encryptedTextLength];
      byte[] authTag = new byte[tagSizeBytes];
      System.arraycopy(encryptedTextWithTag, 0, encryptedText, 0, encryptedTextLength);
      System.arraycopy(encryptedTextWithTag, encryptedTextLength, authTag, 0, tagSizeBytes);

      return Base64.getEncoder().encodeToString(iv) + "." +
             Base64.getEncoder().encodeToString(encryptedText) + "." +
             Base64.getEncoder().encodeToString(authTag);

    } catch (Exception e) {
      throw new RuntimeException("Failed to encrypt field", e);
    }
  }
}

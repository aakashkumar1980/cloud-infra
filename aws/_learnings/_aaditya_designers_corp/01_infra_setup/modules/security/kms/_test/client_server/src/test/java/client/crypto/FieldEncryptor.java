package client.crypto;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
 * <h2>STEP 2 & 4 (CLIENT): Generate DEK and Encrypt PII Fields</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  CLIENT ENCRYPTION FLOW                                                │
 * │                                                                        │
 * │  STEP 2: generateAESEncryptionKey()                             │
 * │  ► KeyGenerator.getInstance("AES"), keyGen.init(256, SecureRandom)    │
 * │  ► Output: 256-bit AES SecretKey                                      │
 * │                                                                        │
 * │  STEP 4: encrypt(plainText, randomAESEncryptionKey)                   │
 * │  ► For each PII field (DOB, Credit Card, SSN):                        │
 * │    1. Generate random 96-bit IV                                       │
 * │    2. Initialize AES-256-GCM cipher                                   │
 * │    3. Encrypt plainText → encryptedText + authTag                     │
 * │    4. Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"      │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class FieldEncryptor {

  private static final Logger log = LoggerFactory.getLogger(FieldEncryptor.class);

  private static final int IV_SIZE_BYTES = 12;
  private static final int AUTH_TAG_SIZE_BITS = 128;
  private static final SecureRandom SECURE_RANDOM = new SecureRandom();

  /**
   * Encrypts a plaintext field using AES-256-GCM.
   *
   * @param plainText              The sensitive data to encrypt
   * @param randomAESEncryptionKey The AES secret key
   * @return Encrypted string in format: BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)
   */
  public String encrypt(String plainText, SecretKey randomAESEncryptionKey) {
    log.debug("[CLIENT STEP 4] Encrypting field (plaintext length: {} chars)", plainText.length());

    try {
      // STEP 1: Generate random IV and encrypt
      byte[] iv = new byte[IV_SIZE_BYTES];
      SECURE_RANDOM.nextBytes(iv);

      log.debug("[CLIENT STEP 4] AES Key - Algorithm: {} | Size: {} bytes",
          randomAESEncryptionKey.getAlgorithm(), randomAESEncryptionKey.getEncoded().length);

      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      GCMParameterSpec gcmSpec = new GCMParameterSpec(AUTH_TAG_SIZE_BITS, iv);
      cipher.init(Cipher.ENCRYPT_MODE, randomAESEncryptionKey, gcmSpec);
      byte[] encryptedTextWithTag = cipher.doFinal(plainText.getBytes(StandardCharsets.UTF_8));

      // STEP 2: Split encryptedText and authTag, then format output
      int tagSizeBytes = AUTH_TAG_SIZE_BITS / 8;
      int encryptedTextLength = encryptedTextWithTag.length - tagSizeBytes;
      byte[] encryptedText = new byte[encryptedTextLength];
      byte[] authTag = new byte[tagSizeBytes];
      System.arraycopy(encryptedTextWithTag, 0, encryptedText, 0, encryptedTextLength);
      System.arraycopy(encryptedTextWithTag, encryptedTextLength, authTag, 0, tagSizeBytes);

      String ivB64 = Base64.getEncoder().encodeToString(iv);
      String cipherB64 = Base64.getEncoder().encodeToString(encryptedText);
      String tagB64 = Base64.getEncoder().encodeToString(authTag);

      log.debug("[CLIENT STEP 4] Encrypted sizes - IV: {} bytes | Ciphertext: {} bytes | AuthTag: {} bytes",
          iv.length, encryptedText.length, authTag.length);
      log.debug("[CLIENT STEP 4] Parts - IV(b64): {} | Ciphertext(b64): {} | AuthTag(b64): {}",
          ivB64, cipherB64, tagB64);

      return ivB64 + "." + cipherB64 + "." + tagB64;

    } catch (Exception e) {
      log.error("[CLIENT STEP 4] Encryption failed: {}", e.getMessage());
      throw new RuntimeException("Failed to encrypt field", e);
    }
  }
}

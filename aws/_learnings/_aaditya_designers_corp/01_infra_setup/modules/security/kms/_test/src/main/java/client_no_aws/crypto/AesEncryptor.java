package client_no_aws.crypto;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * AES-GCM Encryption
 *
 * Uses standard Java crypto (NO AWS SDK).
 * Generates a random DEK (Data Encryption Key) and encrypts data with it.
 */
public class AesEncryptor {

    private static final Logger log = LoggerFactory.getLogger(AesEncryptor.class);

    private static final int AES_KEY_SIZE = 256;
    private static final int GCM_IV_LENGTH = 12;  // 96 bits recommended for GCM
    private static final int GCM_TAG_LENGTH = 128; // bits

    /**
     * Result of AES-GCM encryption
     */
    public record EncryptionResult(
            byte[] dek,           // Data Encryption Key (to be encrypted with RSA)
            byte[] encryptedData, // Encrypted data (without auth tag)
            byte[] iv,            // Initialization Vector
            byte[] authTag        // Authentication Tag
    ) {
        public String dekBase64() { return Base64.getEncoder().encodeToString(dek); }
        public String encryptedDataBase64() { return Base64.getEncoder().encodeToString(encryptedData); }
        public String ivBase64() { return Base64.getEncoder().encodeToString(iv); }
        public String authTagBase64() { return Base64.getEncoder().encodeToString(authTag); }
    }

    /**
     * Generate a random 256-bit AES key (DEK)
     */
    public byte[] generateDek() throws Exception {
        KeyGenerator keyGen = KeyGenerator.getInstance("AES");
        keyGen.init(AES_KEY_SIZE, new SecureRandom());
        SecretKey key = keyGen.generateKey();
        log.debug("Generated random DEK: {} bits", AES_KEY_SIZE);
        return key.getEncoded();
    }

    /**
     * Encrypt data using AES-GCM
     *
     * @param plaintext Data to encrypt
     * @param dek       Data Encryption Key (256-bit)
     * @return EncryptionResult containing encrypted data, IV, and auth tag
     */
    public EncryptionResult encrypt(String plaintext, byte[] dek) throws Exception {
        log.debug("Encrypting {} bytes of data with AES-GCM", plaintext.length());

        // Generate random IV
        byte[] iv = new byte[GCM_IV_LENGTH];
        new SecureRandom().nextBytes(iv);

        // Initialize cipher
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
        SecretKey secretKey = new javax.crypto.spec.SecretKeySpec(dek, "AES");
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, spec);

        // Encrypt
        byte[] cipherTextWithTag = cipher.doFinal(plaintext.getBytes("UTF-8"));

        // GCM appends auth tag to ciphertext, split them
        int tagLengthBytes = GCM_TAG_LENGTH / 8;
        byte[] encryptedData = new byte[cipherTextWithTag.length - tagLengthBytes];
        byte[] authTag = new byte[tagLengthBytes];

        System.arraycopy(cipherTextWithTag, 0, encryptedData, 0, encryptedData.length);
        System.arraycopy(cipherTextWithTag, encryptedData.length, authTag, 0, tagLengthBytes);

        log.debug("Encryption complete. Ciphertext: {} bytes, IV: {} bytes, AuthTag: {} bytes",
                encryptedData.length, iv.length, authTag.length);

        return new EncryptionResult(dek, encryptedData, iv, authTag);
    }
}

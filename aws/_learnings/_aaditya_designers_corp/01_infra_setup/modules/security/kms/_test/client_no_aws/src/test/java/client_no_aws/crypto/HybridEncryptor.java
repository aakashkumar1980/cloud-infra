package client_no_aws.crypto;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSAEncrypter;
import com.nimbusds.jose.jwk.RSAKey;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * Hybrid Encryptor (Test Helper)
 *
 * Uses standard Java crypto + Nimbus JOSE (NO AWS SDK).
 * Implements hybrid encryption for efficient PII field encryption.
 *
 * Flow:
 * 1. Generate random DEK (AES-256 key)
 * 2. Encrypt each PII field with DEK using AES-256-GCM
 * 3. Wrap DEK in JWE using company's RSA public key
 * 4. Return JWE (for header) and encrypted fields (for body)
 *
 * This approach:
 * - Uses RSA only once (to wrap DEK) - efficient
 * - Uses AES-GCM for data (fast, small output)
 * - Matches KMS algorithm: RSA-OAEP-256 for key wrapping
 */
public class HybridEncryptor {

  private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";
  private static final int AES_KEY_SIZE = 256;
  private static final int GCM_IV_SIZE = 12;  // 96 bits
  private static final int GCM_TAG_SIZE = 128; // bits

  private RSAPublicKey publicKey;
  private SecretKey dek;

  /**
   * Load RSA public key from PEM file in resources
   */
  public void loadPublicKeyFromResources() throws Exception {
    try (InputStream is = getClass().getResourceAsStream(PUBLIC_KEY_RESOURCE)) {
      if (is == null) {
        throw new IOException("Public key file not found: " + PUBLIC_KEY_RESOURCE);
      }
      String pemKey = new String(is.readAllBytes(), StandardCharsets.UTF_8);
      loadPublicKey(pemKey);
    }
  }

  /**
   * Load RSA public key from PEM string
   */
  public void loadPublicKey(String pemKey) throws Exception {
    String base64Key = pemKey
        .replace("-----BEGIN PUBLIC KEY-----", "")
        .replace("-----END PUBLIC KEY-----", "")
        .replaceAll("\\s", "");

    byte[] keyBytes = Base64.getDecoder().decode(base64Key);
    X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
    KeyFactory keyFactory = KeyFactory.getInstance("RSA");
    PublicKey key = keyFactory.generatePublic(spec);

    if (!(key instanceof RSAPublicKey)) {
      throw new IllegalArgumentException("Key is not an RSA public key");
    }
    this.publicKey = (RSAPublicKey) key;
  }

  /**
   * Generate a new random DEK (AES-256 key)
   * Call this once per request, then use the DEK to encrypt all fields
   */
  public void generateDek() throws Exception {
    KeyGenerator keyGen = KeyGenerator.getInstance("AES");
    keyGen.init(AES_KEY_SIZE, new SecureRandom());
    this.dek = keyGen.generateKey();
  }

  /**
   * Create JWE containing the encrypted DEK
   * This goes in the X-Encryption-Key header
   *
   * @return JWE compact serialization string
   */
  public String createJweWithDek() throws Exception {
    if (publicKey == null) {
      throw new IllegalStateException("Public key not loaded");
    }
    if (dek == null) {
      throw new IllegalStateException("DEK not generated. Call generateDek() first");
    }

    // Build JWE header
    JWEHeader header = new JWEHeader.Builder(JWEAlgorithm.RSA_OAEP_256, EncryptionMethod.A256GCM)
        .contentType("JWT")
        .build();

    // Create JWE with DEK as payload
    // Note: We're using the DEK bytes directly as the "content"
    // The Nimbus library will generate its own CEK, but we override by directly encrypting our DEK
    JWEObject jweObject = new JWEObject(header, new Payload(dek.getEncoded()));

    // Encrypt with RSA public key
    RSAEncrypter encrypter = new RSAEncrypter(publicKey);
    jweObject.encrypt(encrypter);

    return jweObject.serialize();
  }

  /**
   * Encrypt a field using AES-256-GCM with the current DEK
   *
   * @param plaintext The plaintext to encrypt
   * @return Encrypted field in format: BASE64(IV).BASE64(Ciphertext).BASE64(AuthTag)
   */
  public String encryptField(String plaintext) throws Exception {
    if (dek == null) {
      throw new IllegalStateException("DEK not generated. Call generateDek() first");
    }

    // Generate random IV
    byte[] iv = new byte[GCM_IV_SIZE];
    new SecureRandom().nextBytes(iv);

    // Encrypt with AES-GCM
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_SIZE, iv);
    cipher.init(Cipher.ENCRYPT_MODE, dek, gcmSpec);

    byte[] ciphertextWithTag = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));

    // Split ciphertext and auth tag (GCM appends 16-byte tag)
    int tagSizeBytes = GCM_TAG_SIZE / 8;
    byte[] ciphertext = new byte[ciphertextWithTag.length - tagSizeBytes];
    byte[] authTag = new byte[tagSizeBytes];
    System.arraycopy(ciphertextWithTag, 0, ciphertext, 0, ciphertext.length);
    System.arraycopy(ciphertextWithTag, ciphertext.length, authTag, 0, tagSizeBytes);

    // Format: IV.Ciphertext.AuthTag (all Base64 encoded)
    return Base64.getEncoder().encodeToString(iv) + "." +
           Base64.getEncoder().encodeToString(ciphertext) + "." +
           Base64.getEncoder().encodeToString(authTag);
  }
}

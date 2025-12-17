package server.restapi_data_security.crypto;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.kms.KmsClient;
import software.amazon.awssdk.services.kms.model.DecryptRequest;
import software.amazon.awssdk.services.kms.model.DecryptResponse;
import software.amazon.awssdk.services.kms.model.EncryptionAlgorithmSpec;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/**
 * AES Encryption Key Unwrapper - Unwraps the AES encryption key using AWS KMS.
 *
 * <h2>STEP 6 (BACKEND): Two-Step AES Key Unwrapping via AWS KMS</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  AES KEY UNWRAPPING VIA KMS (Two-Step Process)                         │
 * │                                                                        │
 * │  STEP 6a: Decrypt CEK via KMS                                         │
 * │  ─────────────────────────────────────────────────────────────────────│
 * │  SERVER                               AWS KMS                          │
 * │    │                                    │                              │
 * │    │ ─── DecryptRequest ──────────────► │                              │
 * │    │     (encryptedCEK, keyArn,         │                              │
 * │    │      RSAES_OAEP_SHA_256)           │                              │
 * │    │                                    │  ┌────────────────────────┐  │
 * │    │                                    │  │ RSA Private Key        │  │
 * │    │                                    │  │ (NEVER leaves HSM)     │  │
 * │    │                                    │  └────────────────────────┘  │
 * │    │ ◄── DecryptResponse ────────────── │                              │
 * │    │     (plaintext CEK: 256-bit)       │                              │
 * │                                                                        │
 * │  STEP 6b: Decrypt JWE Payload Locally                                 │
 * │  ─────────────────────────────────────────────────────────────────────│
 * │  Using the decrypted CEK + IV + AuthTag from JWE:                     │
 * │    ► Decrypt JWE ciphertext using AES-256-GCM                         │
 * │    ► Output: Original AES encryption key (for field decryption)       │
 * │                                                                        │
 * │  NOTE: This is the ONLY KMS API call per request!                     │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Two Steps?</h3>
 * <p>JWE uses a two-layer encryption scheme:</p>
 * <ol>
 *   <li>A random CEK (Content Encryption Key) is RSA-encrypted</li>
 *   <li>The payload (our AES key) is encrypted with CEK using A256GCM</li>
 * </ol>
 * <p>We must decrypt both layers to retrieve the original AES key.</p>
 */
@Component
public class AwsKmsDecryptionService {

  private static final Logger log = LoggerFactory.getLogger(AwsKmsDecryptionService.class);
  private static final int GCM_TAG_SIZE_BITS = 128;

  private final KmsClient kmsClient;
  private final String keyArn;

  /**
   * Creates a new AES Encryption Key Unwrapper.
   *
   * @param kmsClient The AWS KMS client (injected by Spring)
   * @param keyArn    The ARN of the asymmetric KMS key (from application.yml)
   */
  public AwsKmsDecryptionService(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String keyArn
  ) {
    this.kmsClient = kmsClient;
    this.keyArn = keyArn;
  }

  /**
   * Unwraps an AES key from JWE components using AWS KMS.
   *
   * <p>This method performs two-step decryption:</p>
   * <ol>
   *   <li>Decrypt the CEK (Content Encryption Key) using KMS</li>
   *   <li>Use the CEK to decrypt the JWE payload (original AES key)</li>
   * </ol>
   *
   * @param jweComponents The JWE components from JwtParser
   * @return The unwrapped AES-256 secret key
   * @throws RuntimeException if decryption fails
   */
  public SecretKey decryptAESKeyFromJweComponents(JwtParser.JweComponents jweComponents) {
    log.info("=== DEBUG: AwsKmsDecryptionService.decryptAESKeyFromJweComponents ===");
    log.info("DEBUG: Input - encrypted CEK size: {} bytes", jweComponents.encryptedCek().length);

    try {
      // STEP 6a: Decrypt CEK via KMS
      log.info("DEBUG: Step 6a - Calling KMS to decrypt CEK...");
      byte[] cek = decryptCekViaKms(jweComponents.encryptedCek());
      log.info("DEBUG: Step 6a - CEK decrypted successfully:");
      log.info("DEBUG:   CEK size: {} bytes", cek.length);
      log.info("DEBUG:   CEK base64: {}", java.util.Base64.getEncoder().encodeToString(cek));

      // STEP 6b: Decrypt JWE payload using CEK to get original AES key
      log.info("DEBUG: Step 6b - Decrypting JWE payload with CEK...");
      log.info("DEBUG:   Using IV size: {} bytes", jweComponents.iv().length);
      log.info("DEBUG:   Using ciphertext size: {} bytes", jweComponents.ciphertext().length);
      log.info("DEBUG:   Using authTag size: {} bytes", jweComponents.authTag().length);

      byte[] aesKeyBytes = decryptJwePayload(cek, jweComponents.iv(),
          jweComponents.ciphertext(), jweComponents.authTag());
      log.info("DEBUG: Step 6b - AES key extracted successfully:");
      log.info("DEBUG:   AES key size: {} bytes", aesKeyBytes.length);
      log.info("DEBUG:   AES key base64: {}", java.util.Base64.getEncoder().encodeToString(aesKeyBytes));

      return new SecretKeySpec(aesKeyBytes, "AES");

    } catch (Exception e) {
      log.error("DEBUG: FAILED to unwrap AES key: {}", e.getMessage(), e);
      throw new RuntimeException("AES key unwrap failed: " + e.getMessage(), e);
    }
  }

  /**
   * Decrypts the CEK using AWS KMS RSA decryption.
   */
  private byte[] decryptCekViaKms(byte[] encryptedCek) {
    DecryptRequest request = DecryptRequest.builder()
        .keyId(keyArn)
        .ciphertextBlob(SdkBytes.fromByteArray(encryptedCek))
        .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
        .build();

    DecryptResponse response = kmsClient.decrypt(request);
    return response.plaintext().asByteArray();
  }

  /**
   * Decrypts the JWE payload using the CEK.
   *
   * <p>Note: A256GCM in JWE places the auth tag at the end of ciphertext
   * for the Cipher.doFinal() call.</p>
   */
  private byte[] decryptJwePayload(byte[] cek, byte[] iv, byte[] ciphertext, byte[] authTag)
      throws Exception {
    // Combine ciphertext and authTag (GCM expects them together)
    byte[] ciphertextWithTag = new byte[ciphertext.length + authTag.length];
    System.arraycopy(ciphertext, 0, ciphertextWithTag, 0, ciphertext.length);
    System.arraycopy(authTag, 0, ciphertextWithTag, ciphertext.length, authTag.length);

    // Decrypt using AES-256-GCM
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    SecretKey cekKey = new SecretKeySpec(cek, "AES");
    GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_SIZE_BITS, iv);
    cipher.init(Cipher.DECRYPT_MODE, cekKey, gcmSpec);

    return cipher.doFinal(ciphertextWithTag);
  }
}

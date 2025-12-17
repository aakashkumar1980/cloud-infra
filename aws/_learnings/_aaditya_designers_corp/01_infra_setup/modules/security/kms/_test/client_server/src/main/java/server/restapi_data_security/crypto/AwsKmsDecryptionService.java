package server.restapi_data_security.crypto;

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
 * AWS KMS Decryption Service - Decrypts the AES CEK (Content Encryption Key) using AWS KMS.
 *
 * <h2>STEP 6 (BACKEND): Two-Step AES CEK Decryption via AWS KMS</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  AES CEK DECRYPTION VIA KMS (Two-Step Process)                        │
 * │                                                                        │
 * │  STEP 6a: Decrypt aesCekEncryptedKey via KMS                          │
 * │  ─────────────────────────────────────────────────────────────────────│
 * │  SERVER                               AWS KMS                          │
 * │    │                                    │                              │
 * │    │ ─── DecryptRequest ──────────────► │                              │
 * │    │     (aesCekEncryptedKey, keyArn,   │                              │
 * │    │      RSAES_OAEP_SHA_256)           │                              │
 * │    │                                    │  ┌────────────────────────┐  │
 * │    │                                    │  │ RSA Private Key        │  │
 * │    │                                    │  │ (NEVER leaves HSM)     │  │
 * │    │                                    │  └────────────────────────┘  │
 * │    │ ◄── DecryptResponse ────────────── │                              │
 * │    │     (aesCekEncryptionKey: 256-bit) │                              │
 * │                                                                        │
 * │  STEP 6b: Decrypt JWE Payload Locally                                 │
 * │  ─────────────────────────────────────────────────────────────────────│
 * │  Using the aesCekEncryptionKey + IV + AuthTag from JWE:               │
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
 *   <li>A random AES CEK is RSA-encrypted → aesCekEncryptedKey</li>
 *   <li>The payload (our AES key) is encrypted with aesCekEncryptionKey using A256GCM</li>
 * </ol>
 * <p>We must decrypt both layers to retrieve the original AES key.</p>
 */
@Component
public class AwsKmsDecryptionService {

  private static final int GCM_TAG_SIZE_BITS = 128;

  private final KmsClient kmsClient;
  private final String keyArn;

  /**
   * Creates a new AWS KMS Decryption Service.
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
   * Decrypts the AES CEK from JWE components using AWS KMS and extracts the original AES key.
   *
   * <p>This method performs two-step decryption:</p>
   * <ol>
   *   <li>Decrypt the aesCekEncryptedKey using KMS → aesCekEncryptionKey</li>
   *   <li>Use the aesCekEncryptionKey to decrypt the JWE payload (original AES key)</li>
   * </ol>
   *
   * @param jweComponents The JWE components from JwtParser
   * @return The decrypted AES-256 secret key for field decryption
   * @throws RuntimeException if decryption fails
   */
  public SecretKey decryptAesCekAndExtractAesKey(JwtParser.JweComponents jweComponents) {
    try {
      // STEP 6a: Decrypt aesCekEncryptedKey via KMS to get aesCekEncryptionKey
      byte[] aesCekEncryptionKey = decryptAesCekViaKms(jweComponents.aesCekEncryptedKey());

      // STEP 6b: Decrypt JWE payload using aesCekEncryptionKey to get original AES key
      byte[] aesKeyBytes = decryptJwePayload(
          aesCekEncryptionKey,
          jweComponents.iv(),
          jweComponents.ciphertext(),
          jweComponents.authTag(),
          jweComponents.aad()
      );

      return new SecretKeySpec(aesKeyBytes, "AES");

    } catch (Exception e) {
      throw new RuntimeException("AES CEK decryption failed: " + e.getMessage(), e);
    }
  }

  /**
   * Decrypts the aesCekEncryptedKey using AWS KMS RSA decryption.
   *
   * @param aesCekEncryptedKey The RSA-encrypted AES CEK
   * @return The decrypted aesCekEncryptionKey (plaintext CEK bytes)
   */
  private byte[] decryptAesCekViaKms(byte[] aesCekEncryptedKey) {
    DecryptRequest request = DecryptRequest.builder()
        .keyId(keyArn)
        .ciphertextBlob(SdkBytes.fromByteArray(aesCekEncryptedKey))
        .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
        .build();

    DecryptResponse response = kmsClient.decrypt(request);
    return response.plaintext().asByteArray();
  }

  /**
   * Decrypts the JWE payload using the aesCekEncryptionKey.
   *
   * <p>JWE uses AAD (Additional Authenticated Data) which is the ASCII bytes
   * of the Base64URL-encoded protected header. This must be provided to the
   * cipher for GCM authentication to succeed.</p>
   *
   * @param aesCekEncryptionKey The decrypted AES CEK (Content Encryption Key)
   * @param iv                  The initialization vector for A256GCM
   * @param ciphertext          The encrypted payload
   * @param authTag             The GCM authentication tag
   * @param aad                 The Additional Authenticated Data
   * @return The decrypted payload (original AES key bytes)
   */
  private byte[] decryptJwePayload(byte[] aesCekEncryptionKey, byte[] iv, byte[] ciphertext, byte[] authTag, byte[] aad)
      throws Exception {
    // Combine ciphertext and authTag (GCM expects them together)
    byte[] ciphertextWithTag = new byte[ciphertext.length + authTag.length];
    System.arraycopy(ciphertext, 0, ciphertextWithTag, 0, ciphertext.length);
    System.arraycopy(authTag, 0, ciphertextWithTag, ciphertext.length, authTag.length);

    // Decrypt using AES-256-GCM with AAD
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    SecretKey cekKey = new SecretKeySpec(aesCekEncryptionKey, "AES");
    GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_SIZE_BITS, iv);
    cipher.init(Cipher.DECRYPT_MODE, cekKey, gcmSpec);

    // CRITICAL: Must provide AAD before decryption for GCM authentication
    cipher.updateAAD(aad);

    return cipher.doFinal(ciphertextWithTag);
  }
}

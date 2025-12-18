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
 * AWS KMS Decryption Service - Extracts the Data Encryption Key (DEK) from JWE via KMS.
 *
 * <h2>STEP 6 (BACKEND): Extract DEK via AWS KMS</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  DEK EXTRACTION (Two-Step Process)                                    │
 * │                                                                        │
 * │  STEP 6a: Decrypt CEK via KMS                                         │
 * │  ─────────────────────────────────────────────────────────────────────│
 * │  SERVER                               AWS KMS                          │
 * │    │                                    │                              │
 * │    │ ─── DecryptRequest ──────────────► │                              │
 * │    │     (encryptedCek, keyArn,         │                              │
 * │    │      RSAES_OAEP_SHA_256)           │                              │
 * │    │                                    │  ┌────────────────────────┐  │
 * │    │                                    │  │ RSA Private Key        │  │
 * │    │                                    │  │ (NEVER leaves HSM)     │  │
 * │    │                                    │  └────────────────────────┘  │
 * │    │ ◄── DecryptResponse ────────────── │                              │
 * │    │     (cek: 256-bit)                 │                              │
 * │                                                                        │
 * │  STEP 6b: Decrypt JWE Payload Locally                                 │
 * │  ─────────────────────────────────────────────────────────────────────│
 * │  Using cek + IV + AuthTag from JWE:                                   │
 * │    ► Decrypt JWE ciphertext using AES-256-GCM                         │
 * │    ► Output: dataEncryptionKey (DEK for field decryption)             │
 * │                                                                        │
 * │  NOTE: This is the ONLY KMS API call per request!                     │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Two Steps?</h3>
 * <p>JWE uses two-layer encryption:</p>
 * <ol>
 *   <li>CEK (Content Encryption Key) is RSA-encrypted → encryptedCek</li>
 *   <li>DEK (Data Encryption Key) is encrypted with CEK → ciphertext</li>
 * </ol>
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
   * Extracts the Data Encryption Key (DEK) from JWE components via AWS KMS.
   *
   * <p>Two-step process:</p>
   * <ol>
   *   <li>Decrypt encryptedCek via KMS → cek</li>
   *   <li>Decrypt JWE payload using cek → dataEncryptionKey</li>
   * </ol>
   *
   * @param jweComponents The JWE components from JwtParser
   * @return The Data Encryption Key (DEK) for field decryption
   * @throws RuntimeException if decryption fails
   */
  public SecretKey extractDataEncryptionKey(JwtParser.JweComponents jweComponents) {
    try {
      // STEP 6a: Decrypt encryptedCek via KMS to get cek
      byte[] cek = decryptCekViaKms(jweComponents.encryptedCek());

      // STEP 6b: Decrypt JWE payload using cek to get dataEncryptionKey
      byte[] dekBytes = decryptJwePayload(
          cek,
          jweComponents.iv(),
          jweComponents.ciphertext(),
          jweComponents.authTag(),
          jweComponents.aad()
      );

      return new SecretKeySpec(dekBytes, "AES");

    } catch (Exception e) {
      throw new RuntimeException("Failed to extract Data Encryption Key: " + e.getMessage(), e);
    }
  }

  /**
   * Decrypts the encryptedCek using AWS KMS RSA decryption.
   *
   * @param encryptedCek The RSA-encrypted Content Encryption Key
   * @return The plaintext CEK bytes
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
   * Decrypts the JWE payload using the CEK to extract the DEK.
   *
   * <p>JWE uses AAD (Additional Authenticated Data) which is the ASCII bytes
   * of the Base64URL-encoded protected header. This must be provided for GCM
   * authentication to succeed.</p>
   *
   * @param cek        The Content Encryption Key (decrypted via KMS)
   * @param iv         Initialization vector for A256GCM
   * @param ciphertext Encrypted payload containing the DEK
   * @param authTag    GCM authentication tag
   * @param aad        Additional Authenticated Data
   * @return The DEK bytes (Data Encryption Key)
   */
  private byte[] decryptJwePayload(byte[] cek, byte[] iv, byte[] ciphertext, byte[] authTag, byte[] aad)
      throws Exception {
    // Combine ciphertext and authTag (GCM expects them together)
    byte[] ciphertextWithTag = new byte[ciphertext.length + authTag.length];
    System.arraycopy(ciphertext, 0, ciphertextWithTag, 0, ciphertext.length);
    System.arraycopy(authTag, 0, ciphertextWithTag, ciphertext.length, authTag.length);

    // Decrypt using AES-256-GCM with AAD
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    SecretKey cekKey = new SecretKeySpec(cek, "AES");
    GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_SIZE_BITS, iv);
    cipher.init(Cipher.DECRYPT_MODE, cekKey, gcmSpec);

    // CRITICAL: Must provide AAD before decryption for GCM authentication
    cipher.updateAAD(aad);

    return cipher.doFinal(ciphertextWithTag);
  }
}

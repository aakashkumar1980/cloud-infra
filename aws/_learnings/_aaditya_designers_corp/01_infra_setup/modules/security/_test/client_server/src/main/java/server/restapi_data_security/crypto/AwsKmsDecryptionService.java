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
 * AWS KMS Decryption Service - Extracts the AES Data Encryption Key (DEK) from JWE via KMS.
 *
 * <h2>STEP 6 (SERVER): Extract DEK via AWS KMS</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  DEK EXTRACTION                                                        │
 * │                                                                        │
 * │  Input: JweComponents from Step 5                                      │
 * │                                                                        │
 * │  Two-Step Process:                                                     │
 * │  Step 6a: DECRYPT-RSA via AWS KMS                                      │
 * │    ► encryptedCek → (KMS RSA decrypt) → cek                           │
 * │                                                                        │
 * │  Step 6b: DECRYPT-AES locally                                          │
 * │    ► encryptedAesDataEncryptionKey → (AES-GCM decrypt) → DEK          │
 * │                                                                        │
 * │  Output: aesDataEncryptionKey (DEK for field decryption)               │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Two Steps?</h3>
 * <p>JWE uses two-layer encryption:</p>
 * <ol>
 *   <li>CEK (Content Encryption Key) is RSA-encrypted → encryptedCek</li>
 *   <li>AES DEK (Data Encryption Key) is encrypted with CEK → encryptedAesDataEncryptionKey</li>
 * </ol>
 *
 * <h3>Security:</h3>
 * <ul>
 *   <li>RSA private key <b>never leaves AWS KMS HSM</b></li>
 *   <li>This is the <b>ONLY KMS API call</b> per request</li>
 *   <li>CEK decryption happens inside KMS hardware</li>
 * </ul>
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
   * Extracts the AES Data Encryption Key (DEK) from JWE components via AWS KMS.
   *
   * <h3>Internal Steps:</h3>
   * <pre>
   * ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   * │  INPUT                                                                                      │
   * │  └── JweComponents: encryptedCek, iv, encryptedAesDataEncryptionKey, authTag, aad          │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 6a: DECRYPT-RSA (RSA-OAEP-256 via AWS KMS) - Decrypt CEK                             │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────┐              ┌─────────────────────────────────────────────┐ │
   * │      │    encryptedCek       │              │                                             │ │
   * │      │ (~512 bytes)          │─────────────►│              AWS KMS                        │ │
   * │      └───────────────────────┘              │                                             │ │
   * │                                             │  DecryptRequest:                            │ │
   * │      ┌───────────────────────┐              │    keyId = keyArn                           │ │
   * │      │      keyArn           │─────────────►│    ciphertextBlob = encryptedCek            │ │
   * │      │ (KMS key reference)   │              │    algorithm = RSAES_OAEP_SHA_256           │ │
   * │      └───────────────────────┘              │                                             │ │
   * │                                             │  ┌─────────────────────────────────────┐    │ │
   * │                                             │  │ RSA Private Key (NEVER leaves HSM) │    │ │
   * │                                             │  └─────────────────────────────────────┘    │ │
   * │                                             │                                             │ │
   * │                                             └──────────────────────┬──────────────────────┘ │
   * │                                                                    │                        │
   * │                                                                    ▼                        │
   * │                                             ┌─────────────────────────────────────────────┐ │
   * │                                             │ cek = 32 bytes (Content Encryption Key)    │ │
   * │                                             └─────────────────────────────────────────────┘ │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 6b: DECRYPT-AES (AES-256-GCM locally) - Decrypt DEK using CEK                        │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌─────────────────────────────────┐                                                    │
   * │      │ encryptedAesDataEncryptionKey   │────┐                                               │
   * │      │ (32 bytes)                      │    │                                               │
   * │      └─────────────────────────────────┘    │  ┌─────────────────────────────────────────┐  │
   * │                                             │  │                                         │  │
   * │      ┌───────────────────────┐              │  │          AES-256-GCM DECRYPT            │  │
   * │      │        cek            │──────────────┼─►│                                         │  │
   * │      │ (32 bytes)            │              │  │  Cipher cipher = Cipher.getInstance(    │  │
   * │      └───────────────────────┘              │  │      "AES/GCM/NoPadding");              │  │
   * │                                             │  │  cipher.init(DECRYPT_MODE, cek, iv);    │  │
   * │      ┌───────────────────────┐              │  │  cipher.updateAAD(aad);  // CRITICAL!   │  │
   * │      │         iv            │──────────────┼─►│  result = cipher.doFinal(               │  │
   * │      │ (12 bytes)            │              │  │      encryptedAesDEK + authTag);        │  │
   * │      └───────────────────────┘              │  │                                         │  │
   * │                                             │  └──────────────────────┬──────────────────┘  │
   * │      ┌───────────────────────┐              │                         │                     │
   * │      │       authTag         │──────────────┤                         │                     │
   * │      │ (16 bytes)            │              │                         │                     │
   * │      └───────────────────────┘              │                         │                     │
   * │                                             │                         │                     │
   * │      ┌───────────────────────┐              │                         │                     │
   * │      │    aad (header)       │──────────────┘                         │                     │
   * │      └───────────────────────┘                                        │                     │
   * │                                                                       ▼                     │
   * │                                             ┌─────────────────────────────────────────────┐ │
   * │                                             │ aesDataEncryptionKey (DEK) = 32 bytes       │ │
   * │                                             │ (used for field decryption in Step 7)       │ │
   * │                                             └─────────────────────────────────────────────┘ │
   * │                                                                                             │
   * │  OUTPUT                                                                                     │
   * │  └── SecretKey (aesDataEncryptionKey) - 256-bit AES key for field decryption              │
   * └─────────────────────────────────────────────────────────────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────┬─────────────────┬─────────────────────────────────────────┬───────────────────────────────┐
   * │ Operation      │ Algorithm       │ Input                                   │ Output                        │
   * ├────────────────┼─────────────────┼─────────────────────────────────────────┼───────────────────────────────┤
   * │ DECRYPT-RSA    │ RSA-OAEP-256    │ encryptedCek, keyArn (via AWS KMS)      │ cek (Content Encryption Key)  │
   * ├────────────────┼─────────────────┼─────────────────────────────────────────┼───────────────────────────────┤
   * │ DECRYPT-AES    │ AES-256-GCM     │ cek, iv, encryptedAesDataEncryptionKey, │ aesDataEncryptionKey (DEK)    │
   * │                │                 │ authTag, aad                            │                               │
   * └────────────────┴─────────────────┴─────────────────────────────────────────┴───────────────────────────────┘
   * </pre>
   *
   * <p><b>NOTE:</b> This is the ONLY KMS API call per request!</p>
   *
   * @param jweComponents The JWE components from JweParser
   * @return The AES Data Encryption Key (DEK) for field decryption
   * @throws RuntimeException if decryption fails
   */
  public SecretKey extractAesDataEncryptionKey(JweParser.JweComponents jweComponents) {
    try {
      // STEP 6a: Decrypt encryptedCek via KMS to get cek
      byte[] cek = decryptCekViaKms(jweComponents.encryptedCek());

      // STEP 6b: Decrypt encryptedAesDataEncryptionKey using cek to get aesDataEncryptionKey
      byte[] aesDataEncryptionKeyBytes = decryptJwePayload(
          cek,
          jweComponents.iv(),
          jweComponents.encryptedAesDataEncryptionKey(),
          jweComponents.authTag(),
          jweComponents.aad()
      );

      return new SecretKeySpec(aesDataEncryptionKeyBytes, "AES");

    } catch (Exception e) {
      throw new RuntimeException("Failed to extract AES Data Encryption Key: " + e.getMessage(), e);
    }
  }

  /**
   * Decrypts the encryptedCek using AWS KMS RSA decryption.
   *
   * <h3>DECRYPT-RSA (Step 6a):</h3>
   * <pre>
   * ┌───────────────────────┐              ┌─────────────────────────────────────────────┐
   * │    encryptedCek       │              │                                             │
   * │ (~512 bytes)          │─────────────►│           AWS KMS RSA-OAEP-256              │
   * └───────────────────────┘              │                                             │
   *                                        │  DecryptRequest:                            │
   * ┌───────────────────────┐              │    keyId = keyArn                           │
   * │      keyArn           │─────────────►│    ciphertextBlob = encryptedCek            │
   * └───────────────────────┘              │    algorithm = RSAES_OAEP_SHA_256           │
   *                                        │                                             │
   *                                        └──────────────────────┬──────────────────────┘
   *                                                               │
   *                                                               ▼
   *                                        ┌─────────────────────────────────────────────┐
   *                                        │ cek = 32 bytes                              │
   *                                        └─────────────────────────────────────────────┘
   * </pre>
   *
   * @param encryptedCek The RSA-encrypted Content Encryption Key
   * @return The plaintext CEK bytes (32 bytes)
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
   * Decrypts the JWE payload using the CEK to extract the AES DEK.
   *
   * <h3>DECRYPT-AES (Step 6b):</h3>
   * <pre>
   * ┌─────────────────────────────────┐
   * │ encryptedAesDataEncryptionKey   │────┐
   * │ (32 bytes)                      │    │
   * └─────────────────────────────────┘    │  ┌─────────────────────────────────────────┐
   *                                        │  │                                         │
   * ┌───────────────────────┐              │  │          AES-256-GCM DECRYPT            │
   * │        cek            │──────────────┼─►│                                         │
   * │ (32 bytes)            │              │  │  Cipher cipher = Cipher.getInstance(    │
   * └───────────────────────┘              │  │      "AES/GCM/NoPadding");              │
   *                                        │  │  cipher.init(DECRYPT_MODE, cek, iv);    │
   * ┌───────────────────────┐              │  │  cipher.updateAAD(aad);  // CRITICAL!   │
   * │         iv            │──────────────┼─►│  result = cipher.doFinal(               │
   * │ (12 bytes)            │              │  │      encryptedAesDEK + authTag);        │
   * └───────────────────────┘              │  │                                         │
   *                                        │  └──────────────────────┬──────────────────┘
   * ┌───────────────────────┐              │                         │
   * │       authTag         │──────────────┤                         │
   * │ (16 bytes)            │              │                         ▼
   * └───────────────────────┘              │  ┌─────────────────────────────────────────┐
   *                                        │  │ aesDataEncryptionKey = 32 bytes         │
   * ┌───────────────────────┐              │  └─────────────────────────────────────────┘
   * │    aad (header)       │──────────────┘
   * └───────────────────────┘
   * </pre>
   *
   * <p>JWE uses AAD (Additional Authenticated Data) which is the ASCII bytes
   * of the Base64URL-encoded protected header. This must be provided for GCM
   * authentication to succeed.</p>
   *
   * @param cek                            The Content Encryption Key (decrypted via KMS)
   * @param iv                             Initialization vector for A256GCM
   * @param encryptedAesDataEncryptionKey  Encrypted payload containing the AES DEK
   * @param authTag                        GCM authentication tag
   * @param aad                            Additional Authenticated Data
   * @return The AES DEK bytes (Data Encryption Key) - 32 bytes
   */
  private byte[] decryptJwePayload(byte[] cek, byte[] iv, byte[] encryptedAesDataEncryptionKey, byte[] authTag, byte[] aad)
      throws Exception {
    // Combine encryptedAesDataEncryptionKey and authTag (GCM expects them together)
    byte[] ciphertextWithTag = new byte[encryptedAesDataEncryptionKey.length + authTag.length];
    System.arraycopy(encryptedAesDataEncryptionKey, 0, ciphertextWithTag, 0, encryptedAesDataEncryptionKey.length);
    System.arraycopy(authTag, 0, ciphertextWithTag, encryptedAesDataEncryptionKey.length, authTag.length);

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

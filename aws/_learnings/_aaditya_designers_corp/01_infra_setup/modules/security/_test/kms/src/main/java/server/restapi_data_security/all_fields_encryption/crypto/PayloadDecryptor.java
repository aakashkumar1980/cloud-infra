package server.restapi_data_security.all_fields_encryption.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
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
import java.nio.charset.StandardCharsets;

/**
 * Payload Decryptor - Decrypts JWE-encrypted payload using AWS KMS.
 *
 * <h2>SERVER STEPS 3-4: Decrypt JWE Payload</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE DECRYPTION (WITH CEK)                                             │
 * │                                                                        │
 * │  Input: JWE string (Header.EncryptedCek.IV.Ciphertext.AuthTag)         │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Parse JWE to extract components                                    │
 * │  2. Decrypt encryptedCek via KMS → contentEncryptionKey (CEK)          │
 * │  3. Decrypt ciphertext with CEK → jsonPayload                          │
 * │                                                                        │
 * │  Output: Original JSON payload string                                  │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Security:</h3>
 * <ul>
 *   <li>RSA private key <b>never leaves AWS KMS HSM</b></li>
 *   <li>1 KMS API call to decrypt encryptedCek</li>
 *   <li>Local AES decryption of payload (fast)</li>
 * </ul>
 */
@Component("allFieldsPayloadDecryptor")
public class PayloadDecryptor {

  private static final int GCM_TAG_SIZE_BITS = 128;

  private final KmsClient kmsClient;
  private final String keyArn;

  public PayloadDecryptor(
      KmsClient kmsClient,
      @Value("${aws.kms.asymmetric-key-arn}") String keyArn
  ) {
    this.kmsClient = kmsClient;
    this.keyArn = keyArn;
  }

  /**
   * Decrypts a JWE string and returns the original JSON payload.
   *
   * <h3>Internal Steps:</h3>
   * <pre>
   * ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   * │  INPUT                                                                                      │
   * │  └── encryptedPayload: Header.EncryptedCek.IV.Ciphertext.AuthTag                                  │
   * │                                                                                             │
   * │  STEP 1: Parse JWE                                                                         │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │  jweObject = JWEObject.parse(encryptedPayload)                                                    │
   * │  Extract: encryptedCek, iv, ciphertext, authTag, aad                                       │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 2: DECRYPT-RSA (via AWS KMS) - Decrypt CEK                                           │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────┐              ┌─────────────────────────────────────────────┐ │
   * │      │    encryptedCek       │              │                                             │ │
   * │      │ (~512 bytes)          │─────────────►│              AWS KMS                        │ │
   * │      └───────────────────────┘              │                                             │ │
   * │                                             │  DecryptRequest:                            │ │
   * │                                             │    keyId = keyArn                           │ │
   * │                                             │    algorithm = RSAES_OAEP_SHA_256           │ │
   * │                                             │                                             │ │
   * │                                             │  ┌─────────────────────────────────────┐    │ │
   * │                                             │  │ RSA Private Key (in HSM)           │    │ │
   * │                                             │  └─────────────────────────────────────┘    │ │
   * │                                             │                                             │ │
   * │                                             └──────────────────────┬──────────────────────┘ │
   * │                                                                    │                        │
   * │                                                                    ▼                        │
   * │                                             ┌─────────────────────────────────────────────┐ │
   * │                                             │ aesContentEncryptionKey (CEK) = 32 bytes    │ │
   * │                                             └─────────────────────────────────────────────┘ │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 3: DECRYPT-AES (locally) - Decrypt payload with CEK                                  │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────┐                                                              │
   * │      │     ciphertext        │────┐                                                         │
   * │      │ (encrypted payload)   │    │                                                         │
   * │      └───────────────────────┘    │        ┌─────────────────────────────────────────────┐  │
   * │                                   │        │                                             │  │
   * │      ┌───────────────────────┐    │        │            AES-256-GCM DECRYPT              │  │
   * │      │ aesContentEncryption  │────┼───────►│                                             │  │
   * │      │ Key (CEK - 32 bytes)  │    │        │  cipher.updateAAD(aad);  // CRITICAL!       │  │
   * │      └───────────────────────┘    │        │  plaintext = cipher.doFinal(...)            │  │
   * │                                   │        │                                             │  │
   * │      ┌───────────────────────┐    │        └──────────────────────┬──────────────────────┘  │
   * │      │    iv + authTag       │────┘                               │                         │
   * │      └───────────────────────┘                                    │                         │
   * │                                                                   ▼                         │
   * │                                             ┌─────────────────────────────────────────────┐ │
   * │                                             │ jsonPayload = {"name":"...", ...}           │ │
   * │                                             └─────────────────────────────────────────────┘ │
   * │                                                                                             │
   * │  OUTPUT                                                                                     │
   * │  └── Original JSON payload string                                                          │
   * └─────────────────────────────────────────────────────────────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────┬─────────────────┬─────────────────────────────────┬───────────────────────────────┐
   * │ Operation      │ Algorithm       │ Input                           │ Output                        │
   * ├────────────────┼─────────────────┼─────────────────────────────────┼───────────────────────────────┤
   * │ DECRYPT-RSA    │ RSA-OAEP-256    │ encryptedCek, keyArn            │ aesContentEncryptionKey (CEK) │
   * │                │ (via AWS KMS)   │                                 │                               │
   * ├────────────────┼─────────────────┼─────────────────────────────────┼───────────────────────────────┤
   * │ DECRYPT-AES    │ AES-256-GCM     │ aesContentEncryptionKey (CEK),  │ jsonPayload                   │
   * │                │                 │ iv, ciphertext, authTag, aad    │                               │
   * └────────────────┴─────────────────┴─────────────────────────────────┴───────────────────────────────┘
   * </pre>
   *
   * @param encryptedPayload The JWE compact serialization string
   * @return The decrypted JSON payload
   */
  public String decrypt(String encryptedPayload) {
    try {
      // Parse JWE
      JWEObject jweObject = JWEObject.parse(encryptedPayload);
      JWEHeader header = jweObject.getHeader();

      // Validate algorithm
      String algorithm = header.getAlgorithm().getName();
      if (!"RSA-OAEP-256".equals(algorithm)) {
        throw new IllegalArgumentException("Unsupported algorithm: " + algorithm);
      }

      // Extract components
      byte[] encryptedContentEncryptionKey = jweObject.getEncryptedKey().decode();
      byte[] iv = jweObject.getIV().decode();
      byte[] encryptedText = jweObject.getCipherText().decode();
      byte[] authTag = jweObject.getAuthTag().decode();

      // AAD = ASCII(BASE64URL(header))
      String protectedHeader = encryptedPayload.split("\\.")[0];
      byte[] aad = protectedHeader.getBytes(StandardCharsets.US_ASCII);

      // STEP 2: Decrypt CEK via KMS
      byte[] contentEncryptedKeyBytes = decryptCekViaKms(encryptedContentEncryptionKey);
      SecretKey contentEncryptionKey = new SecretKeySpec(contentEncryptedKeyBytes, "AES");

      // STEP 3: Decrypt plainText with CEK
      byte[] plainText = decryptText(contentEncryptionKey, encryptedText, iv, authTag, aad);
      return new String(plainText, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt JWE: " + e.getMessage(), e);
    }
  }

  /** Decrypts the encrypted CEK using AWS KMS RSA decryption.
   *
   * @param encryptedCek The encrypted Content Encryption Key
   * @return The decrypted Content Encryption Key bytes
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

  /** Decrypts the ciphertext using AES-GCM with the provided CEK.
   *
   * @param contentEncryptionKey The AES Content Encryption Key
   * @param encryptedText The encrypted payload
   * @param iv The initialization vector
   * @param authTag The authentication tag
   * @param aad The additional authenticated data
   * @return The decrypted plaintext bytes
   * @throws Exception If decryption fails
   */
  private byte[] decryptText(SecretKey contentEncryptionKey, byte[] encryptedText, byte[] iv, byte[] authTag, byte[] aad)
      throws Exception {
    // Combine encryptedText and authTag
    byte[] ciphertextWithTag = new byte[encryptedText.length + authTag.length];
    System.arraycopy(encryptedText, 0, ciphertextWithTag, 0, encryptedText.length);
    System.arraycopy(authTag, 0, ciphertextWithTag, encryptedText.length, authTag.length);

    // Decrypt
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_SIZE_BITS, iv);
    cipher.init(Cipher.DECRYPT_MODE, contentEncryptionKey, gcmSpec);
    cipher.updateAAD(aad);

    return cipher.doFinal(ciphertextWithTag);
  }
}

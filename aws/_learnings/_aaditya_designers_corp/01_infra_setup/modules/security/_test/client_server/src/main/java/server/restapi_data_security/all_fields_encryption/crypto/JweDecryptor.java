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
 * JWE Decryptor - Decrypts JWE payload using AWS KMS.
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
 * │  2. Decrypt encryptedCek via KMS → aesContentEncryptionKey (CEK)       │
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
@Component("allFieldsJweDecryptor")
public class JweDecryptor {

  private static final int GCM_TAG_SIZE_BITS = 128;

  private final KmsClient kmsClient;
  private final String keyArn;

  public JweDecryptor(
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
   * │  └── jweString: Header.EncryptedCek.IV.Ciphertext.AuthTag                                  │
   * │                                                                                             │
   * │  STEP 1: Parse JWE                                                                         │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │  jweObject = JWEObject.parse(jweString)                                                    │
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
   * @param jweString The JWE compact serialization string
   * @return The decrypted JSON payload
   */
  public String decrypt(String jweString) {
    try {
      // Parse JWE
      JWEObject jweObject = JWEObject.parse(jweString);
      JWEHeader header = jweObject.getHeader();

      // Validate algorithm
      String algorithm = header.getAlgorithm().getName();
      if (!"RSA-OAEP-256".equals(algorithm)) {
        throw new IllegalArgumentException("Unsupported algorithm: " + algorithm);
      }

      // Extract components
      byte[] encryptedCek = jweObject.getEncryptedKey().decode();
      byte[] iv = jweObject.getIV().decode();
      byte[] ciphertext = jweObject.getCipherText().decode();
      byte[] authTag = jweObject.getAuthTag().decode();

      // AAD = ASCII(BASE64URL(header))
      String protectedHeader = jweString.split("\\.")[0];
      byte[] aad = protectedHeader.getBytes(StandardCharsets.US_ASCII);

      // STEP 2: Decrypt CEK via KMS
      byte[] cekBytes = decryptCekViaKms(encryptedCek);
      SecretKey aesContentEncryptionKey = new SecretKeySpec(cekBytes, "AES");

      // STEP 3: Decrypt payload with CEK
      byte[] payload = decryptPayload(aesContentEncryptionKey, iv, ciphertext, authTag, aad);

      return new String(payload, StandardCharsets.UTF_8);

    } catch (Exception e) {
      throw new RuntimeException("Failed to decrypt JWE: " + e.getMessage(), e);
    }
  }

  private byte[] decryptCekViaKms(byte[] encryptedCek) {
    DecryptRequest request = DecryptRequest.builder()
        .keyId(keyArn)
        .ciphertextBlob(SdkBytes.fromByteArray(encryptedCek))
        .encryptionAlgorithm(EncryptionAlgorithmSpec.RSAES_OAEP_SHA_256)
        .build();

    DecryptResponse response = kmsClient.decrypt(request);
    return response.plaintext().asByteArray();
  }

  private byte[] decryptPayload(SecretKey aesContentEncryptionKey, byte[] iv, byte[] ciphertext, byte[] authTag, byte[] aad)
      throws Exception {
    // Combine ciphertext and authTag
    byte[] ciphertextWithTag = new byte[ciphertext.length + authTag.length];
    System.arraycopy(ciphertext, 0, ciphertextWithTag, 0, ciphertext.length);
    System.arraycopy(authTag, 0, ciphertextWithTag, ciphertext.length, authTag.length);

    // Decrypt
    Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
    GCMParameterSpec gcmSpec = new GCMParameterSpec(GCM_TAG_SIZE_BITS, iv);
    cipher.init(Cipher.DECRYPT_MODE, aesContentEncryptionKey, gcmSpec);
    cipher.updateAAD(aad);

    return cipher.doFinal(ciphertextWithTag);
  }
}

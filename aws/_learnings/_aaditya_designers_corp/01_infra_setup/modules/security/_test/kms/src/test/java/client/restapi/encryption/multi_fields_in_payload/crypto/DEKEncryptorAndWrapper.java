package client.restapi.encryption.multi_fields_in_payload.crypto;

import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import java.security.spec.MGF1ParameterSpec;
import java.security.interfaces.RSAPublicKey;
import java.util.Base64;

/**
 * DEK Encryptor and Wrapper - Wraps AES DEK using RSA-OAEP-256 encryption.
 *
 * <h2>STEP 3 (CLIENT): Wrap DEK with RSA Public Key</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  DIRECT RSA ENCRYPTION (NO JWE/CEK)                                    │
 * │                                                                        │
 * │  Input:                                                                │
 * │  ├── aesDataEncryptionKey (DEK): 32 bytes                              │
 * │  └── rsaPublicKey: RSA-4096 public key                                 │
 * │                                                                        │
 * │  Process: RSA-OAEP-256 encrypt DEK directly                            │
 * │                                                                        │
 * │  Output: BASE64(encryptedDek) (~512 bytes for RSA-4096)                │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why No CEK?</h3>
 * <ul>
 *   <li>DEK is only 32 bytes - RSA-4096 can easily encrypt it directly</li>
 *   <li>No need for intermediate CEK layer (JWE's CEK is for large payloads)</li>
 *   <li>Simpler: 1 RSA encryption instead of RSA(CEK) + AES(DEK)</li>
 *   <li>More efficient: Server needs only 1 KMS decrypt call</li>
 * </ul>
 */
@Component
public class DEKEncryptorAndWrapper {

  private static final String RSA_ALGORITHM = "RSA/ECB/OAEPWithSHA-256AndMGF1Padding";

  /**
   * Wraps the AES Data Encryption Key using RSA-OAEP-256.
   *
   * <h3>ENCRYPT-RSA (RSA-OAEP-256):</h3>
   * <pre>
   * ┌───────────────────────┐              ┌─────────────────────────────────────┐
   * │ dataEncryptionKey  │              │                                     │
   * │ (DEK - 32 bytes)      │─────────────►│       RSA-OAEP-256 ENCRYPT          │
   * └───────────────────────┘              │                                     │
   *                                        │  Cipher cipher = Cipher.getInstance │
   *                                        │    ("RSA/ECB/OAEPWithSHA-256...");  │
   * ┌───────────────────────┐              │  cipher.init(ENCRYPT_MODE,          │
   * │    publicKey       │─────────────►│    publicKey);                   │
   * │ (RSA-4096)            │              │  encryptedDek = cipher.doFinal(dek);│
   * └───────────────────────┘              │                                     │
   *                                        └──────────────────┬──────────────────┘
   *                                                           │
   *                                                           ▼
   *                                        ┌─────────────────────────────────────┐
   *                                        │ encryptedDek = ~512 bytes           │
   *                                        │ (BASE64 encoded for header)         │
   *                                        └─────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────┬─────────────────┬─────────────────────────────┬──────────────────────┐
   * │ Operation      │ Algorithm       │ Input                       │ Output               │
   * ├────────────────┼─────────────────┼─────────────────────────────┼──────────────────────┤
   * │ ENCRYPT-RSA    │ RSA-OAEP-256    │ publicKey,               │ encryptedDek         │
   * │                │                 │ dataEncryptionKey (DEK)  │ (~512 bytes)         │
   * └────────────────┴─────────────────┴─────────────────────────────┴──────────────────────┘
   * </pre>
   *
   * @param dataEncryptionKey The AES DEK to wrap (256-bit key)
   * @param publicKey         The server's RSA public key
   * @return BASE64-encoded encrypted DEK (for X-Encryption-Key header)
   * @throws RuntimeException if wrapping fails
   */
  public String encryptAndWrapDataEncryptionKey(SecretKey dataEncryptionKey, RSAPublicKey publicKey) {
    try {
      // Configure OAEP parameters (SHA-256 for both hash and MGF1)
      OAEPParameterSpec oaepParams = new OAEPParameterSpec(
          "SHA-256",
          "MGF1",
          MGF1ParameterSpec.SHA256,
          PSource.PSpecified.DEFAULT
      );

      // Initialize RSA cipher with OAEP padding
      Cipher cipher = Cipher.getInstance(RSA_ALGORITHM);
      cipher.init(Cipher.ENCRYPT_MODE, publicKey, oaepParams);

      // Encrypt the DEK
      byte[] encryptedDataEncryptionKey = cipher.doFinal(dataEncryptionKey.getEncoded());

      // Return as Base64 for HTTP header
      return Base64.getEncoder().encodeToString(encryptedDataEncryptionKey);

    } catch (Exception e) {
      throw new RuntimeException("Failed to wrap DEK with RSA: " + e.getMessage(), e);
    }
  }
}

package client.crypto;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSAEncrypter;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.security.interfaces.RSAPublicKey;

/**
 * JWE Builder - Wraps the AES encryption key using RSA public key.
 *
 * <h2>STEP 3 (CLIENT): Wrap DEK for Transport</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE KEY WRAPPING                                                      │
 * │                                                                        │
 * │  Input:  randomAESEncryptionKey (256-bit AES key from Step 2)         │
 * │          rsaPublicKey (from Step 1)                                    │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Create JWE header: {"alg":"RSA-OAEP-256","enc":"A256GCM"}         │
 * │  2. RSA-encrypt the AES key bytes using rsaPublicKey                  │
 * │  3. Build JWE compact serialization                                   │
 * │                                                                        │
 * │  Output: JWE Token (for X-Encryption-Key header)                      │
 * │  ► Server extracts the RSA-encrypted AES key and sends it to KMS      │
 * │  ► KMS uses RSA private key to decrypt → returns plaintext AES key    │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Wrap the Key?</h3>
 * <p>The AES key used to encrypt fields cannot be sent in plaintext.
 * We wrap (encrypt) it using the server's RSA public key. Only the server
 * can unwrap it using their private key stored in AWS KMS.</p>
 */
@Component
public class JwtBuilder {

  /**
   * Wraps an AES key inside a JWE using RSA public key encryption.
   *
   * @param aesEncryptionKey The AES secret key to wrap
   * @param rsaPublicKey           The server's RSA public key
   * @return JWE compact serialization string (for X-Encryption-Key header)
   * @throws RuntimeException if wrapping fails
   */
  public String wrapAndEncryptAESEncryptionKeyByRSAPublicKey(SecretKey aesEncryptionKey, RSAPublicKey rsaPublicKey) {
    try {
      // Build JWE header with algorithm specifications
      JWEHeader header = new JWEHeader.Builder(
          JWEAlgorithm.RSA_OAEP_256,  // Key encryption: RSA-OAEP with SHA-256
          EncryptionMethod.A256GCM     // Content encryption: AES-256-GCM
      ).contentType("JWT").build();

      // Create JWE object with the AES key bytes as payload
      JWEObject jweObject = new JWEObject(header, new Payload(aesEncryptionKey.getEncoded()));

      // Encrypt (wrap) using RSA public key
      jweObject.encrypt(new RSAEncrypter(rsaPublicKey));

      // Return compact serialization
      return jweObject.serialize();

    } catch (Exception e) {
      throw new RuntimeException("Failed to wrap key in JWE", e);
    }
  }
}

package client.crypto;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSAEncrypter;

import javax.crypto.SecretKey;
import java.security.interfaces.RSAPublicKey;

/**
 * JWE Builder - Wraps the encryption key for secure transport.
 *
 * <h2>STEP 3 (CLIENT): Wrap DEK for Transport</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE KEY WRAPPING                                                      │
 * │                                                                        │
 * │  Input:  DEK (256-bit AES key from Step 2)                            │
 * │          RSA Public Key (from Step 1)                                 │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Create JWE header: {"alg":"RSA-OAEP-256","enc":"A256GCM"}         │
 * │  2. Encrypt DEK bytes with RSA public key                             │
 * │  3. Build JWE compact serialization                                   │
 * │                                                                        │
 * │  Output: JWE Token for X-Encryption-Key header                        │
 * │  Format: Header.EncryptedKey.IV.Ciphertext.AuthTag                    │
 * │              │         │                                               │
 * │              │         └── RSA-encrypted DEK (server extracts this)   │
 * │              └── {"alg":"RSA-OAEP-256","enc":"A256GCM"}               │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Wrap the Key?</h3>
 * <p>The AES key used to encrypt fields cannot be sent in plaintext.
 * We wrap (encrypt) it using the server's RSA public key. Only the server
 * can unwrap it using their private key stored in AWS KMS.</p>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * SecretKey aesKey = FieldEncryptor.generateRandomAESEncryptionKey();
 * String jwe = JweBuilder.wrapKey(aesKey, rsaPublicKey);
 * // jwe = "eyJhbGciOiJSU0EtT0FFUC0yNTYi..."
 * // Send this as X-Encryption-Key header
 * }</pre>
 */
public class JweBuilder {

  /**
   * Wraps an AES key inside a JWE using RSA public key encryption.
   *
   * <p>The wrapped key can only be unwrapped by the server using their
   * RSA private key (stored securely in AWS KMS).</p>
   *
   * <h4>Algorithms Used:</h4>
   * <ul>
   *   <li><b>RSA-OAEP-256:</b> Key encryption (matches AWS KMS RSAES_OAEP_SHA_256)</li>
   *   <li><b>A256GCM:</b> Content encryption algorithm indicator</li>
   * </ul>
   *
   * @param randomAESEncryptionKey       The AES secret key to wrap
   * @param publicKey The server's RSA public key
   * @return JWE compact serialization string (for X-Encryption-Key header)
   * @throws RuntimeException if wrapping fails
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * String jwe = JweBuilder.wrapKey(aesKey, publicKey);
   * httpHeaders.set("X-Encryption-Key", jwe);
   * }</pre>
   */
  public static String wrapKey(SecretKey randomAESEncryptionKey, RSAPublicKey publicKey) {
    try {
      // Build JWE header with algorithm specifications
      JWEHeader header = new JWEHeader.Builder(
          JWEAlgorithm.RSA_OAEP_256,  // Key encryption: RSA-OAEP with SHA-256
          EncryptionMethod.A256GCM     // Content encryption: AES-256-GCM
      ).contentType("JWT").build();

      // Create JWE object with the AES key bytes as payload
      JWEObject jweObject = new JWEObject(header, new Payload(randomAESEncryptionKey.getEncoded()));

      // Encrypt (wrap) using RSA public key
      jweObject.encrypt(new RSAEncrypter(publicKey));

      // Return compact serialization (Header.EncryptedKey.IV.Ciphertext.Tag)
      return jweObject.serialize();

    } catch (Exception e) {
      throw new RuntimeException("Failed to wrap key in JWE", e);
    }
  }
}

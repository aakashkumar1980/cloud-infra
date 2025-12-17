package client.crypto;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSAEncrypter;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.security.interfaces.RSAPublicKey;

/**
 * JWE Builder - Wraps the Data Encryption Key (DEK) in JWE format.
 *
 * <h2>STEP 3 (CLIENT): Wrap DEK for Transport</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE KEY WRAPPING                                                      │
 * │                                                                        │
 * │  Input:  dataEncryptionKey (DEK - 256-bit AES key from Step 2)        │
 * │          rsaPublicKey (from Step 1)                                    │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Create JWE header: {"alg":"RSA-OAEP-256","enc":"A256GCM"}         │
 * │  2. JWE generates CEK, encrypts DEK with CEK                          │
 * │  3. RSA-encrypt CEK using rsaPublicKey → encryptedCek                 │
 * │                                                                        │
 * │  Output: JWE Token (for X-Encryption-Key header)                      │
 * │  ► Server decrypts encryptedCek via KMS → cek                         │
 * │  ► Server decrypts payload using cek → dataEncryptionKey              │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Wrap the Key?</h3>
 * <p>The DEK used to encrypt fields cannot be sent in plaintext.
 * We wrap it in JWE using the server's RSA public key. Only the server
 * can extract the DEK using their private key stored in AWS KMS.</p>
 */
@Component
public class JwtBuilder {

  /**
   * Wraps a Data Encryption Key (DEK) inside a JWE using RSA public key.
   *
   * @param dataEncryptionKey The DEK to wrap
   * @param rsaPublicKey      The server's RSA public key
   * @return JWE compact serialization string (for X-Encryption-Key header)
   * @throws RuntimeException if wrapping fails
   */
  public String wrapDataEncryptionKeyInJwe(SecretKey dataEncryptionKey, RSAPublicKey rsaPublicKey) {
    try {
      // Build JWE header with algorithm specifications
      JWEHeader header = new JWEHeader.Builder(
          JWEAlgorithm.RSA_OAEP_256,  // Key encryption: RSA-OAEP with SHA-256
          EncryptionMethod.A256GCM     // Content encryption: AES-256-GCM
      ).contentType("JWT").build();

      // Create JWE object with DEK bytes as payload
      JWEObject jweObject = new JWEObject(header, new Payload(dataEncryptionKey.getEncoded()));

      // Encrypt (wrap) using RSA public key
      jweObject.encrypt(new RSAEncrypter(rsaPublicKey));

      // Return compact serialization
      return jweObject.serialize();

    } catch (Exception e) {
      throw new RuntimeException("Failed to wrap DEK in JWE", e);
    }
  }
}

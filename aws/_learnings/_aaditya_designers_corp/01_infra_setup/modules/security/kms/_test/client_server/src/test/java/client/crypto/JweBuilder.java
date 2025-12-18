package client.crypto;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSAEncrypter;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.security.interfaces.RSAPublicKey;

/**
 * JWE Builder - Wraps the AES Data Encryption Key (DEK) in JWE format.
 *
 * <h2>STEP 3 (CLIENT): Wrap DEK for Transport</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE KEY WRAPPING                                                      │
 * │                                                                        │
 * │  Input:  aesDataEncryptionKey (DEK - 256-bit AES key from Step 2)     │
 * │          rsaPublicKey (from Step 1)                                    │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Create JWE header: {"alg":"RSA-OAEP-256","enc":"A256GCM"}         │
 * │  2. JWE generates CEK, encrypts DEK with CEK                          │
 * │  3. RSA-encrypt CEK using rsaPublicKey → encryptedCek                 │
 * │                                                                        │
 * │  Output: JWE Token (for X-Encryption-Key header)                      │
 * │  ► Server decrypts encryptedCek via KMS → cek                         │
 * │  ► Server decrypts payload using cek → aesDataEncryptionKey           │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>JWE Structure - What is Encrypted vs Not Encrypted?</h3>
 * <pre>
 * Header.EncryptedKey.IV.Ciphertext.AuthTag
 *   │         │        │      │         │
 *   │         │        │      │         └── NOT encrypted (Base64URL encoded)
 *   │         │        │      └── ENCRYPTED (DEK encrypted with CEK)
 *   │         │        └── NOT encrypted (Base64URL encoded)
 *   │         └── ENCRYPTED (CEK encrypted with RSA public key)
 *   └── NOT ENCRYPTED (Base64URL encoded, anyone can read!)
 *
 * IMPORTANT: The header {"alg":"RSA-OAEP-256","enc":"A256GCM"} is VISIBLE
 * to anyone. Only the EncryptedKey and Ciphertext are actually encrypted.
 * </pre>
 *
 * <h3>Why Wrap the Key?</h3>
 * <p>The DEK used to encrypt fields cannot be sent in plaintext.
 * We wrap it in JWE using the server's RSA public key. Only the server
 * can extract the DEK using their private key stored in AWS KMS.</p>
 */
@Component
public class JweBuilder {

  /**
   * Wraps an AES Data Encryption Key (DEK) inside a JWE using RSA public key.
   *
   * <p><b>Note:</b> The header is NOT encrypted - only Base64URL encoded.
   * Only the payload (DEK) is encrypted.</p>
   *
   * <h3>JWE Compact Serialization Format:</h3>
   * <pre>
   * BASE64URL(Header).BASE64URL(EncryptedKey).BASE64URL(IV).BASE64URL(Ciphertext).BASE64URL(AuthTag)
   * </pre>
   *
   * <h3>Sample JWE Output:</h3>
   * <pre>
   * eyJhbGciOiJSU0EtT0FFUC0yNTYiLCJlbmMiOiJBMjU2R0NNIiwiY3R5IjoiSldFIn0.
   * X9Mz1kLp...truncated...RSA-encrypted-CEK...7Yw2qA.
   * qlGBvpTz8scgIg.
   * S2Hf9mNp...truncated...AES-encrypted-DEK...8xKw.
   * 3pLLqgTg_bJf6pw7eanSpQ
   * └────────────────────┘ └──────────────────────────────┘ └──────────────┘ └────────────────────────────┘ └────────────────────┘
   *       Header (82B)           EncryptedKey (~512B)          IV (12B)          Ciphertext (32B)            AuthTag (16B)
   *
   * Actual single-line format (no line breaks):
   * eyJhbGciOiJSU0EtT0FFUC0yNTYiLCJlbmMiOiJBMjU2R0NNIiwiY3R5IjoiSldFIn0.X9Mz1kLp...7Yw2qA.qlGBvpTz8scgIg.S2Hf9mNp...8xKw.3pLLqgTg_bJf6pw7eanSpQ
   * </pre>
   *
   * <h3>Component Details:</h3>
   * <table border="1">
   *   <tr><th>Component</th><th>Size</th><th>Description</th></tr>
   *   <tr><td>Header</td><td>~82 bytes</td><td>{"alg":"RSA-OAEP-256","enc":"A256GCM","cty":"JWE"}</td></tr>
   *   <tr><td>EncryptedKey</td><td>~512 bytes</td><td>CEK encrypted with RSA-4096 public key</td></tr>
   *   <tr><td>IV</td><td>12 bytes</td><td>Initialization vector for AES-256-GCM</td></tr>
   *   <tr><td>Ciphertext</td><td>32 bytes</td><td>DEK (256-bit AES key) encrypted with CEK</td></tr>
   *   <tr><td>AuthTag</td><td>16 bytes</td><td>GCM authentication tag</td></tr>
   * </table>
   *
   * @param aesDataEncryptionKey The AES DEK to wrap (256-bit key)
   * @param rsaPublicKey         The server's RSA public key
   * @return JWE compact serialization string (for X-Encryption-Key header)
   * @throws RuntimeException if wrapping fails
   */
  public String wrapAesDataEncryptionKeyInJwe(SecretKey aesDataEncryptionKey, RSAPublicKey rsaPublicKey) {
    try {
      // Build JWE header (NOT encrypted - just Base64URL encoded)
      // Anyone can see: {"alg":"RSA-OAEP-256","enc":"A256GCM","cty":"JWT"}
      JWEHeader header = new JWEHeader.Builder(
          JWEAlgorithm.RSA_OAEP_256,  // Key encryption: RSA-OAEP with SHA-256
          EncryptionMethod.A256GCM     // Content encryption: AES-256-GCM
      ).contentType("JWE").build();

      // Create JWE object with DEK bytes as payload (THIS gets encrypted)
      JWEObject jweObject = new JWEObject(header, new Payload(aesDataEncryptionKey.getEncoded()));

      // Encrypt (wrap) using RSA public key
      jweObject.encrypt(new RSAEncrypter(rsaPublicKey));

      // Return compact serialization
      return jweObject.serialize();

    } catch (Exception e) {
      throw new RuntimeException("Failed to wrap AES DEK in JWE", e);
    }
  }
}

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
   * <h3>Internal Steps (what happens inside jweObject.encrypt()):</h3>
   * <pre>
   * ┌─────────────────────────────────────────────────────────────────────────────┐
   * │  INPUT                                                                      │
   * │  ├── aesDataEncryptionKey: 32 bytes (256-bit AES key)                      │
   * │  └── rsaPublicKey: RSA-4096 public key                                     │
   * │                                                                             │
   * │  STEP 1: Create Header (NOT encrypted)                                     │
   * │  ────────────────────────────────────────────────────────────────────────  │
   * │  header = {"alg":"RSA-OAEP-256","enc":"A256GCM","cty":"JWE"}               │
   * │                                                                             │
   * │  STEP 2: Generate random CEK (Content Encryption Key)                      │
   * │  ────────────────────────────────────────────────────────────────────────  │
   * │  cek = SecureRandom.generate(256 bits)  // 32 bytes                        │
   * │                                                                             │
   * │  STEP 3: Generate random IV (Initialization Vector)                        │
   * │  ────────────────────────────────────────────────────────────────────────  │
   * │  iv = SecureRandom.generate(96 bits)   // 12 bytes                         │
   * │                                                                             │
   * │  STEP 4: Encrypt DEK payload using CEK + IV (AES-256-GCM)                  │
   * │  ────────────────────────────────────────────────────────────────────────  │
   * │  (ciphertext, authTag) = AES-GCM-Encrypt(                                  │
   * │      key       = cek,                                                       │
   * │      iv        = iv,                                                        │
   * │      plaintext = aesDataEncryptionKey.getEncoded(),  // 32 bytes           │
   * │      aad       = BASE64URL(header)                   // for integrity      │
   * │  )                                                                          │
   * │  // ciphertext = 32 bytes (encrypted DEK)                                  │
   * │  // authTag    = 16 bytes (GCM authentication tag)                         │
   * │                                                                             │
   * │  STEP 5: Encrypt CEK using RSA public key (RSA-OAEP-256)                   │
   * │  ────────────────────────────────────────────────────────────────────────  │
   * │  encryptedKey = RSA-OAEP-Encrypt(                                          │
   * │      publicKey = rsaPublicKey,                                              │
   * │      plaintext = cek                    // 32 bytes                         │
   * │  )                                                                          │
   * │  // encryptedKey = ~512 bytes (RSA-4096 output)                            │
   * │                                                                             │
   * │  STEP 6: Combine into JWE Compact Serialization                            │
   * │  ────────────────────────────────────────────────────────────────────────  │
   * │  jwe = BASE64URL(header) + "." +                                           │
   * │        BASE64URL(encryptedKey) + "." +                                     │
   * │        BASE64URL(iv) + "." +                                               │
   * │        BASE64URL(ciphertext) + "." +                                       │
   * │        BASE64URL(authTag)                                                  │
   * │                                                                             │
   * │  OUTPUT                                                                     │
   * │  └── JWE string (~750 characters)                                          │
   * └─────────────────────────────────────────────────────────────────────────────┘
   * </pre>
   *
   * <h3>JWE Compact Serialization Format:</h3>
   * <pre>
   * BASE64URL(Header).BASE64URL(EncryptedKey).BASE64URL(IV).BASE64URL(Ciphertext).BASE64URL(AuthTag)
   * </pre>
   *
   * <h3>Sample JWE Output:</h3>
   * <pre>
   * eyJhbGciOiJSU0EtT0FFUC0yNTYiLCJlbmMiOiJBMjU2R0NNIiwiY3R5IjoiSldFIn0.
   * X9Mz1kLp...RSA-encrypted-CEK...7Yw2qA.
   * qlGBvpTz8scgIg.
   * S2Hf9mNp...AES-encrypted-DEK...8xKw.
   * 3pLLqgTg_bJf6pw7eanSpQ
   * └────────────────────┘ └─────────────────────────────┘ └──────────────┘ └───────────────────────────┘ └────────────────────┘
   *       Header (82B)          EncryptedKey (~512B)          IV (12B)         Ciphertext (32B)           AuthTag (16B)
   * </pre>
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

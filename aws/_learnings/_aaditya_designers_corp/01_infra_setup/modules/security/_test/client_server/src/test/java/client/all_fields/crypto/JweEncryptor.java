package client.all_fields.crypto;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.RSAEncrypter;
import org.springframework.stereotype.Component;

import java.security.interfaces.RSAPublicKey;

/**
 * JWE Encryptor - Encrypts entire JSON payload using JWE (RFC 7516).
 *
 * <h2>STEP 2 (CLIENT): Encrypt Entire Payload with JWE</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE ENCRYPTION (PROPER CEK USAGE)                                     │
 * │                                                                        │
 * │  Input:                                                                │
 * │  ├── jsonPayload: entire JSON string (order data with PII)             │
 * │  └── rsaPublicKey: RSA-4096 public key                                 │
 * │                                                                        │
 * │  Internal JWE Process:                                                 │
 * │  1. Generate random CEK (aesContentEncryptionKey) - 256 bits           │
 * │  2. Encrypt jsonPayload with CEK using AES-256-GCM                     │
 * │  3. Encrypt CEK with RSA public key using RSA-OAEP-256                 │
 * │  4. Combine into JWE compact format                                    │
 * │                                                                        │
 * │  Output: JWE string (Header.EncryptedCek.IV.Ciphertext.AuthTag)        │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Use JWE/CEK Here?</h3>
 * <ul>
 *   <li>Encrypting <b>entire payload</b> - could be large</li>
 *   <li>CEK allows efficient AES encryption of arbitrary-sized data</li>
 *   <li>Standard format (RFC 7516) - interoperable</li>
 *   <li>Library handles all crypto details correctly</li>
 * </ul>
 *
 * <h3>CEK vs DEK Naming:</h3>
 * <p>In JWE context, we call it <b>CEK (Content Encryption Key)</b> because it
 * encrypts the "content" (payload). Internally, it's still AES-256, so we can
 * also think of it as <b>aesContentEncryptionKey</b>.</p>
 */
@Component
public class JweEncryptor {

  /**
   * Encrypts entire JSON payload into JWE format.
   *
   * <h3>Internal Steps:</h3>
   * <pre>
   * ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   * │  INPUT                                                                                      │
   * │  ├── jsonPayload: {"name":"...", "dob":"1990-05-15", "card":"4111..."}                     │
   * │  └── rsaPublicKey: RSA-4096 public key                                                     │
   * │                                                                                             │
   * │  STEP 1: Generate CEK (Content Encryption Key)                                             │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │  aesContentEncryptionKey = SecureRandom.generate(256 bits)  // 32 bytes                    │
   * │                                                                                             │
   * │  STEP 2: Generate IV                                                                       │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │  iv = SecureRandom.generate(96 bits)  // 12 bytes                                          │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 3: ENCRYPT-AES (AES-256-GCM) - Encrypt payload with CEK                              │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────┐                                                              │
   * │      │     jsonPayload       │────┐                                                         │
   * │      │ (entire JSON)         │    │                                                         │
   * │      └───────────────────────┘    │        ┌─────────────────────────────────────────────┐  │
   * │                                   │        │                                             │  │
   * │      ┌───────────────────────┐    │        │            AES-256-GCM ENCRYPT              │  │
   * │      │ aesContentEncryption  │────┼───────►│                                             │  │
   * │      │ Key (CEK - 32 bytes)  │    │        │  ciphertext = encrypted JSON payload        │  │
   * │      └───────────────────────┘    │        │  authTag = integrity tag                    │  │
   * │                                   │        │                                             │  │
   * │      ┌───────────────────────┐    │        └─────────────────────────────────────────────┘  │
   * │      │         iv            │────┘                                                         │
   * │      │ (12 bytes)            │                                                              │
   * │      └───────────────────────┘                                                              │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 4: ENCRYPT-RSA (RSA-OAEP-256) - Encrypt CEK with RSA public key                      │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────┐              ┌─────────────────────────────────────────────┐ │
   * │      │ aesContentEncryption  │              │                                             │ │
   * │      │ Key (CEK - 32 bytes)  │─────────────►│           RSA-OAEP-256 ENCRYPT              │ │
   * │      └───────────────────────┘              │                                             │ │
   * │                                             │  encryptedCek = RSA-encrypted CEK           │ │
   * │      ┌───────────────────────┐              │  (~512 bytes for RSA-4096)                  │ │
   * │      │    rsaPublicKey       │─────────────►│                                             │ │
   * │      │ (RSA-4096)            │              │                                             │ │
   * │      └───────────────────────┘              └─────────────────────────────────────────────┘ │
   * │                                                                                             │
   * ├─────────────────────────────────────────────────────────────────────────────────────────────┤
   * │  STEP 5: Combine into JWE Compact Serialization                                            │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │  jwe = BASE64URL(header) + "." +                                                           │
   * │        BASE64URL(encryptedCek) + "." +                                                     │
   * │        BASE64URL(iv) + "." +                                                               │
   * │        BASE64URL(ciphertext) + "." +                                                       │
   * │        BASE64URL(authTag)                                                                  │
   * │                                                                                             │
   * │  OUTPUT                                                                                     │
   * │  └── JWE string (contains encrypted entire JSON payload)                                   │
   * └─────────────────────────────────────────────────────────────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────┬─────────────────┬─────────────────────────────────┬───────────────────────────────┐
   * │ Operation      │ Algorithm       │ Input                           │ Output                        │
   * ├────────────────┼─────────────────┼─────────────────────────────────┼───────────────────────────────┤
   * │ ENCRYPT-AES    │ AES-256-GCM     │ aesContentEncryptionKey (CEK),  │ ciphertext + authTag          │
   * │                │                 │ iv, jsonPayload                 │                               │
   * ├────────────────┼─────────────────┼─────────────────────────────────┼───────────────────────────────┤
   * │ ENCRYPT-RSA    │ RSA-OAEP-256    │ rsaPublicKey,                   │ encryptedCek                  │
   * │                │                 │ aesContentEncryptionKey (CEK)   │                               │
   * └────────────────┴─────────────────┴─────────────────────────────────┴───────────────────────────────┘
   * </pre>
   *
   * @param jsonPayload  The entire JSON payload to encrypt
   * @param rsaPublicKey The server's RSA public key
   * @return JWE compact serialization string
   */
  public String encrypt(String jsonPayload, RSAPublicKey rsaPublicKey) {
    try {
      // Create JWE header with RSA-OAEP-256 for key encryption and A256GCM for content encryption
      JWEHeader header = new JWEHeader.Builder(JWEAlgorithm.RSA_OAEP_256, EncryptionMethod.A256GCM)
          .contentType("json")
          .build();

      // Create JWE object with payload
      JWEObject jweObject = new JWEObject(header, new Payload(jsonPayload));

      // Encrypt with RSA public key
      // Nimbus library internally:
      // 1. Generates random CEK (aesContentEncryptionKey)
      // 2. Encrypts payload with CEK using A256GCM
      // 3. Encrypts CEK with RSA public key
      jweObject.encrypt(new RSAEncrypter(rsaPublicKey));

      // Return JWE compact serialization
      return jweObject.serialize();

    } catch (JOSEException e) {
      throw new RuntimeException("Failed to encrypt payload as JWE: " + e.getMessage(), e);
    }
  }
}

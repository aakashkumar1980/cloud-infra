package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import org.springframework.stereotype.Component;

/**
 * JWE Parser - Extracts JWE components for decryption via AWS KMS.
 *
 * <h2>STEP 5 (SERVER): Parse JWE Components</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE PARSING                                                           │
 * │                                                                        │
 * │  Input: jweEncryptionMetadata (from X-Encryption-Key header)          │
 * │                                                                        │
 * │  Process:                                                              │
 * │  1. Parse JWE compact serialization (5 dot-separated parts)           │
 * │  2. Validate algorithm is RSA-OAEP-256                                 │
 * │  3. Extract all components for decryption                             │
 * │                                                                        │
 * │  Output: JweComponents record containing:                              │
 * │    ├── encryptedCek (~512 bytes)                                       │
 * │    ├── iv (12 bytes)                                                   │
 * │    ├── encryptedAesDataEncryptionKey (32 bytes)                        │
 * │    ├── authTag (16 bytes)                                              │
 * │    └── aad (variable - header bytes)                                   │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>JWE Structure - What is Encrypted vs Not Encrypted?</h3>
 * <pre>
 * Header.EncryptedKey.IV.Ciphertext.AuthTag
 *   │         │        │      │         │
 *   │         │        │      │         └── NOT encrypted (Base64URL encoded)
 *   │         │        │      └── ENCRYPTED (aesDataEncryptionKey encrypted with cek)
 *   │         │        └── NOT encrypted (Base64URL encoded)
 *   │         └── ENCRYPTED (cek encrypted with RSA public key)
 *   └── NOT ENCRYPTED (Base64URL encoded, anyone can read!)
 *
 * IMPORTANT: The header {"alg":"RSA-OAEP-256","enc":"A256GCM"} is VISIBLE
 * to anyone. Only the EncryptedKey and Ciphertext are actually encrypted.
 * </pre>
 *
 * <h3>Why Parse?</h3>
 * <p>The server needs to extract individual components to perform two-step decryption:</p>
 * <ol>
 *   <li>encryptedCek → decrypt via KMS → cek</li>
 *   <li>encryptedAesDataEncryptionKey → decrypt with cek → aesDataEncryptionKey</li>
 * </ol>
 */
@Component
public class JweParser {

  /**
   * Parses the JWE and extracts all components needed for decryption.
   *
   * <h3>Internal Steps:</h3>
   * <pre>
   * ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   * │  INPUT                                                                                      │
   * │  └── jweEncryptionMetadata: JWE string from X-Encryption-Key header                        │
   * │                                                                                             │
   * │  STEP 1: Parse JWE Compact Serialization                                                   │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │  JWE Format: Header.EncryptedKey.IV.Ciphertext.AuthTag                                     │
   * │                │         │        │      │         │                                        │
   * │                │         │        │      │         └── NOT encrypted (Base64URL encoded)   │
   * │                │         │        │      └── ENCRYPTED (DEK encrypted with CEK)            │
   * │                │         │        └── NOT encrypted (Base64URL encoded)                    │
   * │                │         └── ENCRYPTED (CEK encrypted with RSA public key)                 │
   * │                └── NOT ENCRYPTED (Base64URL encoded, anyone can read!)                     │
   * │                                                                                             │
   * │  STEP 2: Validate Algorithm                                                                │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │  header.algorithm == "RSA-OAEP-256" ? ✓ : throw IllegalArgumentException                   │
   * │                                                                                             │
   * │  STEP 3: Extract Components                                                                │
   * │  ─────────────────────────────────────────────────────────────────────────────────────────  │
   * │                                                                                             │
   * │      ┌───────────────────────────────────────────────────────────────────────────────────┐  │
   * │      │  jweObject = JWEObject.parse(jweEncryptionMetadata)                               │  │
   * │      │                                                                                   │  │
   * │      │  encryptedCek                    = jweObject.getEncryptedKey().decode()           │  │
   * │      │  iv                              = jweObject.getIV().decode()                     │  │
   * │      │  encryptedAesDataEncryptionKey   = jweObject.getCipherText().decode()             │  │
   * │      │  authTag                         = jweObject.getAuthTag().decode()                │  │
   * │      │  aad                             = protectedHeader.getBytes(US_ASCII)             │  │
   * │      └───────────────────────────────────────────────────────────────────────────────────┘  │
   * │                                                                                             │
   * │  OUTPUT                                                                                     │
   * │  └── JweComponents record containing:                                                      │
   * │      ├── encryptedCek: ~512 bytes (RSA-encrypted CEK)                                      │
   * │      ├── iv: 12 bytes                                                                      │
   * │      ├── encryptedAesDataEncryptionKey: 32 bytes (AES-encrypted DEK)                       │
   * │      ├── authTag: 16 bytes                                                                 │
   * │      └── aad: ASCII bytes of Base64URL header (for GCM authentication)                     │
   * └─────────────────────────────────────────────────────────────────────────────────────────────┘
   * </pre>
   *
   * <h3>Summary:</h3>
   * <pre>
   * ┌────────────────────────────────────┬────────────┬──────────────────────────────────────────────┐
   * │ Component                          │ Size       │ Description                                  │
   * ├────────────────────────────────────┼────────────┼──────────────────────────────────────────────┤
   * │ encryptedCek                       │ ~512 bytes │ RSA-OAEP-256 encrypted CEK (decrypt via KMS) │
   * ├────────────────────────────────────┼────────────┼──────────────────────────────────────────────┤
   * │ iv                                 │ 12 bytes   │ Initialization Vector for AES-GCM            │
   * ├────────────────────────────────────┼────────────┼──────────────────────────────────────────────┤
   * │ encryptedAesDataEncryptionKey      │ 32 bytes   │ AES-GCM encrypted DEK (ciphertext)           │
   * ├────────────────────────────────────┼────────────┼──────────────────────────────────────────────┤
   * │ authTag                            │ 16 bytes   │ GCM authentication tag                       │
   * ├────────────────────────────────────┼────────────┼──────────────────────────────────────────────┤
   * │ aad                                │ variable   │ Additional Authenticated Data (header bytes) │
   * └────────────────────────────────────┴────────────┴──────────────────────────────────────────────┘
   * </pre>
   *
   * @param jweEncryptionMetadata The JWE encryption metadata from X-Encryption-Key header
   * @return JweComponents containing all parts needed for decryption
   * @throws IllegalArgumentException if the format is invalid
   * @throws RuntimeException if parsing fails
   */
  public JweComponents extractJweComponents(String jweEncryptionMetadata) {
    try {
      // Parse the JWE encryption metadata
      JWEObject jweObject = JWEObject.parse(jweEncryptionMetadata);
      JWEHeader header = jweObject.getHeader();

      // Validate the algorithm
      String algorithm = header.getAlgorithm().getName();
      if (!"RSA-OAEP-256".equals(algorithm)) {
        throw new IllegalArgumentException(
            "Unsupported key encryption algorithm: " + algorithm + ". Expected RSA-OAEP-256");
      }

      // Extract all JWE components
      byte[] encryptedCek = jweObject.getEncryptedKey().decode();
      byte[] iv = jweObject.getIV().decode();
      byte[] encryptedAesDataEncryptionKey = jweObject.getCipherText().decode();
      byte[] authTag = jweObject.getAuthTag().decode();

      // Extract the protected header for AAD (Additional Authenticated Data)
      // JWE AAD = ASCII(BASE64URL(UTF8(JWE Protected Header)))
      // The first part of the JWE token (before the first dot) is the Base64URL-encoded header
      String protectedHeader = jweEncryptionMetadata.split("\\.")[0];
      byte[] aad = protectedHeader.getBytes(java.nio.charset.StandardCharsets.US_ASCII);

      return new JweComponents(encryptedCek, iv, encryptedAesDataEncryptionKey, authTag, aad);

    } catch (IllegalArgumentException e) {
      throw e;
    } catch (Exception e) {
      throw new RuntimeException("Failed to parse JWE encryption metadata: " + e.getMessage(), e);
    }
  }

  /**
   * Validates JWE encryption metadata without extracting the key.
   *
   * @param jweEncryptionMetadata The JWE encryption metadata to validate
   * @return true if valid, false otherwise
   */
  public boolean isValid(String jweEncryptionMetadata) {
    try {
      extractJweComponents(jweEncryptionMetadata);
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * Record containing all JWE components needed for decryption.
   *
   * @param encryptedCek                   RSA-encrypted CEK (Content Encryption Key) - decrypted via KMS
   * @param iv                             Initialization vector for A256GCM
   * @param encryptedAesDataEncryptionKey  Encrypted payload containing the AES DEK (Data Encryption Key)
   * @param authTag                        GCM authentication tag
   * @param aad                            Additional Authenticated Data (ASCII bytes of Base64URL protected header)
   */
  public record JweComponents(byte[] encryptedCek, byte[] iv, byte[] encryptedAesDataEncryptionKey, byte[] authTag, byte[] aad) {}
}

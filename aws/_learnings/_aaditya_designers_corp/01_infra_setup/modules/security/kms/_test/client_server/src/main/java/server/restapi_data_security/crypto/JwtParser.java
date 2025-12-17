package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import org.springframework.stereotype.Component;

/**
 * JWT Parser - Extracts JWE components for two-step decryption via AWS KMS.
 *
 * <h2>STEP 5 (BACKEND): Extract JWE Components for KMS Decryption</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWT ENCRYPTION METADATA (JWE Format)                                  │
 * │                                                                        │
 * │  Header.EncryptedKey.IV.Ciphertext.AuthTag                            │
 * │    │         │        │      │         │                               │
 * │    │         │        │      │         └── GCM auth tag                │
 * │    │         │        │      └── Encrypted AES CEK (our payload)       │
 * │    │         │        └── IV for content encryption                    │
 * │    │         └── RSA-encrypted AES CEK (aesCekEncryptedKey)            │
 * │    └── {"alg":"RSA-OAEP-256","enc":"A256GCM"}                         │
 * │                                                                        │
 * │  IMPORTANT: The JWE encrypts the AES CEK in TWO layers:               │
 * │  1. A random AES CEK is RSA-encrypted → aesCekEncryptedKey            │
 * │  2. Our AES key is encrypted with CEK using A256GCM → Ciphertext      │
 * │                                                                        │
 * │  To get the original AES key:                                         │
 * │  1. Send aesCekEncryptedKey to KMS → get aesCekEncryptionKey          │
 * │  2. Use aesCekEncryptionKey + IV + AuthTag to decrypt Ciphertext      │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class JwtParser {

  /**
   * Parses the JWE and extracts all components needed for decryption.
   *
   * @param jwtEncryptionMetadata The JWT encryption metadata from X-Encryption-Key header
   * @return JweComponents containing all parts needed for decryption
   * @throws IllegalArgumentException if the format is invalid
   * @throws RuntimeException if parsing fails
   */
  public JweComponents extractJweComponents(String jwtEncryptionMetadata) {
    try {
      // Parse the JWT encryption metadata (JWE format)
      JWEObject jweObject = JWEObject.parse(jwtEncryptionMetadata);
      JWEHeader header = jweObject.getHeader();

      // Validate the algorithm
      String algorithm = header.getAlgorithm().getName();
      if (!"RSA-OAEP-256".equals(algorithm)) {
        throw new IllegalArgumentException(
            "Unsupported key encryption algorithm: " + algorithm + ". Expected RSA-OAEP-256");
      }

      // Extract all JWE components
      byte[] aesCekEncryptedKey = jweObject.getEncryptedKey().decode();
      byte[] iv = jweObject.getIV().decode();
      byte[] ciphertext = jweObject.getCipherText().decode();
      byte[] authTag = jweObject.getAuthTag().decode();

      // Extract the protected header for AAD (Additional Authenticated Data)
      // JWE AAD = ASCII(BASE64URL(UTF8(JWE Protected Header)))
      // The first part of the JWE token (before the first dot) is the Base64URL-encoded header
      String protectedHeader = jwtEncryptionMetadata.split("\\.")[0];
      byte[] aad = protectedHeader.getBytes(java.nio.charset.StandardCharsets.US_ASCII);

      return new JweComponents(aesCekEncryptedKey, iv, ciphertext, authTag, aad);

    } catch (IllegalArgumentException e) {
      throw e;
    } catch (Exception e) {
      throw new RuntimeException("Failed to parse JWT encryption metadata: " + e.getMessage(), e);
    }
  }

  /**
   * Validates JWT encryption metadata without extracting the key.
   *
   * @param jwtEncryptionMetadata The JWT encryption metadata to validate
   * @return true if valid, false otherwise
   */
  public boolean isValid(String jwtEncryptionMetadata) {
    try {
      extractJweComponents(jwtEncryptionMetadata);
      return true;
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * Record containing all JWE components needed for two-step decryption.
   *
   * @param aesCekEncryptedKey The RSA-encrypted AES CEK (Content Encryption Key) for KMS decryption
   * @param iv                 The initialization vector for A256GCM content decryption
   * @param ciphertext         The encrypted payload (contains our original AES key)
   * @param authTag            The GCM authentication tag for content decryption
   * @param aad                The Additional Authenticated Data (ASCII bytes of Base64URL protected header)
   */
  public record JweComponents(byte[] aesCekEncryptedKey, byte[] iv, byte[] ciphertext, byte[] authTag, byte[] aad) {}
}

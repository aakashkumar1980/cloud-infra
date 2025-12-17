package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import com.nimbusds.jose.util.Base64URL;
import org.springframework.stereotype.Component;

/**
 * JWT Parser - Extracts the encrypted AES key from JWT encryption metadata.
 *
 * <h2>STEP 5 (BACKEND): Extract Encrypted AES Key from JWT Metadata</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWT ENCRYPTION METADATA (JWE Format)                                  │
 * │                                                                        │
 * │  Header.EncryptedKey.IV.Ciphertext.AuthTag                            │
 * │    │         │                                                         │
 * │    │         └── RSA-encrypted AES key (THIS IS WHAT WE EXTRACT)      │
 * │    │                                                                   │
 * │    └── {"alg":"RSA-OAEP-256","enc":"A256GCM"}                         │
 * │                                                                        │
 * │  Input:  X-Encryption-Key header value (JWE compact serialization)    │
 * │  Output: byte[] encryptedAESKey (for KMS unwrapping in Step 6)        │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Parse Instead of Decrypt?</h3>
 * <p>We only need to extract the encrypted key bytes. The actual decryption
 * (unwrapping) is done by AWS KMS, which holds the private RSA key securely
 * in hardware (HSM). The private key never leaves AWS.</p>
 */
@Component
public class JwtParser {

  /**
   * Extracts the encrypted AES key bytes from JWT encryption metadata.
   *
   * @param jwtEncryptionMetadata The JWT encryption metadata from X-Encryption-Key header
   * @return The encrypted key bytes (RSA-encrypted AES key)
   * @throws IllegalArgumentException if the format is invalid
   * @throws RuntimeException if parsing fails
   */
  public byte[] extractAESEncryptionKey(String jwtEncryptionMetadata) {
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

      // Extract the encrypted key (second part of JWE)
      Base64URL encryptedKeyBase64 = jweObject.getEncryptedKey();
      return encryptedKeyBase64.decode();

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
      extractAESEncryptionKey(jwtEncryptionMetadata);
      return true;
    } catch (Exception e) {
      return false;
    }
  }
}

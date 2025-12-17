package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import com.nimbusds.jose.util.Base64URL;
import org.springframework.stereotype.Component;

/**
 * JWE Parser - Extracts the encrypted key from a JWE token.
 *
 * <h2>STEP 5 (BACKEND): Extract Encrypted Key from JWE</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE TOKEN STRUCTURE                                                   │
 * │                                                                        │
 * │  Header.EncryptedKey.IV.Ciphertext.AuthTag                            │
 * │    │         │                                                         │
 * │    │         └── RSA-encrypted DEK (THIS IS WHAT WE EXTRACT)          │
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
public class JweParser {

  /**
   * Extracts the encrypted AES key bytes from a JWE token.
   *
   * @param jwtEncryptionMetadata The JWE token from the X-Encryption-Key header
   * @return The encrypted key bytes (RSA-encrypted AES key)
   * @throws IllegalArgumentException if the JWE format is invalid
   * @throws RuntimeException if parsing fails
   */
  public byte[] extractEncryptedAESKey(String jwtEncryptionMetadata) {
    try {
      // Parse the JWE token
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
      throw new RuntimeException("Failed to parse JWE token: " + e.getMessage(), e);
    }
  }

  /**
   * Validates a JWE token without extracting the key.
   *
   * @param jwtEncryptionMetadata The JWE token to validate
   * @return true if valid, false otherwise
   */
  public boolean isValid(String jwtEncryptionMetadata) {
    try {
      extractEncryptedAESKey(jwtEncryptionMetadata);
      return true;
    } catch (Exception e) {
      return false;
    }
  }
}

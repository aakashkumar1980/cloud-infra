package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import com.nimbusds.jose.util.Base64URL;

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
 * │  Output: byte[] encryptedKey (for KMS unwrapping in Step 6)           │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 *
 * <h3>Why Parse Instead of Decrypt?</h3>
 * <p>We only need to extract the encrypted key bytes. The actual decryption
 * (unwrapping) is done by AWS KMS, which holds the private RSA key securely
 * in hardware (HSM). The private key never leaves AWS.</p>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * String jweHeader = request.getHeader("X-Encryption-Key");
 * byte[] encryptedKey = JweParser.extractEncryptedKey(jweHeader);
 * SecretKey key = KmsKeyUnwrapper.unwrap(encryptedKey);
 * }</pre>
 */
public class JweParser {

  /**
   * Extracts the encrypted key bytes from a JWE token.
   *
   * <p>Parses the JWE compact serialization and returns the second part
   * (the encrypted key). This encrypted key must be sent to AWS KMS for
   * unwrapping using the RSA private key.</p>
   *
   * @param jweToken The JWE token from the X-Encryption-Key header
   * @return The encrypted key bytes (RSA-encrypted AES key)
   * @throws IllegalArgumentException if the JWE format is invalid
   * @throws RuntimeException if parsing fails
   *
   * <h4>Validation:</h4>
   * <ul>
   *   <li>Checks that the algorithm is RSA-OAEP-256</li>
   *   <li>Verifies the JWE structure is valid</li>
   * </ul>
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * String jwe = "eyJhbGciOiJSU0EtT0FFUC0yNTYi...";
   * byte[] encryptedKey = JweParser.extractEncryptedKey(jwe);
   * // encryptedKey is ~512 bytes (RSA-4096 output)
   * }</pre>
   */
  public static byte[] extractEncryptedKey(String jweToken) {
    try {
      // Parse the JWE token
      JWEObject jweObject = JWEObject.parse(jweToken);
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
      throw e; // Re-throw validation errors
    } catch (Exception e) {
      throw new RuntimeException("Failed to parse JWE token: " + e.getMessage(), e);
    }
  }

  /**
   * Validates a JWE token without extracting the key.
   *
   * <p>Useful for quick validation before processing. Checks that the
   * token is well-formed and uses the expected algorithm.</p>
   *
   * @param jweToken The JWE token to validate
   * @return true if valid, false otherwise
   */
  public static boolean isValid(String jweToken) {
    try {
      extractEncryptedKey(jweToken);
      return true;
    } catch (Exception e) {
      return false;
    }
  }
}

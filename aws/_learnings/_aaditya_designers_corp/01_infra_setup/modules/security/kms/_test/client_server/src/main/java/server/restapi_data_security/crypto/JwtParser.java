package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import com.nimbusds.jose.util.Base64URL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Base64;

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
 * │    │         │        │      └── Encrypted AES key (our payload)       │
 * │    │         │        └── IV for content encryption                    │
 * │    │         └── RSA-encrypted CEK (Content Encryption Key)            │
 * │    └── {"alg":"RSA-OAEP-256","enc":"A256GCM"}                         │
 * │                                                                        │
 * │  IMPORTANT: The JWE encrypts the AES key in TWO layers:               │
 * │  1. A random CEK is generated and RSA-encrypted → EncryptedKey        │
 * │  2. Our AES key is encrypted with CEK using A256GCM → Ciphertext      │
 * │                                                                        │
 * │  To get the original AES key:                                         │
 * │  1. Send EncryptedKey to KMS → get decrypted CEK                      │
 * │  2. Use CEK + IV + AuthTag to decrypt Ciphertext → original AES key   │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class JwtParser {

  private static final Logger log = LoggerFactory.getLogger(JwtParser.class);

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
      log.info("=== DEBUG: JwtParser.extractJweComponents ===");
      log.info("DEBUG: JWE Token (first 100 chars): {}",
          jwtEncryptionMetadata.length() > 100 ? jwtEncryptionMetadata.substring(0, 100) + "..." : jwtEncryptionMetadata);

      // Parse the JWT encryption metadata (JWE format)
      JWEObject jweObject = JWEObject.parse(jwtEncryptionMetadata);
      JWEHeader header = jweObject.getHeader();

      // Validate the algorithm
      String algorithm = header.getAlgorithm().getName();
      String encMethod = header.getEncryptionMethod().getName();
      log.info("DEBUG: JWE Header - alg={}, enc={}", algorithm, encMethod);

      if (!"RSA-OAEP-256".equals(algorithm)) {
        throw new IllegalArgumentException(
            "Unsupported key encryption algorithm: " + algorithm + ". Expected RSA-OAEP-256");
      }

      // Extract all JWE components
      byte[] aesEncryptedKey = jweObject.getEncryptedKey().decode();
      byte[] iv = jweObject.getIV().decode();
      byte[] ciphertext = jweObject.getCipherText().decode();
      byte[] authTag = jweObject.getAuthTag().decode();

      // Extract the protected header for AAD (Additional Authenticated Data)
      // JWE AAD = ASCII(BASE64URL(UTF8(JWE Protected Header)))
      // The first part of the JWE token (before the first dot) is the Base64URL-encoded header
      String protectedHeader = jwtEncryptionMetadata.split("\\.")[0];
      byte[] aad = protectedHeader.getBytes(java.nio.charset.StandardCharsets.US_ASCII);

      log.info("DEBUG: JWE Components extracted:");
      log.info("DEBUG:   aesEncryptedKey size: {} bytes, base64: {}", aesEncryptedKey.length, Base64.getEncoder().encodeToString(aesEncryptedKey));
      log.info("DEBUG:   iv size: {} bytes, base64: {}", iv.length, Base64.getEncoder().encodeToString(iv));
      log.info("DEBUG:   ciphertext size: {} bytes, base64: {}", ciphertext.length, Base64.getEncoder().encodeToString(ciphertext));
      log.info("DEBUG:   authTag size: {} bytes, base64: {}", authTag.length, Base64.getEncoder().encodeToString(authTag));
      log.info("DEBUG:   aad (protected header): {}", protectedHeader);

      return new JweComponents(aesEncryptedKey, iv, ciphertext, authTag, aad);

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
   * @param aesEncryptedKey The RSA-encrypted Content Encryption Key (for KMS decryption)
   * @param iv           The initialization vector for A256GCM content decryption
   * @param ciphertext   The encrypted payload (contains our original AES key)
   * @param authTag      The GCM authentication tag for content decryption
   * @param aad          The Additional Authenticated Data (ASCII bytes of Base64URL protected header)
   */
  public record JweComponents(byte[] aesEncryptedKey, byte[] iv, byte[] ciphertext, byte[] authTag, byte[] aad) {}
}

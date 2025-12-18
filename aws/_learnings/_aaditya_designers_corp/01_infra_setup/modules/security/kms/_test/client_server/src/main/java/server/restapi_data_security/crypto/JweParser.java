package server.restapi_data_security.crypto;

import com.nimbusds.jose.JWEHeader;
import com.nimbusds.jose.JWEObject;
import org.springframework.stereotype.Component;

/**
 * JWE Parser - Extracts JWE components for decryption via AWS KMS.
 *
 * <h2>STEP 5 (BACKEND): Extract JWE Components</h2>
 * <pre>
 * ┌────────────────────────────────────────────────────────────────────────┐
 * │  JWE FORMAT: Header.EncryptedKey.IV.Ciphertext.AuthTag                │
 * │                                                                        │
 * │  Components:                                                           │
 * │  ├── Header: {"alg":"RSA-OAEP-256","enc":"A256GCM"} (NOT encrypted!)  │
 * │  ├── EncryptedKey: RSA-encrypted CEK (encryptedCek)                   │
 * │  ├── IV: Initialization vector for A256GCM                            │
 * │  ├── Ciphertext: Encrypted AES DEK (our Data Encryption Key)          │
 * │  └── AuthTag: GCM authentication tag                                  │
 * │                                                                        │
 * │  Two-Layer Encryption:                                                │
 * │  1. CEK (Content Encryption Key) is RSA-encrypted → encryptedCek      │
 * │  2. AES DEK (Data Encryption Key) is encrypted with CEK → Ciphertext  │
 * │                                                                        │
 * │  To extract DEK:                                                       │
 * │  1. Decrypt encryptedCek via KMS → cek                                │
 * │  2. Decrypt Ciphertext using cek → aesDataEncryptionKey               │
 * └────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@Component
public class JweParser {

  /**
   * Parses the JWE and extracts all components needed for decryption.
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
      byte[] ciphertext = jweObject.getCipherText().decode();
      byte[] authTag = jweObject.getAuthTag().decode();

      // Extract the protected header for AAD (Additional Authenticated Data)
      // JWE AAD = ASCII(BASE64URL(UTF8(JWE Protected Header)))
      // The first part of the JWE token (before the first dot) is the Base64URL-encoded header
      String protectedHeader = jweEncryptionMetadata.split("\\.")[0];
      byte[] aad = protectedHeader.getBytes(java.nio.charset.StandardCharsets.US_ASCII);

      return new JweComponents(encryptedCek, iv, ciphertext, authTag, aad);

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
   * @param encryptedCek RSA-encrypted CEK (Content Encryption Key) - decrypted via KMS
   * @param iv           Initialization vector for A256GCM
   * @param ciphertext   Encrypted payload containing the AES DEK (Data Encryption Key)
   * @param authTag      GCM authentication tag
   * @param aad          Additional Authenticated Data (ASCII bytes of Base64URL protected header)
   */
  public record JweComponents(byte[] encryptedCek, byte[] iv, byte[] ciphertext, byte[] authTag, byte[] aad) {}
}

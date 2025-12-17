package client_no_aws.crypto;

import javax.crypto.SecretKey;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * Hybrid Encryption Helper - Main utility for encrypting REST API requests.
 *
 * <p>This helper orchestrates the hybrid encryption flow, combining the speed
 * of AES with the security of RSA key exchange. It provides a simple API for
 * encrypting sensitive fields before sending them to the server.</p>
 *
 * <h3>What is Hybrid Encryption?</h3>
 * <p>Instead of encrypting each field with RSA (slow, large output), we:</p>
 * <ol>
 *   <li>Generate ONE random AES key (called DEK - Data Encryption Key)</li>
 *   <li>Encrypt ALL fields with this fast AES key (small output)</li>
 *   <li>Wrap the AES key with RSA (only once)</li>
 *   <li>Send: wrapped key in header + encrypted fields in body</li>
 * </ol>
 *
 * <h3>Benefits:</h3>
 * <ul>
 *   <li><b>Small Payload:</b> ~60 chars per field (vs 684 with direct RSA)</li>
 *   <li><b>Fast:</b> AES is ~1000x faster than RSA</li>
 *   <li><b>Efficient:</b> Server makes only 1 KMS call to unwrap key</li>
 * </ul>
 *
 * <h3>Usage Example:</h3>
 * <pre>{@code
 * HybridEncryptionHelper helper = new HybridEncryptionHelper();
 * helper.loadPublicKey(pemString);
 * helper.prepareForNewRequest();
 *
 * // Encrypt fields
 * String encryptedCard = helper.encryptField("4111111111111234");
 * String encryptedSsn = helper.encryptField("123-45-6789");
 *
 * // Get header for HTTP request
 * String headerValue = helper.getEncryptionHeader();
 * httpHeaders.set("X-Encryption-Key", headerValue);
 * }</pre>
 */
public class HybridEncryptionHelper {

  private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";

  private RSAPublicKey publicKey;
  private SecretKey currentKey;
  private String currentHeader;

  /**
   * Loads the RSA public key from the default resource location.
   *
   * <p>Looks for the public key at: src/test/resources/public-key.pem</p>
   *
   * @throws RuntimeException if the key file is not found or invalid
   */
  public void loadPublicKeyFromResources() {
    try (InputStream is = getClass().getResourceAsStream(PUBLIC_KEY_RESOURCE)) {
      if (is == null) {
        throw new IOException("Public key not found at: " + PUBLIC_KEY_RESOURCE);
      }
      String pemContent = new String(is.readAllBytes(), StandardCharsets.UTF_8);
      loadPublicKey(pemContent);
    } catch (IOException e) {
      throw new RuntimeException("Failed to load public key from resources", e);
    }
  }

  /**
   * Loads the RSA public key from a PEM-formatted string.
   *
   * @param pemContent The public key in PEM format (with or without headers)
   * @throws RuntimeException if the key is invalid
   *
   * <h4>Expected Format:</h4>
   * <pre>
   * -----BEGIN PUBLIC KEY-----
   * MIICIjANBgkqhkiG9w0BAQEFAAOCAg8A...
   * -----END PUBLIC KEY-----
   * </pre>
   */
  public void loadPublicKey(String pemContent) {
    try {
      // Remove PEM headers and whitespace
      String base64Key = pemContent
          .replace("-----BEGIN PUBLIC KEY-----", "")
          .replace("-----END PUBLIC KEY-----", "")
          .replaceAll("\\s", "");

      // Decode and create public key
      byte[] keyBytes = Base64.getDecoder().decode(base64Key);
      X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
      KeyFactory keyFactory = KeyFactory.getInstance("RSA");

      this.publicKey = (RSAPublicKey) keyFactory.generatePublic(keySpec);

    } catch (Exception e) {
      throw new RuntimeException("Failed to parse public key", e);
    }
  }

  /**
   * Prepares for a new request by generating a fresh encryption key.
   *
   * <p>Call this method before encrypting fields for each new HTTP request.
   * This ensures each request uses a unique key for maximum security.</p>
   *
   * @throws IllegalStateException if public key has not been loaded
   */
  public void prepareForNewRequest() {
    if (publicKey == null) {
      throw new IllegalStateException("Public key not loaded. Call loadPublicKey() first.");
    }

    // Generate new AES key for this request
    this.currentKey = FieldEncryptor.generateKey();

    // Wrap the key in JWE format
    this.currentHeader = JweBuilder.wrapKey(currentKey, publicKey);
  }

  /**
   * Encrypts a sensitive field value.
   *
   * <p>Uses the current request's AES key to encrypt the field.
   * Must call {@link #prepareForNewRequest()} before encrypting fields.</p>
   *
   * @param plaintext The sensitive value to encrypt (e.g., credit card number)
   * @return Encrypted string in format: iv.ciphertext.authTag
   * @throws IllegalStateException if not prepared for request
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * String encrypted = helper.encryptField("4111111111111234");
   * // Result: "abc123.xyz789.def456" (~60 chars)
   * }</pre>
   */
  public String encryptField(String plaintext) {
    if (currentKey == null) {
      throw new IllegalStateException("Not prepared for request. Call prepareForNewRequest() first.");
    }
    return FieldEncryptor.encrypt(plaintext, currentKey);
  }

  /**
   * Gets the encryption header value for the current request.
   *
   * <p>This JWE-formatted string should be sent in the X-Encryption-Key header.
   * The server will use it to unwrap the AES key and decrypt the fields.</p>
   *
   * @return The JWE string for the X-Encryption-Key header
   * @throws IllegalStateException if not prepared for request
   *
   * <h4>Example:</h4>
   * <pre>{@code
   * String headerValue = helper.getEncryptionHeader();
   * httpHeaders.set("X-Encryption-Key", headerValue);
   * }</pre>
   */
  public String getEncryptionHeader() {
    if (currentHeader == null) {
      throw new IllegalStateException("Not prepared for request. Call prepareForNewRequest() first.");
    }
    return currentHeader;
  }

  /**
   * Clears the current request state.
   *
   * <p>Call this after completing a request to clear sensitive key material
   * from memory. Optional but recommended for security.</p>
   */
  public void clear() {
    this.currentKey = null;
    this.currentHeader = null;
  }
}

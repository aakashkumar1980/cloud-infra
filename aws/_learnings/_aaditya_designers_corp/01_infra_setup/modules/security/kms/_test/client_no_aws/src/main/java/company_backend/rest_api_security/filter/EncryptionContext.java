package company_backend.rest_api_security.filter;

import javax.crypto.SecretKey;

/**
 * Thread-local context for storing the DEK during request processing
 *
 * The DEK (Data Encryption Key) is extracted from the X-Encryption-Key header
 * by the EncryptionFilter and stored here for use by the decryption service.
 *
 * Thread-local ensures each request has its own isolated DEK.
 */
public class EncryptionContext {

  private static final ThreadLocal<SecretKey> DEK_HOLDER = new ThreadLocal<>();

  /**
   * Store the DEK for the current request
   */
  public static void setDek(SecretKey dek) {
    DEK_HOLDER.set(dek);
  }

  /**
   * Get the DEK for the current request
   *
   * @return The DEK or null if not set
   */
  public static SecretKey getDek() {
    return DEK_HOLDER.get();
  }

  /**
   * Clear the DEK after request processing (important for security!)
   */
  public static void clear() {
    DEK_HOLDER.remove();
  }
}

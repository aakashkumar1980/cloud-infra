package company_backend.dto;

/**
 * Response after decrypting 3rd party data
 */
public record DecryptResponse(
    String plaintext,
    Boolean success,
    String message
) {
  public static DecryptResponse success(String plaintext) {
    return new DecryptResponse(plaintext, Boolean.TRUE, "Data decrypted successfully");
  }

  public static DecryptResponse error(String message) {
    return new DecryptResponse(null, Boolean.FALSE, message);
  }
}

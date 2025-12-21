package server._common;

import com.google.gson.JsonObject;
import org.springframework.stereotype.Component;

/**
 * Common utility methods for REST API data security.
 *
 * <p>Provides helper methods for error responses and PII masking.</p>
 */
@Component
public class Utils {

  /**
   * Creates a standardized error response JSON object.
   *
   * @param message The error message to include
   * @return JSON object with success=false and the error message
   */
  public JsonObject errorResponse(String message) {
    JsonObject response = new JsonObject();
    response.addProperty("success", false);
    response.addProperty("message", message);
    return response;
  }

  /**
   * Truncates a string to the specified maximum length, appending "..." if truncated.
   *
   * @param str    The input string
   * @param maxLen The maximum length
   * @return The truncated string with "..." if it was longer than maxLen
   */
  public String truncate(String str, int maxLen) {
    return str.length() > maxLen ? str.substring(0, maxLen) + "..." : str;
  }

  /**
   * Masks a credit card number, showing only the last 4 digits.
   *
   * @param card The credit card number to mask
   * @return Masked card number (e.g., "****-****-****-1234")
   */
  public String maskCard(String card) {
    if (card == null || card.length() < 4) return "****";
    return "****-****-****-" + card.substring(card.length() - 4);
  }

  /**
   * Masks an SSN, showing only the last 4 digits.
   *
   * @param ssn The SSN to mask
   * @return Masked SSN (e.g., "***-**-6789")
   */
  public String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) return "***-**-****";
    return "***-**-" + ssn.substring(ssn.length() - 4);
  }
}

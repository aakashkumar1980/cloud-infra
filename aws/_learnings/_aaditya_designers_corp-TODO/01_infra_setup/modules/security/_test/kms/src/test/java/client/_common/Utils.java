package client._common;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

@Component("clientUtils")
public class Utils {

  private static final Logger log = LoggerFactory.getLogger(Utils.class);
  private final Gson gson = new Gson();

  /**
   * Loads the sample-order.json file from resources and logs key details.
   *
   * @return The JsonObject representing the order
   */
  public JsonObject loadSampleOrder() {
    try (var reader = new InputStreamReader(
        Objects.requireNonNull(getClass().getClassLoader().getResourceAsStream("sample-order.json")),
        StandardCharsets.UTF_8)) {
      JsonObject order = gson.fromJson(reader, JsonObject.class);
      JsonObject cardDetails = order.getAsJsonObject("cardDetails");

      log.info("OrderData: Name={} | DOB={} | Card={} | SSN={}",
          order.get("name").getAsString(),
          order.get("dateOfBirth").getAsString(),
          maskCard(cardDetails.get("creditCardNumber").getAsString()),
          maskSsn(cardDetails.get("ssn").getAsString()));
      return order;
    } catch (Exception e) {
      throw new RuntimeException("Failed to load sample-order.json", e);
    }
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
   * @param card The credit card number
   * @return Masked card number (e.g., "****1234")
   */
  public String maskCard(String card) {
    if (card == null || card.length() < 4) return "****";
    return "****" + card.substring(card.length() - 4);
  }

  /**
   * Masks a Social Security Number, showing only the last 4 digits.
   *
   * @param ssn The SSN
   * @return Masked SSN (e.g., "***-**-1234")
   */
  public String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) return "***-**-****";
    return "***-**-" + ssn.substring(ssn.length() - 4);
  }
}

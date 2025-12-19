package server.restapi_data_security._common_utils;

import com.google.gson.JsonObject;
import org.springframework.stereotype.Component;

@Component
public class Utils {

  public JsonObject errorResponse(String message) {
    JsonObject response = new JsonObject();
    response.addProperty("success", false);
    response.addProperty("message", message);
    return response;
  }

  public String maskCard(String card) {
    if (card == null || card.length() < 4) return "****";
    return "****-****-****-" + card.substring(card.length() - 4);
  }

  public String maskSsn(String ssn) {
    if (ssn == null || ssn.length() < 4) return "***-**-****";
    return "***-**-" + ssn.substring(ssn.length() - 4);
  }
}

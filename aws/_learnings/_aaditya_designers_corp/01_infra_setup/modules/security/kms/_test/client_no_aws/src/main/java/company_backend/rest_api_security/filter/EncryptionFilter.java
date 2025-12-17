package company_backend.rest_api_security.filter;

import company_backend.rest_api_security.service.JweDecryptionService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.crypto.SecretKey;
import java.io.IOException;

/**
 * Encryption Filter
 *
 * Intercepts incoming requests to extract and unwrap the DEK from the
 * X-Encryption-Key header before the request reaches the controller.
 *
 * Flow:
 * 1. Extract JWE token from X-Encryption-Key header
 * 2. Unwrap DEK using KMS (one API call)
 * 3. Store DEK in EncryptionContext (thread-local)
 * 4. Continue filter chain
 * 5. Clear DEK after request processing
 */
@Component
@Order(1)
public class EncryptionFilter extends OncePerRequestFilter {

  private static final Logger log = LoggerFactory.getLogger(EncryptionFilter.class);
  private static final String ENCRYPTION_KEY_HEADER = "X-Encryption-Key";

  private final JweDecryptionService jweDecryptionService;

  public EncryptionFilter(JweDecryptionService jweDecryptionService) {
    this.jweDecryptionService = jweDecryptionService;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request,
      HttpServletResponse response,
      FilterChain filterChain
  ) throws ServletException, IOException {

    String jweToken = request.getHeader(ENCRYPTION_KEY_HEADER);

    try {
      if (jweToken != null && !jweToken.isBlank()) {
        log.debug("X-Encryption-Key header found, unwrapping DEK");

        // Unwrap DEK from JWE (1 KMS API call)
        SecretKey dek = jweDecryptionService.unwrapDek(jweToken);

        // Store DEK in thread-local context
        EncryptionContext.setDek(dek);

        log.debug("DEK stored in EncryptionContext");
      }

      // Continue with request processing
      filterChain.doFilter(request, response);

    } catch (Exception e) {
      log.error("Failed to unwrap DEK from X-Encryption-Key header", e);
      response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
      response.setContentType("application/json");
      response.getWriter().write("{\"error\":\"Invalid encryption key: " + e.getMessage() + "\"}");

    } finally {
      // Always clear DEK after request (security best practice)
      EncryptionContext.clear();
      log.debug("EncryptionContext cleared");
    }
  }
}

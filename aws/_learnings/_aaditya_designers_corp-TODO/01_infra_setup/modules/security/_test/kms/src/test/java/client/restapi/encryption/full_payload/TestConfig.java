package client.restapi.encryption.full_payload;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.ComponentScan;

/**
 * Test configuration for All-Fields JWE encryption tests.
 * Scans client packages for test components.
 */
@TestConfiguration
@ComponentScan(basePackages = {"client.restapi.encryption.full_payload", "client._common"})
public class TestConfig {
}

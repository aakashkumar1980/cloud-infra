package client.all_fields_encryption;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.ComponentScan;

/**
 * Test configuration for All-Fields JWE encryption tests.
 * Scans client.all_fields package for test components.
 */
@TestConfiguration
@ComponentScan(basePackages = {"client.all_fields"})
public class TestConfig {
}

package client.multi_fields;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.ComponentScan;

/**
 * Test configuration for Multi-Fields encryption tests.
 * Scans client.multi_fields package for test components.
 */
@TestConfiguration
@ComponentScan(basePackages = {"client.multi_fields"})
public class TestConfig {
}

package client.restapi.encryption.multi_fields_in_payload;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.ComponentScan;

/**
 * Test configuration for Multi-Fields encryption tests.
 * Scans client packages for test components.
 */
@TestConfiguration
@ComponentScan(basePackages = {"client.restapi.encryption.multi_fields_in_payload", "client._common"})
public class TestConfig {
}

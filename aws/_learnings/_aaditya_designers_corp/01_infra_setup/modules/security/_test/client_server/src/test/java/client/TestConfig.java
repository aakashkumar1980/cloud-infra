package client;

import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

/**
 * Test configuration that enables component scanning for client packages.
 * This is needed because the main ServerApplication only scans the 'server' package.
 */
@Configuration
@ComponentScan(basePackages = {"client"})
public class TestConfig {
}

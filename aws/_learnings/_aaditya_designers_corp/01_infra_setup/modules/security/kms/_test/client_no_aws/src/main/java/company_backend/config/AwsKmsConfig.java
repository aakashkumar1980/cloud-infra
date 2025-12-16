package company_backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.ProfileCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.kms.KmsClient;

/**
 * AWS KMS Configuration
 *
 * Creates KMS client bean using credentials from ~/.aws/credentials
 */
@Configuration
public class AwsKmsConfig {

  @Value("${aws.region}")
  private String region;

  @Bean
  public KmsClient kmsClient() {
    return KmsClient.builder()
        .region(Region.of(region))
        .credentialsProvider(ProfileCredentialsProvider.create("default"))
        .build();
  }
}

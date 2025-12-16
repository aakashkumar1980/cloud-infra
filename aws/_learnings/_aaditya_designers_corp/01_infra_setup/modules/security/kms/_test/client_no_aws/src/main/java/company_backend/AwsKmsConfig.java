package company_backend;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.kms.KmsClient;

/**
 * AWS KMS Configuration
 *
 * Creates KMS client bean using credentials from application properties.
 *
 * Credentials are injected via environment variables or system properties:
 * - Local development: Pass as env vars or -D flags
 *   Example: AWS_ACCESS_KEY_ID=xxx AWS_SECRET_ACCESS_KEY=xxx ./gradlew bootRun
 *
 * - Production (Kubernetes): Credentials populated from AWS Secrets Manager
 *   via External Secrets Operator or CSI Driver into environment variables
 *
 * Properties:
 * - aws.credentials.access-key-id: AWS Access Key ID
 * - aws.credentials.secret-access-key: AWS Secret Access Key
 * - aws.region: AWS Region (default: us-east-1)
 */
@Configuration
public class AwsKmsConfig {

  @Value("${aws.region}")
  private String region;

  @Value("${aws.credentials.access-key-id}")
  private String accessKeyId;

  @Value("${aws.credentials.secret-access-key}")
  private String secretAccessKey;

  @Bean
  public KmsClient kmsClient() {
    AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKeyId, secretAccessKey);

    return KmsClient.builder()
        .region(Region.of(region))
        .credentialsProvider(StaticCredentialsProvider.create(credentials))
        .build();
  }
}

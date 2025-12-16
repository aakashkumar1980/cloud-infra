package company_backend;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.kms.KmsClient;

/**
 * AWS KMS Configuration
 *
 * Creates KMS client bean using DefaultCredentialsProvider which automatically
 * tries credentials in this order:
 *
 * 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
 *    - Use in Docker/Kubernetes via secrets
 *
 * 2. System properties (aws.accessKeyId, aws.secretAccessKey)
 *
 * 3. Web Identity Token (for EKS with IRSA)
 *    - Best practice for Kubernetes on AWS
 *
 * 4. ~/.aws/credentials file (profile-based)
 *    - Use for local development
 *
 * 5. EC2/ECS Instance Profile / Container Credentials
 *    - Automatic when running on AWS infrastructure
 *
 * For production Kubernetes:
 * - EKS: Use IAM Roles for Service Accounts (IRSA) - no credentials needed
 * - Non-EKS: Use environment variables from Kubernetes Secrets
 */
@Configuration
public class AwsKmsConfig {

  @Value("${aws.region}")
  private String region;

  @Bean
  public KmsClient kmsClient() {
    return KmsClient.builder()
        .region(Region.of(region))
        .credentialsProvider(DefaultCredentialsProvider.create())
        .build();
  }
}

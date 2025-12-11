package com.aadityadesigners.kms.config;

import com.amazonaws.encryptionsdk.AwsCrypto;
import com.amazonaws.encryptionsdk.CommitmentPolicy;
import com.amazonaws.encryptionsdk.kmssdkv2.KmsMasterKeyProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.kms.KmsClient;

/**
 * AWS Configuration for KMS Encryption
 *
 * Configures:
 * - KMS Client (AWS SDK v2)
 * - AWS Encryption SDK crypto instance
 * - KMS Master Key Provider
 */
@Configuration
public class AwsConfig {

    @Value("${aws.region}")
    private String awsRegion;

    @Value("${aws.kms.key-arn}")
    private String kmsKeyArn;

    /**
     * AWS KMS Client using SDK v2
     */
    @Bean
    public KmsClient kmsClient() {
        return KmsClient.builder()
                .region(Region.of(awsRegion))
                .build();
    }

    /**
     * AWS Encryption SDK Crypto Instance
     *
     * Uses REQUIRE_ENCRYPT_REQUIRE_DECRYPT commitment policy
     * which is the most secure and recommended for new applications.
     */
    @Bean
    public AwsCrypto awsCrypto() {
        return AwsCrypto.builder()
                .withCommitmentPolicy(CommitmentPolicy.RequireEncryptRequireDecrypt)
                .build();
    }

    /**
     * KMS Master Key Provider
     *
     * This provider uses the KMS key to:
     * - Generate Data Encryption Keys (DEK)
     * - Encrypt/Decrypt the DEK
     *
     * The actual data encryption uses AES-GCM with the DEK (envelope encryption)
     */
    @Bean
    public KmsMasterKeyProvider kmsMasterKeyProvider() {
        return KmsMasterKeyProvider.builder()
                .defaultRegion(Region.of(awsRegion))
                .buildStrict(kmsKeyArn);
    }

    /**
     * Expose the KMS Key ARN for other components
     */
    @Bean
    public String kmsKeyArn() {
        return kmsKeyArn;
    }
}

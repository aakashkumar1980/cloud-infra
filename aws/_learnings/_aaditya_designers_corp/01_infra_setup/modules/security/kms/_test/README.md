# KMS Encryption Demo - AWS Encryption SDK

Spring Boot demo application showing how to use AWS KMS for encryption/decryption using the AWS Encryption SDK (Option 3 - Production Ready).

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENVELOPE ENCRYPTION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Your App                        AWS KMS                        │
│  ────────                        ───────                        │
│                                                                 │
│  1. "Encrypt this data"                                         │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────┐    GenerateDataKey     ┌───────────────┐  │
│  │ AWS Encryption  │ ──────────────────────►│   KMS Key     │  │
│  │     SDK         │◄────────────────────── │ (Never leaves │  │
│  └─────────────────┘  Plaintext DEK +       │    AWS)       │  │
│         │             Encrypted DEK         └───────────────┘  │
│         │                                                       │
│         ▼                                                       │
│  2. Encrypt data locally with DEK (AES-GCM)                    │
│         │                                                       │
│         ▼                                                       │
│  3. Return: [Encrypted DEK] + [Encrypted Data] + [Metadata]    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **AWS Credentials** configured:
   ```bash
   export AWS_ACCESS_KEY_ID=your-access-key
   export AWS_SECRET_ACCESS_KEY=your-secret-key
   ```

2. **KMS Key** created via Terraform:
   ```bash
   cd aws/_learnings/_aaditya_designers_corp/01_infra_setup
   terraform apply -var="profile=dev"
   ```

3. **Set KMS Key ARN**:
   ```bash
   # Get the key ARN from Terraform output
   export KMS_KEY_ARN=$(terraform output -raw kms_key_arn_nvirginia)
   # Or use alias ARN
   export KMS_KEY_ARN="arn:aws:kms:us-east-1:YOUR_ACCOUNT:alias/aaditya-designers-cmk-nvirginia-dev-terraform"
   ```

## Run the Demo

```bash
cd aws/_learnings/_aaditya_designers_corp/01_infra_setup/modules/security/kms/_test

# Run with Gradle
./gradlew bootRun

# Or with explicit key ARN
KMS_KEY_ARN="arn:aws:kms:us-east-1:123456789:key/abc-123" ./gradlew bootRun
```

## Expected Output

```
============================================================
KMS ENCRYPTION DEMO - AWS Encryption SDK
============================================================

[1] Original Text: Hello, Aaditya Designers! This is sensitive data.

[2] Encrypting with KMS...
Encrypted (Base64): AYADeJzLzUzJz0nNBQBFrAYfAAAAABwAB3B1cnBvc2UAFmRhdGEtZW5jcnlwdGlv...
Encrypted size: 587 bytes

[3] Decrypting with KMS...
Decrypted Text: Hello, Aaditya Designers! This is sensitive data.

[4] Verification:
Original matches Decrypted: ✓ SUCCESS

============================================================
DEMO COMPLETE
============================================================
```

## Key Components

| File | Description |
|------|-------------|
| `AwsConfig.java` | AWS beans configuration (KmsClient, AwsCrypto, KeyProvider) |
| `KmsEncryptionService.java` | Main encryption/decryption service |
| `KmsEncryptionDemoApplication.java` | Demo runner with examples |

## Encryption Context

The service supports **encryption context** - additional authenticated data that:
- Is NOT encrypted (stored in plaintext)
- IS cryptographically bound to ciphertext
- Must match exactly during decryption

```java
// Multi-tenant example
byte[] encrypted = service.encryptForTenant("secret", "tenant-123");
String decrypted = service.decryptForTenant(encrypted, "tenant-123");
```

## Production Considerations

1. **Key Caching**: AWS Encryption SDK supports data key caching to reduce KMS API calls
2. **Key Rotation**: Handled automatically by KMS (yearly)
3. **Cross-Region**: Use multi-region keys for disaster recovery
4. **Audit**: All KMS operations logged in CloudTrail

# Use-Case 1: Third Party Client WITHOUT AWS Account

This demonstrates encryption/decryption for 3rd party clients who do NOT have their own AWS account.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         3RD PARTY CLIENT                                     │
│                    (No AWS Account / No AWS SDK)                             │
│                                                                              │
│   1. GET /public-key ───────────────────────────┐                           │
│                                                  │                           │
│   2. Generate random DEK (256-bit)              ▼                           │
│   3. Encrypt data with DEK (AES-GCM)      ┌──────────┐                      │
│   4. Encrypt DEK with public key          │  Public  │                      │
│      (RSA-OAEP SHA-256)                   │   Key    │                      │
│                                           └──────────┘                      │
│   5. POST /decrypt ─────────────────────────────┐                           │
│      {encryptedDek, encryptedData, iv, authTag} │                           │
│                                                  │                           │
└──────────────────────────────────────────────────┼───────────────────────────┘
                                                   │
                                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMPANY BACKEND                                      │
│                    (Has AWS Account + KMS Access)                            │
│                                                                              │
│   1. Receive encrypted package                                               │
│   2. Decrypt DEK using KMS ──────────────────────┐                          │
│      (RSA private key in KMS)                    │                          │
│                                                   ▼                          │
│                                           ┌────────────┐                     │
│                                           │  AWS KMS   │                     │
│                                           │ (RSA-4096) │                     │
│                                           └────────────┘                     │
│   3. Decrypt data with DEK (AES-GCM)             │                          │
│   4. Return plaintext                            │                          │
│                                                   │                          │
└───────────────────────────────────────────────────┴──────────────────────────┘
```

## Project Structure

```
client_no_aws/
├── src/main/java/
│   └── company_backend/           # Spring Boot backend (has AWS SDK)
│       ├── CompanyBackendApplication.java
│       ├── config/
│       │   └── AwsConfig.java     # AWS KMS client configuration
│       ├── controller/
│       │   └── EncryptionController.java  # REST endpoints
│       ├── service/
│       │   ├── PublicKeyService.java      # Exports public key from KMS
│       │   └── DecryptionService.java     # Decrypts DEK + data
│       └── dto/
│           ├── PublicKeyResponse.java
│           ├── DecryptRequest.java
│           └── DecryptResponse.java
│
├── src/test/java/
│   └── client_no_aws/             # 3rd party client simulator (NO AWS SDK)
│       ├── ThirdPartyClientTest.java      # JUnit tests
│       └── crypto/
│           ├── AesEncryptor.java          # AES-GCM encryption helper
│           └── RsaEncryptor.java          # RSA-OAEP encryption helper
│
└── src/main/resources/
    └── application.yml            # Application configuration
```

## Prerequisites

1. **Deploy KMS Key** (one-time setup):
   ```bash
   cd ../terraform
   terraform init
   terraform apply
   ```

2. **Set Environment Variable**:
   ```bash
   export AWS_KMS_ASYMMETRIC_KEY_ARN=<output from terraform>
   ```

3. **AWS Credentials**: Ensure AWS credentials are configured (via environment variables, ~/.aws/credentials, or IAM role)

## Running the Tests

```bash
# From client_no_aws directory
./gradlew test

# Or run specific test
./gradlew test --tests "client_no_aws.ThirdPartyClientEncryptionTest"
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/public-key` | Get RSA public key in PEM format |
| POST | `/api/v1/decrypt` | Decrypt data sent by 3rd party |
| GET | `/api/v1/health` | Health check |

## Security Notes

- **Private key never leaves KMS**: Decryption happens inside AWS KMS
- **Public key is safe to share**: It can only encrypt, not decrypt
- **AES-GCM provides**: Confidentiality + Integrity (via auth tag)
- **RSA-OAEP with SHA-256**: Industry standard for key wrapping

# KMS Test Cases

This folder contains test implementations for three KMS use-cases:

## Use-Cases

| Use-Case | Description | Status |
|----------|-------------|--------|
| **1. Third Party WITHOUT AWS Account** | 3rd party encrypts with public key | ✅ Implemented |
| **2. Third Party WITH AWS Account** | 3rd party uses IAM credentials | 🔜 Planned |
| **3. Internal Company Apps** | Apps use envelope encryption | 🔜 Planned |

---

## Use-Case 1: Third Party WITHOUT AWS Account

### Architecture

```
3rd Party Client              Company Backend              AWS KMS
(No AWS SDK)                  (Spring Boot)
─────────────                 ─────────────                ───────
     │                             │                           │
     │  1. GET /public-key         │                           │
     │ ───────────────────────────>│                           │
     │                             │  GetPublicKey()           │
     │                             │ ─────────────────────────>│
     │  2. Public Key (PEM)        │                           │
     │ <───────────────────────────│<──────────────────────────│
     │                             │                           │
     │  3. Encrypt DEK with RSA    │                           │
     │  4. Encrypt data with AES   │                           │
     │                             │                           │
     │  5. POST /decrypt           │                           │
     │     {encryptedDek, data}    │                           │
     │ ───────────────────────────>│                           │
     │                             │  Decrypt(encryptedDek)    │
     │                             │ ─────────────────────────>│
     │                             │  plaintextDek             │
     │                             │<──────────────────────────│
     │                             │                           │
     │  6. Decrypted plaintext     │  AES decrypt locally      │
     │ <───────────────────────────│                           │
```

### Folder Structure

```
usecase1-third-party-no-aws/
├── company-backend/          # Aaditya Corp backend (has AWS creds)
│   ├── build.gradle
│   └── src/main/java/
│       └── com/aadityadesigners/kms/
│           ├── CompanyBackendApplication.java
│           ├── config/AwsKmsConfig.java
│           ├── controller/EncryptionController.java
│           ├── service/
│           │   ├── PublicKeyService.java
│           │   └── DecryptionService.java
│           └── dto/
│
└── client-simulator/         # 3rd party simulator (NO AWS SDK!)
    ├── build.gradle
    └── src/main/java/
        └── com/thirdparty/client/
            ├── ClientSimulatorApplication.java
            ├── crypto/
            │   ├── AesEncryptor.java
            │   └── RsaEncryptor.java
            └── api/CompanyApiClient.java
```

### How to Run

#### 1. Create KMS Asymmetric Key (one-time)

```bash
cd terraform
terraform init
terraform apply -var="profile=dev"
```

Copy the `asymmetric_key_arn` from output.

#### 2. Update Configuration

Edit `company-backend/src/main/resources/application.yml`:
```yaml
aws:
  kms:
    asymmetric-key-arn: <paste-arn-here>
```

#### 3. Start Company Backend

```bash
cd usecase1-third-party-no-aws/company-backend
./gradlew bootRun
```

#### 4. Run Client Simulator

```bash
cd usecase1-third-party-no-aws/client-simulator
./gradlew run
```

### Expected Output

```
[STEP 1] Fetching public key from Aaditya Corp...
✓ Public key loaded successfully

[STEP 2] Sensitive data to encrypt:
         "SSN: 123-45-6789, Credit Card: 4111-1111-1111-1111..."

[STEP 3] Encrypting data locally with AES-GCM...
✓ Data encrypted with random DEK

[STEP 4] Encrypting DEK with company's public key (RSA-OAEP)...
✓ DEK encrypted with public key

[STEP 5] Sending encrypted payload to Aaditya Corp API...
         (Sensitive data is NEVER sent in plaintext!)

[STEP 6] Response from server:
         "SSN: 123-45-6789, Credit Card: 4111-1111-1111-1111..."

═══════════════════════════════════════════════════════════════
  ✓ SUCCESS! Data round-trip verified.
  ✓ Sensitive data was encrypted locally.
  ✓ Only encrypted data traveled over the network.
  ✓ Decryption happened server-side using KMS.
═══════════════════════════════════════════════════════════════
```

---

## Security Notes

- **Private key NEVER leaves KMS** - only KMS can decrypt the DEK
- **Public key is safe to share** - cannot be used for decryption
- **Sensitive data never sent in plaintext** - encrypted before transmission
- **DEK is random per request** - even same data produces different ciphertext

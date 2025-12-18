# KMS Test Cases

This folder contains test implementations for three KMS use-cases:

## Use-Cases

| Use-Case | Description | Package | Status |
|----------|-------------|---------|--------|
| **1. Third Party WITHOUT AWS Account** | 3rd party encrypts with public key | `client_no_aws` + `company_backend` | ✅ Implemented |
| **2. Third Party WITH AWS Account** | 3rd party uses IAM credentials | `client_with_aws` | 🔜 Planned |
| **3. Internal Company Apps** | Apps use envelope encryption | `internal_app` | 🔜 Planned |

---

## Folder Structure

```
_test/
├── terraform/                    # One-time setup: Asymmetric KMS key
│   ├── locals.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── data.tf
│   ├── main.tf
│   └── outputs.tf
│
├── company_backend/              # Company Backend (Spring Boot + AWS SDK)
│   ├── build.gradle
│   ├── settings.gradle
│   └── src/main/java/company_backend/
│       ├── CompanyBackendApplication.java
│       ├── config/AwsKmsConfig.java
│       ├── controller/EncryptionController.java
│       ├── service/
│       │   ├── PublicKeyService.java
│       │   └── DecryptionService.java
│       └── dto/
│           ├── PublicKeyResponse.java
│           ├── DecryptRequest.java
│           └── DecryptResponse.java
│
├── client_no_aws/                # 3rd Party Client (NO AWS SDK!)
│   ├── build.gradle
│   ├── settings.gradle
│   └── src/main/java/client_no_aws/
│       ├── ClientSimulatorApplication.java
│       ├── crypto/
│       │   ├── AesEncryptor.java
│       │   └── RsaEncryptor.java
│       └── api/
│           └── CompanyApiClient.java
│
├── .gitignore
└── README.md
```

---

## Use-Case 1: Third Party WITHOUT AWS Account

### Architecture

```
3rd Party Client              Company Backend              AWS KMS
(No AWS SDK)                  (Spring Boot + AWS SDK)
─────────────                 ─────────────────────        ───────
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

### How to Run

#### 1. Create KMS Asymmetric Key (one-time)

```bash
cd terraform
terraform init
terraform apply -var="profile=dev"
```

Copy the `asymmetric_key_arn` from output.

#### 2. Update Company Backend Configuration

Edit `company_backend/src/main/resources/application.yml`:
```yaml
aws:
  kms:
    asymmetric-key-arn: <paste-arn-here>
```

#### 3. Start Company Backend

```bash
cd company_backend
./gradlew bootRun
```

Backend runs at `http://localhost:8080`

#### 4. Run Client Simulator

In a new terminal:
```bash
cd client_no_aws
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
- **KMS deletion window minimum 7 days** - AWS enforces this for security

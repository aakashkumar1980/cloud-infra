# KMS Test Cases

This folder contains test implementations for three KMS use-cases:

## Use-Cases

| Use-Case | Description | Package | Status |
|----------|-------------|---------|--------|
| **1. Third Party WITHOUT AWS Account** | 3rd party encrypts with public key | `client_no_aws` | ✅ Implemented |
| **2. Third Party WITH AWS Account** | 3rd party uses IAM credentials | `client_with_aws` | 🔜 Planned |
| **3. Internal Company Apps** | Apps use envelope encryption | `internal_app` | 🔜 Planned |

---

## Folder Structure

```
_test/
├── terraform/                    # Asymmetric KMS key for Use-Case 1
│   ├── locals.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   └── outputs.tf
│
├── src/main/java/
│   └── client_no_aws/            # Use-Case 1: 3rd party WITHOUT AWS
│       ├── ClientSimulatorApplication.java
│       ├── crypto/
│       │   ├── AesEncryptor.java
│       │   └── RsaEncryptor.java
│       └── api/
│           └── CompanyApiClient.java
│
├── build.gradle
├── settings.gradle
└── README.md
```

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

### How to Run

#### 1. Create KMS Asymmetric Key (one-time)

```bash
cd terraform
terraform init
terraform apply -var="profile=dev"
```

Copy the `asymmetric_key_arn` from output.

#### 2. Run Client Simulator

```bash
./gradlew run
```

**Note:** The client simulator requires the company backend to be running.
The company backend code should be set up separately with AWS KMS access.

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

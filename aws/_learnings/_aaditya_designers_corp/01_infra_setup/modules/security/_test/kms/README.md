# Hybrid Encryption for REST API

This project demonstrates two approaches to encrypting sensitive data in REST APIs using AWS KMS.

---

## Two Encryption Approaches

| Approach | Use Case | Key Type | How It Works |
|----------|----------|----------|--------------|
| **Multi-Fields** | Multiple PII fields | DEK (Data Encryption Key) | Direct RSA encryption of DEK, each field encrypted separately |
| **Full-Payload** | Entire JSON payload | CEK (Content Encryption Key) | JWE format, entire payload encrypted at once |

---

## Approach 1: Multi-Fields (Direct RSA, No JWE/CEK)

**Best for:** Encrypting multiple individual PII fields in a JSON payload.

### Client Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  CLIENT (MultiFieldsEncryptionTest → HybridEncryptionService)                │
│                                                                              │
│  Step 1: Load RSA Public Key                                                 │
│  ► hybridEncryptionService.loadPublicKey()                                   │
│  ► Load RSA-4096 public key from PEM file                                    │
│                                                                              │
│  Step 2: Generate DEK & Wrap with RSA (Direct, No CEK)                       │
│  ► hybridEncryptionService.generateEncryptAndWrapDataEncryptionKey()         │
│    ├── DEKGenerator.generateDataEncryptionKey() → 256-bit AES key            │
│    └── DEKEncryptorAndWrapper.encryptAndWrapDataEncryptionKey()              │
│        └── RSA-OAEP-256 encrypt DEK → encryptedDataEncryptionKey             │
│                                                                              │
│  Step 3: Encrypt PII Fields with DEK                                         │
│  ► hybridEncryptionService.encryptField(plainText)                           │
│    └── FieldEncryptor.encrypt(plainText, dataEncryptionKey)                  │
│        └── AES-256-GCM encrypt → "BASE64(IV).BASE64(ciphertext).BASE64(tag)" │
│                                                                              │
│  Step 4: Get Encrypted DEK for Header                                        │
│  ► hybridEncryptionService.getEncryptedDataEncryptionKey()                   │
│                                                                              │
│  Step 5: Submit Order to API                                                 │
│  ► POST /api/v1/multi-fields/orders                                          │
│    Header: X-Encryption-Key: BASE64(encryptedDataEncryptionKey)              │
│    Body: { "dateOfBirth": "encrypted", "cardDetails": {...} }                │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Server Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVER (OrderController → OrderService)                                     │
│                                                                              │
│  Step 6: Unwrap DEK via AWS KMS (1 KMS call)                                 │
│  ► DEKDecryptorAndUnwrapper.unwrapAndDecryptDataEncryptionKeyViaAWSKMS()     │
│    ├── Decode Base64 → encryptedDataEncryptionKey bytes                      │
│    ├── KMS DecryptRequest (RSA-OAEP-256)                                     │
│    │   └── RSA private key NEVER leaves HSM                                  │
│    └── Return dataEncryptionKey (DEK) - 32 bytes                             │
│                                                                              │
│  Step 7: Decrypt PII Fields Locally                                          │
│  ► FieldDecryptor.decrypt(encryptedField, dataEncryptionKey)                 │
│    ├── Parse: iv, encryptedText, authTag from dot-separated string           │
│    ├── AES-256-GCM decrypt (fast, local, no KMS call)                        │
│    └── Return plainText                                                      │
│                                                                              │
│  Response: { "success": true, "dateOfBirth": "1990-05-15", ... }             │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Why No CEK?

- DEK is only 32 bytes - RSA can encrypt it directly
- No intermediate CEK layer needed
- Simpler: 1 RSA decryption instead of RSA(CEK) + AES(DEK)
- Server needs only 1 KMS call

### Multi-Fields Summary Table

| Step | Component | Operation | Algorithm | Input | Output |
|------|-----------|-----------|-----------|-------|--------|
| 2 | DEKGenerator | Generate key | AES | - | dataEncryptionKey (32 bytes) |
| 2 | DEKEncryptorAndWrapper | ENCRYPT-RSA | RSA-OAEP-256 | publicKey, DEK | encryptedDataEncryptionKey |
| 3 | FieldEncryptor | ENCRYPT-AES | AES-256-GCM | DEK, iv, plainText | IV.ciphertext.authTag |
| 6 | DEKDecryptorAndUnwrapper | DECRYPT-RSA | RSA-OAEP-256 (KMS) | encryptedDEK | dataEncryptionKey |
| 7 | FieldDecryptor | DECRYPT-AES | AES-256-GCM | DEK, iv, ciphertext | plainText |

---

## Approach 2: Full-Payload (JWE with CEK)

**Best for:** Encrypting entire JSON payload at once.

### Client Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  CLIENT (FullPayloadEncryptionTest → HybridEncryptionService)                │
│                                                                              │
│  Step 1: Load RSA Public Key                                                 │
│  ► hybridEncryptionService.loadPublicKey()                                   │
│  ► Load RSA-4096 public key from PEM file                                    │
│                                                                              │
│  Step 2: Encrypt Entire Payload as JWE                                       │
│  ► hybridEncryptionService.encryptPayload(jsonPayload)                       │
│    └── PayloadEncryptor.encrypt(payload, publicKey)                          │
│        ├── JWE library internally:                                           │
│        │   ├── Generate random CEK (contentEncryptionKey) - 256 bits         │
│        │   ├── Generate random IV - 12 bytes                                 │
│        │   ├── AES-256-GCM encrypt payload with CEK → ciphertext + authTag   │
│        │   └── RSA-OAEP-256 encrypt CEK → encryptedContentEncryptionKey      │
│        └── Return JWE: Header.EncryptedCEK.IV.Ciphertext.AuthTag             │
│                                                                              │
│  Step 3: Submit Order to API                                                 │
│  ► POST /api/v1/all-fields/orders                                            │
│    Content-Type: text/plain                                                  │
│    Body: <JWE string>                                                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Server Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVER (OrderController → OrderService → PayloadDecryptor)                  │
│                                                                              │
│  Step 4: Decrypt JWE Payload                                                 │
│  ► PayloadDecryptor.decrypt(jweString)                                       │
│                                                                              │
│    Step 4a: Parse JWE                                                        │
│    ├── Extract: encryptedCEK, iv, ciphertext, authTag, aad                   │
│                                                                              │
│    Step 4b: Decrypt CEK via AWS KMS (1 KMS call)                             │
│    ├── decryptCekViaKms(encryptedCEK)                                        │
│    │   ├── KMS DecryptRequest (RSA-OAEP-256)                                 │
│    │   │   └── RSA private key NEVER leaves HSM                              │
│    │   └── Return contentEncryptionKey (CEK) - 32 bytes                      │
│                                                                              │
│    Step 4c: Decrypt Payload Locally                                          │
│    ├── decryptText(CEK, ciphertext, iv, authTag, aad)                        │
│    │   ├── AES-256-GCM decrypt with AAD (fast, local)                        │
│    │   └── Return jsonPayload                                                │
│                                                                              │
│  Response: { "success": true, "dateOfBirth": "1990-05-15", ... }             │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Why Use CEK Here?

- Encrypting **entire payload** - could be large
- CEK allows efficient AES encryption of arbitrary-sized data
- Standard JWE format (RFC 7516) - interoperable
- Library handles all crypto details

### Full-Payload Summary Table

| Step | Component | Operation | Algorithm | Input | Output |
|------|-----------|-----------|-----------|-------|--------|
| 2 | PayloadEncryptor (JWE lib) | Generate CEK | AES | - | contentEncryptionKey (32 bytes) |
| 2 | PayloadEncryptor (JWE lib) | ENCRYPT-AES | AES-256-GCM | CEK, iv, payload | ciphertext + authTag |
| 2 | PayloadEncryptor (JWE lib) | ENCRYPT-RSA | RSA-OAEP-256 | publicKey, CEK | encryptedCEK |
| 4b | PayloadDecryptor | DECRYPT-RSA | RSA-OAEP-256 (KMS) | encryptedCEK | contentEncryptionKey |
| 4c | PayloadDecryptor | DECRYPT-AES | AES-256-GCM | CEK, iv, ciphertext, aad | jsonPayload |

---

## When to Use Which?

| Scenario | Recommended Approach |
|----------|---------------------|
| Multiple individual PII fields | **Multi-Fields** (DEK) |
| Entire payload encryption | **Full-Payload** (JWE/CEK) |
| Need to process fields separately on server | **Multi-Fields** (DEK) |
| Need standard JWE format | **Full-Payload** (JWE/CEK) |
| File encryption (future) | **DEK** (similar to Multi-Fields) |

---

## Key Terminology

| Term | Full Name | Variable Name | Used In | Description |
|------|-----------|---------------|---------|-------------|
| **DEK** | Data Encryption Key | `dataEncryptionKey` | Multi-Fields | 256-bit AES key we generate and control |
| **CEK** | Content Encryption Key | `contentEncryptionKey` | Full-Payload (JWE) | 256-bit AES key generated by JWE library |
| **JWE** | JSON Web Encryption | - | Full-Payload | Standard format for encrypted payloads (RFC 7516) |

---

## Project Structure

```
src/
├── main/java/server/
│   ├── _common/
│   │   └── Utils.java                          # Common utilities (masking, error responses)
│   ├── AwsKmsConfig.java                       # AWS KMS client configuration
│   ├── ServerApplication.java                  # Spring Boot application entry point
│   │
│   └── restapi/encryption/
│       ├── multi_fields_in_payload/            # Approach 1: Direct RSA of DEK
│       │   ├── controller/
│       │   │   └── OrderController.java        # REST endpoint /api/v1/multi-fields/orders
│       │   ├── crypto/
│       │   │   ├── DEKDecryptorAndUnwrapper.java   # KMS decrypt encryptedDEK → DEK
│       │   │   └── FieldDecryptor.java             # AES decrypt fields with DEK
│       │   └── service/
│       │       └── OrderService.java           # Order processing orchestration
│       │
│       └── full_payload/                       # Approach 2: JWE with CEK
│           ├── controller/
│           │   └── OrderController.java        # REST endpoint /api/v1/all-fields/orders
│           ├── crypto/
│           │   └── PayloadDecryptor.java       # KMS decrypt encryptedCEK + AES decrypt payload
│           └── service/
│               └── OrderService.java           # Order processing orchestration
│
└── test/java/client/
    ├── _common/
    │   └── Utils.java                          # Test utilities (load sample order, truncate)
    │
    └── restapi/encryption/
        ├── multi_fields_in_payload/            # Test client for Approach 1
        │   ├── TestConfig.java                 # Spring test configuration
        │   ├── MultiFieldsEncryptionTest.java  # End-to-end test
        │   ├── crypto/
        │   │   ├── DEKGenerator.java               # Generate dataEncryptionKey (DEK)
        │   │   ├── DEKEncryptorAndWrapper.java     # RSA encrypt DEK → encryptedDEK
        │   │   └── FieldEncryptor.java             # AES encrypt fields with DEK
        │   └── service/
        │       └── HybridEncryptionService.java    # Client-side encryption orchestration
        │
        └── full_payload/                       # Test client for Approach 2
            ├── TestConfig.java                 # Spring test configuration
            ├── FullPayloadEncryptionTest.java  # End-to-end test
            ├── crypto/
            │   └── PayloadEncryptor.java       # JWE encrypt entire payload (CEK internally)
            └── service/
                └── HybridEncryptionService.java    # Client-side encryption orchestration
```

---

## Running the Tests

### Multi-Fields Test (Direct RSA, No CEK)
```bash
./gradlew test --tests "client.restapi.encryption.multi_fields_in_payload.MultiFieldsEncryptionTest"
```

### Full-Payload Test (JWE with CEK)
```bash
./gradlew test --tests "client.restapi.encryption.full_payload.FullPayloadEncryptionTest"
```

### Run All Tests
```bash
./gradlew test
```

---

## API Endpoints

### Multi-Fields
- `GET /api/v1/multi-fields/health` - Health check
- `POST /api/v1/multi-fields/orders` - Submit order with encrypted fields
  - Header: `X-Encryption-Key: BASE64(encryptedDataEncryptionKey)`
  - Body: JSON with individually encrypted PII fields

### Full-Payload
- `GET /api/v1/all-fields/health` - Health check
- `POST /api/v1/all-fields/orders` - Submit JWE-encrypted order
  - Content-Type: `text/plain`
  - Body: JWE compact serialization string

---

## Security

- RSA private key **never leaves AWS KMS HSM**
- **1 KMS API call per request** (regardless of approach)
- AES-256-GCM provides **authenticated encryption**
- AuthTag validates data integrity

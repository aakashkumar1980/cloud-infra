# Hybrid Encryption for REST API

This project demonstrates two approaches to encrypting sensitive data in REST APIs using AWS KMS.

---

## Two Encryption Approaches

| Approach | Use Case | Key Type | How It Works |
|----------|----------|----------|--------------|
| **Multi-Fields** | Multiple PII fields | DEK (Data Encryption Key) | Direct RSA encryption of DEK, each field encrypted separately |
| **All-Fields** | Entire JSON payload | CEK (Content Encryption Key) | JWE format, entire payload encrypted at once |

---

## Approach 1: Multi-Fields (Direct RSA, No JWE/CEK)

**Best for:** Encrypting multiple individual PII fields in a JSON payload.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  CLIENT                                                                      │
│                                                                              │
│  Step 1: Generate DEK (dataEncryptionKey) - 256 bits                         │
│  Step 2: Encrypt DEK directly with RSA → encryptedDataEncryptionKey          │
│  Step 3: Encrypt each field with DEK → encryptedField                        │
│                                                                              │
│  Request:                                                                    │
│  POST /api/v1/multi-fields/orders                                            │
│  X-Encryption-Key: BASE64(encryptedDataEncryptionKey)                        │
│  Body: { "dob": "encrypted", "card": "encrypted", ... }                      │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVER                                                                      │
│                                                                              │
│  Step 1: KMS decrypt header → DEK (1 KMS call, direct RSA)                   │
│  Step 2: Local AES decrypt each field using DEK                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Why No CEK?

- DEK is only 32 bytes - RSA can encrypt it directly
- No intermediate CEK layer needed
- Simpler: 1 RSA decryption instead of RSA(CEK) + AES(DEK)
- Server needs only 1 KMS call

### Multi-Fields Summary Table

| Operation | Algorithm | Input | Output |
|-----------|-----------|-------|--------|
| **Client: ENCRYPT-RSA** | RSA-OAEP-256 | publicKey, dataEncryptionKey | encryptedDataEncryptionKey |
| **Client: ENCRYPT-AES** | AES-256-GCM | dataEncryptionKey, iv, plainText | encryptedField |
| **Server: DECRYPT-RSA** | RSA-OAEP-256 (KMS) | encryptedDataEncryptionKey | dataEncryptionKey |
| **Server: DECRYPT-AES** | AES-256-GCM | dataEncryptionKey, iv, encryptedField | plainText |

---

## Approach 2: All-Fields (JWE with CEK)

**Best for:** Encrypting entire JSON payload at once.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  CLIENT                                                                      │
│                                                                              │
│  Step 1: Build JSON payload with plaintext PII                               │
│  Step 2: Encrypt entire payload as JWE:                                      │
│          - JWE library generates contentEncryptionKey (CEK) internally       │
│          - CEK encrypts entire JSON → ciphertext                             │
│          - RSA encrypts CEK → encryptedContentEncryptionKey                  │
│                                                                              │
│  Request:                                                                    │
│  POST /api/v1/all-fields/orders                                              │
│  Content-Type: text/plain                                                    │
│  Body: <JWE string> (Header.EncryptedContentEncryptionKey.IV.Ciphertext.AuthTag) │
└──────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│  SERVER                                                                      │
│                                                                              │
│  Step 1: Parse JWE from body                                                 │
│  Step 2: KMS decrypt encryptedContentEncryptionKey → contentEncryptionKey (1 KMS call) │
│  Step 3: Local AES decrypt ciphertext → JSON payload                         │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Why Use CEK Here?

- Encrypting **entire payload** - could be large
- CEK allows efficient AES encryption of arbitrary-sized data
- Standard JWE format (RFC 7516) - interoperable
- Library handles all crypto details

### All-Fields Summary Table

| Operation | Algorithm | Input | Output |
|-----------|-----------|-------|--------|
| **Client: ENCRYPT-AES** | AES-256-GCM | contentEncryptionKey, iv, jsonPayload | ciphertext + authTag |
| **Client: ENCRYPT-RSA** | RSA-OAEP-256 | publicKey, contentEncryptionKey | encryptedContentEncryptionKey |
| **Server: DECRYPT-RSA** | RSA-OAEP-256 (KMS) | encryptedContentEncryptionKey | contentEncryptionKey |
| **Server: DECRYPT-AES** | AES-256-GCM | contentEncryptionKey, iv, ciphertext | jsonPayload |

---

## When to Use Which?

| Scenario | Recommended Approach |
|----------|---------------------|
| Multiple individual PII fields | **Multi-Fields** (DEK) |
| Entire payload encryption | **All-Fields** (JWE/CEK) |
| Need to process fields separately on server | **Multi-Fields** (DEK) |
| Need standard JWE format | **All-Fields** (JWE/CEK) |
| File encryption (future) | **DEK** (similar to Multi-Fields) |

---

## Key Terminology

| Term | Full Name | Variable Name | Used In | Description |
|------|-----------|---------------|---------|-------------|
| **DEK** | Data Encryption Key | `dataEncryptionKey` | Multi-Fields | 256-bit AES key we generate and control |
| **CEK** | Content Encryption Key | `contentEncryptionKey` | All-Fields (JWE) | 256-bit AES key generated by JWE library |
| **JWE** | JSON Web Encryption | - | All-Fields | Standard format for encrypted payloads (RFC 7516) |

---

## Project Structure

```
src/
├── main/java/server/restapi_data_security/
│   ├── multi_fields_encryption/    # Approach 1: Direct RSA of DEK
│   │   ├── controller/
│   │   ├── crypto/
│   │   │   ├── DEKDecryptorAndUnwrapper.java  # KMS decrypt encryptedDataEncryptionKey → DEK
│   │   │   └── FieldDecryptor.java            # AES decrypt fields with DEK
│   │   └── service/
│   │
│   └── all_fields_encryption/      # Approach 2: JWE with CEK
│       ├── controller/
│       ├── crypto/
│       │   └── PayloadDecryptor.java          # KMS decrypt encryptedContentEncryptionKey (CEK) + AES decrypt payload
│       └── service/
│
└── test/java/client/
    ├── multi_fields_encryption/    # Test client for Approach 1
    │   ├── crypto/
    │   │   ├── DEKGenerator.java              # Generate dataEncryptionKey (DEK)
    │   │   ├── DEKEncryptorAndWrapper.java    # RSA encrypt DEK → encryptedDataEncryptionKey
    │   │   └── FieldEncryptor.java            # AES encrypt fields with DEK
    │   └── service/
    │
    └── all_fields_encryption/      # Test client for Approach 2
        ├── crypto/
        │   └── PayloadEncryptor.java          # JWE encrypt entire payload (CEK generated internally)
        └── service/
```

---

## Running the Tests

### Multi-Fields Test (Direct RSA, No CEK)
```bash
./gradlew test --tests "client.restapi.multi_fields_in_payload.MultiFieldsEncryptionTest"
```

### All-Fields Test (JWE with CEK)
```bash
./gradlew test --tests "client.restapi.full_payload.AllFieldsEncryptionTest"
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

### All-Fields
- `GET /api/v1/all-fields/health` - Health check
- `POST /api/v1/all-fields/orders` - Submit JWE-encrypted order

---

## Security

- RSA private key **never leaves AWS KMS HSM**
- **1 KMS API call per request** (regardless of approach)
- AES-256-GCM provides **authenticated encryption**
- AuthTag validates data integrity

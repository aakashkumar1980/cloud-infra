# Hybrid Encryption for REST API (Field-Level PII Encryption)

This project demonstrates **field-level encryption** for sensitive PII data using a hybrid encryption approach with AWS KMS.

---

## Encryption Flow Overview

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  CLIENT                                                                          │
│                                                                                  │
│  STEP 1: Load RSA Public Key                                                     │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  rsaPublicKey = loadFromPEM("public-key.pem")  // RSA-4096                       │
│                                                                                  │
│  STEP 2: Generate AES Data Encryption Key (DEK)                                  │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  aesDataEncryptionKey = KeyGenerator.getInstance("AES").generateKey()            │
│  // Output: 32 bytes (256-bit random AES key)                                    │
│                                                                                  │
│  STEP 3: Wrap DEK in JWE                                                         │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  jwe = jweMetadataBuilder.wrapAesDataEncryptionKeyInJwe(aesDataEncryptionKey, rsaPubKey) │
│  // Output: "eyJhbGci...Header.EncryptedKey.IV.Ciphertext.AuthTag"               │
│                                                                                  │
│  STEP 4: Encrypt PII Fields with DEK                                             │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  encryptedDob  = fieldEncryptor.encrypt("1990-05-15", aesDataEncryptionKey)      │
│  encryptedCard = fieldEncryptor.encrypt("4111111111111234", aesDataEncryptionKey)│
│  encryptedSsn  = fieldEncryptor.encrypt("123-45-6789", aesDataEncryptionKey)     │
│  // Output: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"                   │
│                                                                                  │
│  HTTP Request:                                                                   │
│  POST /api/v1/orders                                                             │
│  X-Encryption-Key: <JWE>                                                         │
│  Body: {"dateOfBirth": "<encrypted>", "cardDetails": {...}}                      │
└──────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│  SERVER                                                                          │
│                                                                                  │
│  STEP 5: Parse JWE Components                                                    │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  jweComponents = jweParser.extractJweComponents(jweEncryptionMetadata)           │
│  // Output: encryptedCek, iv, ciphertext, authTag, aad                           │
│                                                                                  │
│  STEP 6: Extract DEK via AWS KMS (1 API call)                                    │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  aesDataEncryptionKey = awsKmsDecryptionService.extractAesDataEncryptionKey(jwe) │
│  // KMS decrypts encryptedCek → cek, then cek decrypts ciphertext → DEK          │
│                                                                                  │
│  STEP 7: Decrypt PII Fields Locally (no additional KMS calls)                    │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  dob  = fieldDecryptor.decrypt(encryptedDob, aesDataEncryptionKey)  // 1990-05-15│
│  card = fieldDecryptor.decrypt(encryptedCard, aesDataEncryptionKey) // 4111...   │
│  ssn  = fieldDecryptor.decrypt(encryptedSsn, aesDataEncryptionKey)  // 123-45-...│
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## Step 3 Details: JWE Wrapping (Internal Steps)

When `jweMetadataBuilder.wrapAesDataEncryptionKeyInJwe()` is called:

```
INPUT:
  ├── aesDataEncryptionKey: 32 bytes (256-bit AES key)
  └── rsaPublicKey: RSA-4096 public key

STEP 1: Create Header (NOT encrypted, only Base64URL encoded)
────────────────────────────────────────────────────────────
header = {"alg":"RSA-OAEP-256","enc":"A256GCM","cty":"JWE"}

STEP 2: Generate random CEK (Content Encryption Key)
────────────────────────────────────────────────────────────
cek = SecureRandom.generate(256 bits)  // 32 bytes

STEP 3: Generate random IV (Initialization Vector)
────────────────────────────────────────────────────────────
iv = SecureRandom.generate(96 bits)    // 12 bytes

STEP 4: Encrypt DEK using CEK + IV (AES-256-GCM)
────────────────────────────────────────────────────────────
(ciphertext, authTag) = AES-GCM-Encrypt(
    key       = cek,
    iv        = iv,
    plaintext = aesDataEncryptionKey.getEncoded(),  // 32 bytes
    aad       = BASE64URL(header)                    // for integrity
)
// ciphertext = 32 bytes (encrypted DEK)
// authTag    = 16 bytes (GCM authentication tag)

STEP 5: Encrypt CEK using RSA public key (RSA-OAEP-256)
────────────────────────────────────────────────────────────
encryptedKey = RSA-OAEP-Encrypt(
    publicKey = rsaPublicKey,
    plaintext = cek                    // 32 bytes
)
// encryptedKey = ~512 bytes (RSA-4096 output)

STEP 6: Combine into JWE Compact Serialization
────────────────────────────────────────────────────────────
jwe = BASE64URL(header) + "." +
      BASE64URL(encryptedKey) + "." +
      BASE64URL(iv) + "." +
      BASE64URL(ciphertext) + "." +
      BASE64URL(authTag)

OUTPUT:
└── JWE string (~750 characters)
```

**Sample JWE Output:**
```
eyJhbGciOiJSU0EtT0FFUC0yNTYiLCJlbmMiOiJBMjU2R0NNIiwiY3R5IjoiSldFIn0.X9Mz1kLp...7Yw2qA.qlGBvpTz8scgIg.S2Hf9mNp...8xKw.3pLLqgTg_bJf6pw7eanSpQ
└────────────────────────────────────────────────────────┘ └───────────────────┘ └──────────────┘ └─────────────────┘ └────────────────────┘
                      Header (82B)                          EncryptedKey (~512B)     IV (12B)      Ciphertext (32B)      AuthTag (16B)
```

---

## Step 4 Details: Field Encryption

When `fieldEncryptor.encrypt()` is called:

```
INPUT:
  ├── plaintext: "1990-05-15"
  └── aesDataEncryptionKey: 32 bytes (the DEK)

STEP 1: Generate random IV
────────────────────────────────────────────────────────────
iv = SecureRandom.generate(96 bits)  // 12 bytes

STEP 2: Encrypt plaintext using DEK + IV (AES-256-GCM)
────────────────────────────────────────────────────────────
(encryptedText, authTag) = AES-GCM-Encrypt(
    key       = aesDataEncryptionKey,
    iv        = iv,
    plaintext = "1990-05-15".getBytes()
)
// authTag = 16 bytes (used for validation during decryption)

STEP 3: Combine into dot-separated format
────────────────────────────────────────────────────────────
output = BASE64(iv) + "." + BASE64(encryptedText) + "." + BASE64(authTag)

OUTPUT:
└── "rK8xMzQ1Njc4OTAx.YWJjZGVmZ2hpamts...eXo=.dGFnMTIzNDU2Nzg5MDEyMzQ1Ng=="
     └───────────────┘ └────────────────────────┘ └──────────────────────────────┘
         IV (12B)          EncryptedText              AuthTag (16B)
```

---

## Key Terminology

| Term | Full Name | Description |
|------|-----------|-------------|
| **DEK** | Data Encryption Key | 256-bit AES key that encrypts actual PII data |
| **CEK** | Content Encryption Key | JWE's internal random key (handled by library) |
| **JWE** | JSON Web Encryption | Standard format for encrypted payloads (RFC 7516) |
| **AAD** | Additional Authenticated Data | Header used for GCM integrity verification |

---

## Performance

| Aspect | Detail |
|--------|--------|
| **KMS API calls** | 1 per request (regardless of number of fields) |
| **AES decryption** | Local, extremely fast (~GB/sec) |
| **DEK reuse** | Same key decrypts all fields in one request |

---

## Security

- RSA private key **never leaves AWS KMS HSM**
- DEK is **randomly generated per request**
- AES-256-GCM provides **authenticated encryption** (integrity + confidentiality)
- AuthTag **validates data integrity** during decryption
- JWE header uses **AAD** to prevent tampering

---

## Running the Tests

```bash
./gradlew test --tests "client.ClientRESTAPIEncryptionTest"
```

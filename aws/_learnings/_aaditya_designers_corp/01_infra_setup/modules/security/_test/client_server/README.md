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
│  // Output: encryptedCek, iv, encryptedAesDataEncryptionKey, authTag, aad        │
│                                                                                  │
│  STEP 6: Extract DEK via AWS KMS (1 API call)                                    │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  aesDataEncryptionKey = awsKmsDecryptionService.extractAesDataEncryptionKey(jwe) │
│  // 6a: KMS decrypts encryptedCek → cek                                          │
│  // 6b: Local AES decrypts encryptedAesDataEncryptionKey → aesDataEncryptionKey  │
│                                                                                  │
│  STEP 7: Decrypt PII Fields Locally (no additional KMS calls)                    │
│  ─────────────────────────────────────────────────────────────────────────────── │
│  dob  = fieldDecryptor.decrypt(encryptedDob, aesDataEncryptionKey)  // 1990-05-15│
│  card = fieldDecryptor.decrypt(encryptedCard, aesDataEncryptionKey) // 4111...   │
│  ssn  = fieldDecryptor.decrypt(encryptedSsn, aesDataEncryptionKey)  // 123-45-...│
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## CLIENT: Step 3 Details - JWE Wrapping (Internal Steps)

When `jweMetadataBuilder.wrapAesDataEncryptionKeyInJwe()` is called:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  INPUT                                                                                      │
│  ├── aesDataEncryptionKey: 32 bytes (256-bit AES key)                                      │
│  └── rsaPublicKey: RSA-4096 public key                                                     │
│                                                                                             │
│  STEP 1: Create Header (NOT encrypted)                                                     │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│  header = {"alg":"RSA-OAEP-256","enc":"A256GCM","cty":"JWE"}                               │
│                                                                                             │
│  STEP 2: Generate random CEK (Content Encryption Key)                                      │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│  cek = SecureRandom.generate(256 bits)  // 32 bytes                                        │
│                                                                                             │
│  STEP 3: Generate random IV (Initialization Vector)                                        │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│  iv = SecureRandom.generate(96 bits)   // 12 bytes                                         │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 4: ENCRYPT-AES (AES-256-GCM) - Encrypt DEK using CEK                                 │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌───────────────────────┐                                                              │
│      │ aesDataEncryptionKey  │────┐                                                         │
│      │ (32 bytes)            │    │                                                         │
│      └───────────────────────┘    │        ┌─────────────────────────────────────────────┐  │
│                                   │        │                                             │  │
│      ┌───────────────────────┐    │        │            AES-256-GCM ENCRYPT              │  │
│      │        cek            │────┼───────►│                                             │  │
│      │ (32 bytes)            │    │        │  Cipher cipher = Cipher.getInstance(        │  │
│      └───────────────────────┘    │        │      "AES/GCM/NoPadding");                  │  │
│                                   │        │  cipher.init(ENCRYPT_MODE, cek, iv);        │  │
│      ┌───────────────────────┐    │        │  cipher.updateAAD(BASE64URL(header));       │  │
│      │         iv            │────┼───────►│  result = cipher.doFinal(                   │  │
│      │ (12 bytes)            │    │        │      aesDataEncryptionKey.getEncoded());    │  │
│      └───────────────────────┘    │        │                                             │  │
│                                   │        └──────────────────────┬──────────────────────┘  │
│      ┌───────────────────────┐    │                               │                         │
│      │    header (AAD)       │────┘                               ▼                         │
│      │ {"alg":"RSA-OAEP-256" │              ┌─────────────────────────────────────────────┐ │
│      │  "enc":"A256GCM"...}  │              │ ciphertext (encryptedAesDataEncryptionKey)  │ │
│      └───────────────────────┘              │ = 32 bytes                                  │ │
│                                             ├─────────────────────────────────────────────┤ │
│                                             │ authTag = 16 bytes                         │ │
│                                             └─────────────────────────────────────────────┘ │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 5: ENCRYPT-RSA (RSA-OAEP-256) - Encrypt CEK using RSA public key                     │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌───────────────────────┐              ┌─────────────────────────────────────────────┐ │
│      │        cek            │              │                                             │ │
│      │ (32 bytes)            │─────────────►│           RSA-OAEP-256 ENCRYPT              │ │
│      └───────────────────────┘              │                                             │ │
│                                             │  Cipher cipher = Cipher.getInstance(        │ │
│      ┌───────────────────────┐              │      "RSA/ECB/OAEPWithSHA-256...");         │ │
│      │    rsaPublicKey       │─────────────►│  cipher.init(ENCRYPT_MODE, rsaPublicKey);   │ │
│      │ (RSA-4096)            │              │  result = cipher.doFinal(cek);              │ │
│      └───────────────────────┘              │                                             │ │
│                                             └──────────────────────┬──────────────────────┘ │
│                                                                    │                        │
│                                                                    ▼                        │
│                                             ┌─────────────────────────────────────────────┐ │
│                                             │ encryptedKey (encryptedCek)                 │ │
│                                             │ = ~512 bytes                                │ │
│                                             └─────────────────────────────────────────────┘ │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 6: Combine into JWE Compact Serialization                                            │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│  jwe = BASE64URL(header) + "." +                                                           │
│        BASE64URL(encryptedKey i.e. encryptedCek) + "." +                                   │
│        BASE64URL(iv) + "." +                                                               │
│        BASE64URL(ciphertext i.e. encryptedAesDataEncryptionKey) + "." +                    │
│        BASE64URL(authTag)                                                                  │
│                                                                                             │
│  OUTPUT                                                                                     │
│  └── JWE string (~750 characters)                                                          │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

**CLIENT Step 3 Summary:**

| Operation      | Algorithm       | Input                             | Output                                      |
|----------------|-----------------|-----------------------------------|---------------------------------------------|
| ENCRYPT-AES    | AES-256-GCM     | cek, iv, aesDataEncryptionKey,    | ciphertext (encryptedAesDataEncryptionKey)  |
|                |                 | header (AAD)                      | + authTag                                   |
| ENCRYPT-RSA    | RSA-OAEP-256    | rsaPublicKey, cek                 | encryptedKey (encryptedCek)                 |

**Sample JWE Output:**
```
eyJhbGciOiJSU0EtT0FFUC0yNTYiLCJlbmMiOiJBMjU2R0NNIiwiY3R5IjoiSldFIn0.X9Mz1kLp...7Yw2qA.qlGBvpTz8scgIg.S2Hf9mNp...8xKw.3pLLqgTg_bJf6pw7eanSpQ
└──────────────────────────────────────────────────────┘ └─────────────────┘ └──────────────┘ └─────────────────┘ └────────────────────┘
                    Header (82B)                         EncryptedKey(~512B)     IV (12B)      Ciphertext (32B)      AuthTag (16B)
                                                         (encryptedCek)                    (encryptedAesDEK)
```

---

## CLIENT: Step 4 Details - Field Encryption

When `fieldEncryptor.encrypt()` is called:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  INPUT                                                                                      │
│  ├── plainText: "1990-05-15" (or any sensitive PII data)                                   │
│  └── aesDataEncryptionKey (DEK): 32 bytes (256-bit AES key)                                │
│                                                                                             │
│  STEP 1: Generate random IV (Initialization Vector)                                        │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│  iv = SecureRandom.generate(96 bits)  // 12 bytes                                          │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 2: ENCRYPT-AES (AES-256-GCM) - Encrypt plainText using DEK                           │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌───────────────────────┐                                                              │
│      │      plainText        │────┐                                                         │
│      │ "1990-05-15"          │    │                                                         │
│      └───────────────────────┘    │        ┌─────────────────────────────────────────────┐  │
│                                   │        │                                             │  │
│      ┌───────────────────────┐    │        │            AES-256-GCM ENCRYPT              │  │
│      │ aesDataEncryptionKey  │────┼───────►│                                             │  │
│      │ (DEK - 32 bytes)      │    │        │  Cipher cipher = Cipher.getInstance(        │  │
│      └───────────────────────┘    │        │      "AES/GCM/NoPadding");                  │  │
│                                   │        │  cipher.init(ENCRYPT_MODE, dek, iv);        │  │
│      ┌───────────────────────┐    │        │  result = cipher.doFinal(                   │  │
│      │         iv            │────┼───────►│      plainText.getBytes());                 │  │
│      │ (12 bytes)            │    │        │                                             │  │
│      └───────────────────────┘    │        └──────────────────────┬──────────────────────┘  │
│                                   │                               │                         │
│                                   │                               ▼                         │
│                                   │        ┌─────────────────────────────────────────────┐  │
│                                   │        │ encryptedText = variable size               │  │
│                                   │        │ (same size as plainText)                    │  │
│                                   │        ├─────────────────────────────────────────────┤  │
│                                   │        │ authTag = 16 bytes                          │  │
│                                   │        │ (for integrity validation during decrypt)   │  │
│                                   │        └─────────────────────────────────────────────┘  │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 3: Combine into dot-separated format                                                 │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│  output = BASE64(iv) + "." + BASE64(encryptedText) + "." + BASE64(authTag)                 │
│                                                                                             │
│  OUTPUT                                                                                     │
│  └── "rK8xMzQ1Njc4OTAx.YWJjZGVmZ2hpamts...eXo=.dGFnMTIzNDU2Nzg5MDEyMzQ1Ng=="              │
│       └───────────────┘ └────────────────────────┘ └──────────────────────────────┘        │
│           IV (12B)          EncryptedText              AuthTag (16B)                       │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

**CLIENT Step 4 Summary:**

| Operation      | Algorithm       | Input                             | Output                       |
|----------------|-----------------|-----------------------------------|------------------------------|
| ENCRYPT-AES    | AES-256-GCM     | aesDataEncryptionKey (DEK),       | encryptedText + authTag      |
|                |                 | iv, plainText                     |                              |

---

## SERVER: Step 5 Details - JWE Parsing

When `jweParser.extractJweComponents()` is called:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  INPUT                                                                                      │
│  └── jweEncryptionMetadata: JWE string from X-Encryption-Key header                        │
│                                                                                             │
│  STEP 1: Parse JWE Compact Serialization                                                   │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│  JWE Format: Header.EncryptedKey.IV.Ciphertext.AuthTag                                     │
│                │         │        │      │         │                                        │
│                │         │        │      │         └── NOT encrypted (Base64URL encoded)   │
│                │         │        │      └── ENCRYPTED (DEK encrypted with CEK)            │
│                │         │        └── NOT encrypted (Base64URL encoded)                    │
│                │         └── ENCRYPTED (CEK encrypted with RSA public key)                 │
│                └── NOT ENCRYPTED (Base64URL encoded, anyone can read!)                     │
│                                                                                             │
│  STEP 2: Validate Algorithm                                                                │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│  header.algorithm == "RSA-OAEP-256" ? ✓ : throw IllegalArgumentException                   │
│                                                                                             │
│  STEP 3: Extract Components                                                                │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌───────────────────────────────────────────────────────────────────────────────────┐  │
│      │  jweObject = JWEObject.parse(jweEncryptionMetadata)                               │  │
│      │                                                                                   │  │
│      │  encryptedCek                    = jweObject.getEncryptedKey().decode()           │  │
│      │  iv                              = jweObject.getIV().decode()                     │  │
│      │  encryptedAesDataEncryptionKey   = jweObject.getCipherText().decode()             │  │
│      │  authTag                         = jweObject.getAuthTag().decode()                │  │
│      │  aad                             = protectedHeader.getBytes(US_ASCII)             │  │
│      └───────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                             │
│  OUTPUT                                                                                     │
│  └── JweComponents record containing:                                                      │
│      ├── encryptedCek: ~512 bytes (RSA-encrypted CEK)                                      │
│      ├── iv: 12 bytes                                                                      │
│      ├── encryptedAesDataEncryptionKey: 32 bytes (AES-encrypted DEK)                       │
│      ├── authTag: 16 bytes                                                                 │
│      └── aad: ASCII bytes of Base64URL header (for GCM authentication)                     │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

**SERVER Step 5 Summary:**

| Component                      | Size       | Description                                      |
|--------------------------------|------------|--------------------------------------------------|
| encryptedCek                   | ~512 bytes | RSA-OAEP-256 encrypted CEK (decrypt via KMS)     |
| iv                             | 12 bytes   | Initialization Vector for AES-GCM                |
| encryptedAesDataEncryptionKey  | 32 bytes   | AES-GCM encrypted DEK (ciphertext)               |
| authTag                        | 16 bytes   | GCM authentication tag                           |
| aad                            | variable   | Additional Authenticated Data (header bytes)     |

---

## SERVER: Step 6 Details - Extract DEK via AWS KMS

When `awsKmsDecryptionService.extractAesDataEncryptionKey()` is called:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  INPUT                                                                                      │
│  └── JweComponents: encryptedCek, iv, encryptedAesDataEncryptionKey, authTag, aad          │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 6a: DECRYPT-RSA (RSA-OAEP-256 via AWS KMS) - Decrypt CEK                             │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌───────────────────────┐              ┌─────────────────────────────────────────────┐ │
│      │    encryptedCek       │              │                                             │ │
│      │ (~512 bytes)          │─────────────►│              AWS KMS                        │ │
│      └───────────────────────┘              │                                             │ │
│                                             │  DecryptRequest:                            │ │
│      ┌───────────────────────┐              │    keyId = keyArn                           │ │
│      │      keyArn           │─────────────►│    ciphertextBlob = encryptedCek            │ │
│      │ (KMS key reference)   │              │    algorithm = RSAES_OAEP_SHA_256           │ │
│      └───────────────────────┘              │                                             │ │
│                                             │  ┌─────────────────────────────────────┐    │ │
│                                             │  │ RSA Private Key (NEVER leaves HSM) │    │ │
│                                             │  └─────────────────────────────────────┘    │ │
│                                             │                                             │ │
│                                             └──────────────────────┬──────────────────────┘ │
│                                                                    │                        │
│                                                                    ▼                        │
│                                             ┌─────────────────────────────────────────────┐ │
│                                             │ cek = 32 bytes (Content Encryption Key)    │ │
│                                             └─────────────────────────────────────────────┘ │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 6b: DECRYPT-AES (AES-256-GCM locally) - Decrypt DEK using CEK                        │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌─────────────────────────────────┐                                                    │
│      │ encryptedAesDataEncryptionKey   │────┐                                               │
│      │ (32 bytes)                      │    │                                               │
│      └─────────────────────────────────┘    │  ┌─────────────────────────────────────────┐  │
│                                             │  │                                         │  │
│      ┌───────────────────────┐              │  │          AES-256-GCM DECRYPT            │  │
│      │        cek            │──────────────┼─►│                                         │  │
│      │ (32 bytes)            │              │  │  Cipher cipher = Cipher.getInstance(    │  │
│      └───────────────────────┘              │  │      "AES/GCM/NoPadding");              │  │
│                                             │  │  cipher.init(DECRYPT_MODE, cek, iv);    │  │
│      ┌───────────────────────┐              │  │  cipher.updateAAD(aad);  // CRITICAL!   │  │
│      │         iv            │──────────────┼─►│  result = cipher.doFinal(               │  │
│      │ (12 bytes)            │              │  │      encryptedAesDEK + authTag);        │  │
│      └───────────────────────┘              │  │                                         │  │
│                                             │  └──────────────────────┬──────────────────┘  │
│      ┌───────────────────────┐              │                         │                     │
│      │       authTag         │──────────────┤                         │                     │
│      │ (16 bytes)            │              │                         │                     │
│      └───────────────────────┘              │                         │                     │
│                                             │                         │                     │
│      ┌───────────────────────┐              │                         │                     │
│      │    aad (header)       │──────────────┘                         │                     │
│      └───────────────────────┘                                        │                     │
│                                                                       ▼                     │
│                                             ┌─────────────────────────────────────────────┐ │
│                                             │ aesDataEncryptionKey (DEK) = 32 bytes       │ │
│                                             │ (used for field decryption in Step 7)       │ │
│                                             └─────────────────────────────────────────────┘ │
│                                                                                             │
│  OUTPUT                                                                                     │
│  └── SecretKey (aesDataEncryptionKey) - 256-bit AES key for field decryption              │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

**SERVER Step 6 Summary:**

| Operation      | Algorithm       | Input                                   | Output                       |
|----------------|-----------------|----------------------------------------|------------------------------|
| DECRYPT-RSA    | RSA-OAEP-256    | encryptedCek, keyArn (via AWS KMS)     | cek (Content Encryption Key) |
| DECRYPT-AES    | AES-256-GCM     | cek, iv, encryptedAesDataEncryptionKey,| aesDataEncryptionKey (DEK)   |
|                |                 | authTag, aad                           |                              |

**NOTE:** This is the ONLY KMS API call per request!

---

## SERVER: Step 7 Details - Field Decryption

When `fieldDecryptor.decrypt()` is called:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  INPUT                                                                                      │
│  ├── encryptedField: "BASE64(IV).BASE64(EncryptedText).BASE64(AuthTag)"                    │
│  └── aesDataEncryptionKey (DEK): 32 bytes (extracted in Step 6)                            │
│                                                                                             │
│  STEP 1: Parse encrypted field                                                             │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│  parts = encryptedField.split(".")                                                         │
│  iv            = Base64.decode(parts[0])  // 12 bytes                                      │
│  encryptedText = Base64.decode(parts[1])  // variable size                                 │
│  authTag       = Base64.decode(parts[2])  // 16 bytes                                      │
│                                                                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│  STEP 2: DECRYPT-AES (AES-256-GCM) - Decrypt field using DEK                               │
│  ─────────────────────────────────────────────────────────────────────────────────────────  │
│                                                                                             │
│      ┌───────────────────────┐                                                              │
│      │    encryptedText      │────┐                                                         │
│      │ (variable size)       │    │                                                         │
│      └───────────────────────┘    │        ┌─────────────────────────────────────────────┐  │
│                                   │        │                                             │  │
│      ┌───────────────────────┐    │        │            AES-256-GCM DECRYPT              │  │
│      │ aesDataEncryptionKey  │────┼───────►│                                             │  │
│      │ (DEK - 32 bytes)      │    │        │  Cipher cipher = Cipher.getInstance(        │  │
│      └───────────────────────┘    │        │      "AES/GCM/NoPadding");                  │  │
│                                   │        │  cipher.init(DECRYPT_MODE, dek, iv);        │  │
│      ┌───────────────────────┐    │        │  plainText = cipher.doFinal(                │  │
│      │         iv            │────┼───────►│      encryptedText + authTag);              │  │
│      │ (12 bytes)            │    │        │                                             │  │
│      └───────────────────────┘    │        │  // authTag validates data integrity        │  │
│                                   │        │  // Throws exception if tampered!           │  │
│      ┌───────────────────────┐    │        │                                             │  │
│      │       authTag         │────┘        └──────────────────────┬──────────────────────┘  │
│      │ (16 bytes)            │                                    │                         │
│      └───────────────────────┘                                    │                         │
│                                                                   ▼                         │
│                                             ┌─────────────────────────────────────────────┐ │
│                                             │ plainText = "1990-05-15"                    │ │
│                                             │ (or credit card, SSN, etc.)                 │ │
│                                             └─────────────────────────────────────────────┘ │
│                                                                                             │
│  OUTPUT                                                                                     │
│  └── String (plainText) - the decrypted PII value                                          │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

**SERVER Step 7 Summary:**

| Operation      | Algorithm       | Input                             | Output                       |
|----------------|-----------------|-----------------------------------|------------------------------|
| DECRYPT-AES    | AES-256-GCM     | aesDataEncryptionKey (DEK),       | plainText                    |
|                |                 | iv, encryptedText, authTag        |                              |

**Sample Decryption:**
```
Input:  "rK8xMzQ1Njc4OTAx.YWJjZGVmZ2hpamts...eXo=.dGFnMTIzNDU2Nzg5MDEyMzQ1Ng=="
         └───────────────┘ └────────────────────────┘ └──────────────────────────────┘
              IV (12B)          EncryptedText              AuthTag (16B)

Output: "1990-05-15"
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

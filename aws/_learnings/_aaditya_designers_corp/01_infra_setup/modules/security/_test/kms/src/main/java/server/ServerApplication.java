package server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Server Application - Backend for 3rd Party REST API Integration
 *
 * <h2>Packages:</h2>
 * <ul>
 *   <li><b>restapi</b> - PII data protection for REST API payloads</li>
 *   <li><b>file_security</b> - File encryption/decryption (coming soon)</li>
 * </ul>
 *
 * <h2>REST API Security Flow (3rd Party WITHOUT AWS Account):</h2>
 * <pre>
 * ┌─────────────────────────────────────────────────────────────────────────┐
 * │                     HYBRID ENCRYPTION FLOW                             │
 * ├─────────────────────────────────────────────────────────────────────────┤
 * │                                                                         │
 * │  CLIENT (No AWS SDK)                SERVER                  AWS KMS    │
 * │  ══════════════════                 ══════                  ═══════    │
 * │                                                                         │
 * │  ┌──────────────────────────────────────────────────────────────────┐  │
 * │  │ STEP 1: Load Public Key                                          │  │
 * │  │ ► HybridEncryptionHelper.loadPublicKeyFromResources()            │  │
 * │  │   Loads RSA-4096 public key from resources                       │  │
 * │  └──────────────────────────────────────────────────────────────────┘  │
 * │                                                                         │
 * │  ┌──────────────────────────────────────────────────────────────────┐  │
 * │  │ STEP 2: Generate Encryption Key (DEK)                            │  │
 * │  │ ► FieldEncryptor.generateKey()                                   │  │
 * │  │   Creates random 256-bit AES key                                 │  │
 * │  └──────────────────────────────────────────────────────────────────┘  │
 * │                                                                         │
 * │  ┌──────────────────────────────────────────────────────────────────┐  │
 * │  │ STEP 3: Wrap DEK for Transport                                   │  │
 * │  │ ► JweBuilder.wrapKey(dek, publicKey)                             │  │
 * │  │   Wraps DEK in JWE using RSA-OAEP-256                            │  │
 * │  └──────────────────────────────────────────────────────────────────┘  │
 * │                                                                         │
 * │  ┌──────────────────────────────────────────────────────────────────┐  │
 * │  │ STEP 4: Encrypt PII Fields                                       │  │
 * │  │ ► FieldEncryptor.encrypt(plaintext, dek)                         │  │
 * │  │   Encrypts each field with AES-256-GCM → iv.ciphertext.authTag   │  │
 * │  └──────────────────────────────────────────────────────────────────┘  │
 * │                                                                         │
 * │  ────── HTTP Request ──────────────────────────────────────────────►   │
 * │  Header: X-Encryption-Key: {JWE}                                       │
 * │  Body:   {"dateOfBirth":"abc.xyz.123", "cardDetails":{...}}            │
 * │                                                                         │
 * │                          ┌──────────────────────────────────────────┐  │
 * │                          │ STEP 5: Extract Encrypted Key            │  │
 * │                          │ ► JweParser.extractEncryptedKey(jwe)     │  │
 * │                          │   Parses JWE, extracts RSA-encrypted DEK │  │
 * │                          └──────────────────────────────────────────┘  │
 * │                                                                         │
 * │                          ┌──────────────────────────────────────────┐  │
 * │                          │ STEP 6: Unwrap DEK via KMS (1 API Call)  │──┼──►
 * │                          │ ► KmsKeyUnwrapper.unwrap(encryptedKey)   │  │
 * │                          │   KMS decrypts using private RSA key    │◄─┼──
 * │                          └──────────────────────────────────────────┘  │
 * │                                                                         │
 * │                          ┌──────────────────────────────────────────┐  │
 * │                          │ STEP 7: Decrypt PII Fields (Local)       │  │
 * │                          │ ► FieldDecryptor.decrypt(encrypted, dek) │  │
 * │                          │   Decrypts each field with AES-256-GCM   │  │
 * │                          └──────────────────────────────────────────┘  │
 * │                                                                         │
 * │  ◄───── HTTP Response ─────────────────────────────────────────────    │
 * │  Body: {"success":true, "orderId":"ORD-123", ...masked data...}        │
 * │                                                                         │
 * └─────────────────────────────────────────────────────────────────────────┘
 * </pre>
 */
@SpringBootApplication
public class ServerApplication {

  public static void main(String[] args) {
    SpringApplication.run(ServerApplication.class, args);
  }
}

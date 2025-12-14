package com.thirdparty.client.crypto;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.Cipher;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;

/**
 * RSA Encryption for DEK
 *
 * Uses standard Java crypto (NO AWS SDK).
 * Encrypts the DEK using the company's public key.
 *
 * Algorithm: RSA-OAEP with SHA-256 (matches KMS RSAES_OAEP_SHA_256)
 */
public class RsaEncryptor {

    private static final Logger log = LoggerFactory.getLogger(RsaEncryptor.class);

    private PublicKey publicKey;

    /**
     * Load public key from PEM format
     *
     * @param pemKey PEM-encoded public key from company API
     */
    public void loadPublicKey(String pemKey) throws Exception {
        log.debug("Loading public key from PEM format");

        // Remove PEM headers and whitespace
        String base64Key = pemKey
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s", "");

        // Decode and create PublicKey
        byte[] keyBytes = Base64.getDecoder().decode(base64Key);
        X509EncodedKeySpec spec = new X509EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        this.publicKey = keyFactory.generatePublic(spec);

        log.info("Public key loaded successfully. Algorithm: {}, Format: {}",
                publicKey.getAlgorithm(), publicKey.getFormat());
    }

    /**
     * Encrypt DEK using RSA-OAEP with SHA-256
     * This matches KMS encryption algorithm: RSAES_OAEP_SHA_256
     *
     * @param dek Data Encryption Key to encrypt
     * @return Encrypted DEK (Base64 encoded)
     */
    public String encryptDek(byte[] dek) throws Exception {
        if (publicKey == null) {
            throw new IllegalStateException("Public key not loaded. Call loadPublicKey() first.");
        }

        log.debug("Encrypting DEK ({} bytes) with RSA-OAEP-SHA256", dek.length);

        // Configure RSA-OAEP with SHA-256 (must match KMS algorithm)
        OAEPParameterSpec oaepParams = new OAEPParameterSpec(
                "SHA-256",
                "MGF1",
                MGF1ParameterSpec.SHA256,
                PSource.PSpecified.DEFAULT
        );

        Cipher cipher = Cipher.getInstance("RSA/ECB/OAEPWithSHA-256AndMGF1Padding");
        cipher.init(Cipher.ENCRYPT_MODE, publicKey, oaepParams);

        byte[] encryptedDek = cipher.doFinal(dek);

        log.debug("DEK encrypted successfully. Encrypted size: {} bytes", encryptedDek.length);

        return Base64.getEncoder().encodeToString(encryptedDek);
    }
}

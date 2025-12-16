package client_no_aws.crypto;

import javax.crypto.Cipher;
import javax.crypto.spec.OAEPParameterSpec;
import javax.crypto.spec.PSource;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.MGF1ParameterSpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/**
 * RSA Encryption for DEK (Test Helper)
 *
 * Uses standard Java crypto (NO AWS SDK).
 * Encrypts the DEK using the company's public key.
 *
 * Algorithm: RSA-OAEP with SHA-256 (matches KMS RSAES_OAEP_SHA_256)
 */
public class RsaEncryptor {

    private static final String PUBLIC_KEY_RESOURCE = "/public-key.pem";

    private PublicKey publicKey;

    /**
     * Load public key from PEM file in resources folder
     *
     * @throws IOException if file cannot be read
     */
    public void loadPublicKeyFromResources() throws Exception {
        try (InputStream is = getClass().getResourceAsStream(PUBLIC_KEY_RESOURCE)) {
            if (is == null) {
                throw new IOException("Public key file not found: " + PUBLIC_KEY_RESOURCE +
                        "\nPlease download the public key from AWS KMS and place it in src/test/resources/public-key.pem");
            }
            String pemKey = new String(is.readAllBytes(), StandardCharsets.UTF_8);
            loadPublicKey(pemKey);
        }
    }

    /**
     * Load public key from PEM format string
     *
     * @param pemKey PEM-encoded public key
     */
    public void loadPublicKey(String pemKey) throws Exception {
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
            throw new IllegalStateException("Public key not loaded. Call loadPublicKeyFromResources() first.");
        }

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

        return Base64.getEncoder().encodeToString(encryptedDek);
    }
}

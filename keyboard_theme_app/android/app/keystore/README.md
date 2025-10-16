# Keystore Directory

This directory contains the JKS (Java KeyStore) files for signing your Android app releases.

## Files

Each flavor should have its own keystore file:

- `kedehun.jks` - Keystore for K-POP DEMON HUNTERS brand
- `aespa_winter.jks` - Keystore for Aespa Winter brand (to be generated)
- `aespa_karina.jks` - Keystore for Aespa Karina brand (to be generated)

## Generating a New Keystore

To generate a new keystore for a flavor, use the following command:

```bash
keytool -genkey -v -keystore aespa_winter.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Replace `aespa_winter.jks` with the appropriate filename for your flavor.

## Important Notes

- **NEVER commit these files to version control!**
- Keep these files in a secure location
- Back up these files - you cannot publish app updates without them
- The keystore directory is already added to `.gitignore`

## Configuration

After generating a keystore, create a corresponding properties file in the `android/` directory:

Example for `android/key_aespa_winter.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=keystore/aespa_winter.jks
```

## Security Best Practices

1. Use strong, unique passwords for each keystore
2. Store passwords securely (use a password manager)
3. Never share keystores or passwords in chat, email, or version control
4. Consider using environment variables for CI/CD pipelines

# Release signing (Android)

Release builds are signed with a keystore read from `android/key.properties`.
Both that file and the `.jks` are git-ignored.

## One-time setup

```bash
./tool/create_release_keystore.sh
```

It asks for a password, creates `android/app/upload-keystore.jks` and writes
`android/key.properties` (template: `android/key.properties.example`).

**Back both up** (password manager and an offline copy). Lose the keystore and
you cannot ship updates under the same listing.

## Building

```bash
flutter build appbundle --release   # Play Store
flutter build apk --release         # sideload
```

Without `android/key.properties` the release build falls back to the **debug**
key and prints a warning. Never upload that build.

## Play App Signing

Enrol in Play App Signing when creating the app; the key above is then the
*upload* key and Google holds the real app-signing key, so a lost upload key
can be reset through Play support.

## CI

See `docs/ci.md` - the `Release (Android)` workflow restores the keystore from
GitHub secrets and builds the signed APK/AAB.

## Verify

```bash
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```
The signer should be `CN=NativeSpend`, not `Android Debug`. (`keytool
-printcert -jarfile` cannot read v2/v3 signatures.)

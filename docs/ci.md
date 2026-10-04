# CI & release builds (GitHub Actions)

## `CI` (`.github/workflows/ci.yml`)
Runs on every push to `main` and every pull request:

1. `flutter pub get`
2. Checks `lib/core/rules/bundled_rules.g.dart` is in sync with `rules/rules.bundled.json`
   (if it fails: `dart run tool/gen_bundled_rules.dart` and commit)
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk --debug` (catches Gradle / plugin problems early)

No secrets needed.

## `Release (Android)` (`.github/workflows/release-android.yml`)
Builds a **signed** release APK and Play Store bundle (`.aab`), checks the APK
is not debug-signed, and attaches both as a downloadable artifact (30 days).
Run it by pushing a tag (`git tag v1.0.0 && git push origin v1.0.0`) or from
Actions -> Release (Android) -> Run workflow.

### One-time secrets
Repo -> Settings -> Secrets and variables -> Actions, or with the GitHub CLI
from the project root:

```bash
base64 -i android/app/upload-keystore.jks | gh secret set ANDROID_KEYSTORE_BASE64
gh secret set ANDROID_STORE_PASSWORD   # prompts for the value
gh secret set ANDROID_KEY_PASSWORD
gh secret set ANDROID_KEY_ALIAS        # upload
```

The repository is public: secrets are never printed in logs, but never put the
keystore or `key.properties` in the repo (both are git-ignored).

## Versions
Flutter is pinned (`FLUTTER_VERSION` in both workflows) so builds match local
ones; bump it deliberately. Android builds use Java 17.

## Not covered
iOS builds (they need Apple signing certificates and a macOS runner).

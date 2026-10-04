#!/usr/bin/env bash
# Creates the Android release keystore and android/key.properties.
# Run once:  ./tool/create_release_keystore.sh
# You choose the passwords; they are only written to the git-ignored key.properties.
set -euo pipefail

cd "$(dirname "$0")/.."
KEYSTORE="android/app/upload-keystore.jks"
PROPS="android/key.properties"
ALIAS="upload"

if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "Refusing to overwrite an existing $KEYSTORE or $PROPS." >&2
  exit 1
fi
command -v keytool >/dev/null || { echo "keytool not found (install a JDK)." >&2; exit 1; }

read -r -s -p "Choose a keystore/key password (min 6 chars): " PASS; echo
read -r -s -p "Repeat it: " PASS2; echo
[[ "$PASS" == "$PASS2" && ${#PASS} -ge 6 ]] || { echo "Passwords differ or are too short." >&2; exit 1; }

keytool -genkeypair -v -keystore "$KEYSTORE" -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=NativeSpend, O=NativeSpend, C=IN"

umask 077
cat > "$PROPS" <<PROPS_EOF
storePassword=$PASS
keyPassword=$PASS
keyAlias=$ALIAS
storeFile=upload-keystore.jks
PROPS_EOF

echo
echo "Created $KEYSTORE and $PROPS (both git-ignored)."
echo "BACK THEM UP NOW (password manager + an offline copy). If the keystore is"
echo "lost you cannot publish updates to the same app. Then build with:"
echo "  flutter build appbundle --release"

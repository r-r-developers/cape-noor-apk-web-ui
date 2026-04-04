#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/development/side-projects/salaah-time-fast-duah/flutter"
KEY_PROPERTIES_PATH="$PROJECT_ROOT/android/key.properties"
EXPECTED_SHA1_DEFAULT="F5:1A:9F:EA:C8:3F:CE:2B:B9:8E:E7:78:9D:8F:80:A0:FC:62:B4:9B"

usage() {
  cat <<EOF
Usage:
  setup-play-signing.sh --keystore /abs/path/key.jks --alias keyAlias --store-pass STORE_PASS --key-pass KEY_PASS [--expected-sha1 SHA1]

Example:
  setup-play-signing.sh \\
    --keystore /home/user/upload-key.jks \\
    --alias upload \\
    --store-pass '***' \\
    --key-pass '***'
EOF
}

KEYSTORE=""
ALIAS=""
STORE_PASS=""
KEY_PASS=""
EXPECTED_SHA1="$EXPECTED_SHA1_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keystore) KEYSTORE="$2"; shift 2 ;;
    --alias) ALIAS="$2"; shift 2 ;;
    --store-pass) STORE_PASS="$2"; shift 2 ;;
    --key-pass) KEY_PASS="$2"; shift 2 ;;
    --expected-sha1) EXPECTED_SHA1="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

prompt_if_missing() {
  if [[ -z "$KEYSTORE" ]]; then
    read -r -p "Keystore path (.jks): " KEYSTORE
  fi
  if [[ -z "$ALIAS" ]]; then
    read -r -p "Key alias: " ALIAS
  fi
  if [[ -z "$STORE_PASS" ]]; then
    read -r -s -p "Store password: " STORE_PASS
    echo
  fi
  if [[ -z "$KEY_PASS" ]]; then
    read -r -s -p "Key password: " KEY_PASS
    echo
  fi
}

if [[ -z "$KEYSTORE" || -z "$ALIAS" || -z "$STORE_PASS" || -z "$KEY_PASS" ]]; then
  if [[ -t 0 ]]; then
    echo "Some signing inputs are missing. Enter them interactively."
    prompt_if_missing
  else
    echo "Missing required arguments."
    usage
    exit 1
  fi
fi

if [[ -z "$KEYSTORE" || -z "$ALIAS" || -z "$STORE_PASS" || -z "$KEY_PASS" ]]; then
  echo "Missing required arguments after prompt."
  usage
  exit 1
fi

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Keystore file not found: $KEYSTORE"
  exit 1
fi

SHA1_LINE=$(keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$STORE_PASS" -keypass "$KEY_PASS" 2>/dev/null | grep -m1 "SHA1:" || true)
if [[ -z "$SHA1_LINE" ]]; then
  echo "Could not read SHA1 from keystore. Check alias/passwords."
  exit 1
fi

ACTUAL_SHA1=$(echo "$SHA1_LINE" | sed -E 's/.*SHA1:[[:space:]]*//')

echo "Expected SHA1: $EXPECTED_SHA1"
echo "Actual SHA1:   $ACTUAL_SHA1"

if [[ "$ACTUAL_SHA1" != "$EXPECTED_SHA1" ]]; then
  echo "SHA1 mismatch. This is not the upload key Google Play expects."
  exit 1
fi

cat > "$KEY_PROPERTIES_PATH" <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=$KEYSTORE
EOF

chmod 600 "$KEY_PROPERTIES_PATH"

echo "Created $KEY_PROPERTIES_PATH"
echo "Now build with:"
echo "  cd $PROJECT_ROOT && flutter build appbundle --release --no-pub"

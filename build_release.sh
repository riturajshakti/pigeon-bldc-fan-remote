#!/bin/bash
set -e
cd "$(dirname "$0")"

VERSION_LINE=$(grep '^version:' pubspec.yaml | awk '{print $2}')
APP_VERSION="${VERSION_LINE%%+*}"
APP_BUILD="${VERSION_LINE##*+}"

echo "Building $APP_VERSION (build $APP_BUILD)"

flutter build apk --release --split-per-abi \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --dart-define=APP_BUILD="$APP_BUILD" \
  --obfuscate --split-debug-info=build/symbols \
  --extra-gen-snapshot-options=--strip

mkdir -p outputs
for abi in arm64-v8a armeabi-v7a x86_64; do
  cp "build/app/outputs/flutter-apk/app-$abi-release.apk" \
     "outputs/pigeon-fan-remote-$APP_VERSION-$abi.apk"
done

ls -la outputs/*.apk

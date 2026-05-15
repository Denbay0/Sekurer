#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is not installed or not available in PATH. Cannot generate android/ios project files."
  exit 1
fi

if [ ! -d "mobile" ]; then
  echo "mobile directory not found"
  exit 1
fi

cd mobile
flutter create --platforms=android,ios .
flutter pub get
dart format lib test
flutter analyze
flutter test

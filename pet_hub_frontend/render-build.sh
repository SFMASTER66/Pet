#!/usr/bin/env bash
# exit on error
set -o errexit

# 1. Clone Flutter SDK into a temporary directory
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web & fetch dependencies
flutter config --enable-web
flutter pub get

# 4. Build Flutter Web release
flutter build web --release
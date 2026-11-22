#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="${1:-$ROOT_DIR}"
BUILD_DIR=$(mktemp -d /tmp/taskmanager-build.XXXXXX)

echo "==> Building TaskManager in $BUILD_DIR..."

cd "$ROOT_DIR"

if command -v xcodegen >/dev/null 2>&1; then
    echo "==> Generating Xcode project with xcodegen..."
    xcodegen generate

    echo "==> Compiling with xcodebuild..."
    xcodebuild build \
        -project TaskManager.xcodeproj \
        -scheme TaskManager \
        -configuration Release \
        -sdk iphoneos \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        AD_HOC_CODE_SIGNING_ALLOWED=YES

    APP_PATH=$(find "$BUILD_DIR/DerivedData/Build/Products/Release-iphoneos" -name "TaskManager.app" -type d | head -n 1)
else
    echo "==> Compiling directly with swiftc for iOS arm64..."
    SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
    mkdir -p "$BUILD_DIR/Payload/TaskManager.app"
    APP_PATH="$BUILD_DIR/Payload/TaskManager.app"

    SWIFT_FILES=$(find "$ROOT_DIR/Sources" -name "*.swift")

    swiftc \
        -target arm64-apple-ios15.0 \
        -sdk "$SDK_PATH" \
        -O \
        $SWIFT_FILES \
        -emit-executable \
        -o "$APP_PATH/TaskManager"

    cp "$ROOT_DIR/Resources/Info.plist" "$APP_PATH/Info.plist"
fi

echo "==> Staging IPA Payload..."
mkdir -p "$BUILD_DIR/Payload"
cp -R "$APP_PATH" "$BUILD_DIR/Payload/TaskManager.app"

echo "==> Signing with TrollStore entitlements..."
if command -v ldid >/dev/null 2>&1; then
    ldid -S"$ROOT_DIR/Resources/entitlements.plist" "$BUILD_DIR/Payload/TaskManager.app/TaskManager"
fi

mkdir -p "$OUTPUT_DIR"
cd "$BUILD_DIR"

echo "==> Packaging .ipa and .tipa..."
zip -q -r9 "$OUTPUT_DIR/TaskManager.ipa" Payload
cp "$OUTPUT_DIR/TaskManager.ipa" "$OUTPUT_DIR/TaskManager.tipa"

echo "==> Packaging complete:"
ls -lh "$OUTPUT_DIR/TaskManager.ipa" "$OUTPUT_DIR/TaskManager.tipa"

rm -rf "$BUILD_DIR"
echo "==> Build successful!"

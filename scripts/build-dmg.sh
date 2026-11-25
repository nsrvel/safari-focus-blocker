#!/usr/bin/env bash
# macOS-only build script for Focus Blocker Safari Web Extension.
# DO NOT run this script on Linux (requires macOS, Xcode, xcrun, xcodebuild, and hdiutil).
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: scripts/build-dmg.sh is macOS-only and cannot run on $(uname -s)." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_DIR="${ROOT_DIR}/extension"
BUILD_DIR="${ROOT_DIR}/build"
XCODE_DIR="${BUILD_DIR}/xcode"
ARCHIVE_PATH="${BUILD_DIR}/FocusBlocker.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
DMG_STAGE="${BUILD_DIR}/dmg-stage"
DIST_DIR="${ROOT_DIR}/dist"
DMG_PATH="${DIST_DIR}/Focus-Blocker.dmg"

APP_NAME="Focus Blocker"
BUNDLE_ID="com.nsrvel.focus-blocker"

command -v xcrun >/dev/null 2>&1 || { echo "Error: xcrun not found (install Xcode)." >&2; exit 1; }
command -v xcodebuild >/dev/null 2>&1 || { echo "Error: xcodebuild not found (install Xcode)." >&2; exit 1; }
command -v hdiutil >/dev/null 2>&1 || { echo "Error: hdiutil not found." >&2; exit 1; }

rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${XCODE_DIR}" "${EXPORT_DIR}" "${DMG_STAGE}" "${DIST_DIR}"

echo "==> Converting Web Extension to Xcode project..."
xcrun safari-web-extension-converter "${EXT_DIR}" \
  --project-location "${XCODE_DIR}" \
  --app-name "${APP_NAME}" \
  --bundle-identifier "${BUNDLE_ID}" \
  --macos-only \
  --no-open \
  --force

XCODEPROJ="$(find "${XCODE_DIR}" -maxdepth 3 -name "*.xcodeproj" | head -n 1)"
if [[ -z "${XCODEPROJ}" ]]; then
  echo "Error: Generated .xcodeproj not found under ${XCODE_DIR}" >&2
  exit 1
fi

echo "==> Building macOS app with xcodebuild..."
xcodebuild \
  -project "${XCODEPROJ}" \
  -scheme "${APP_NAME}" \
  -configuration Release \
  -derivedDataPath "${BUILD_DIR}/derived" \
  CONFIGURATION_BUILD_DIR="${EXPORT_DIR}" \
  build

APP_PATH="$(find "${EXPORT_DIR}" -maxdepth 2 -name "*.app" | head -n 1)"
if [[ -z "${APP_PATH}" ]]; then
  echo "Error: Built .app bundle not found in ${EXPORT_DIR}" >&2
  exit 1
fi

echo "==> Packaging DMG..."
cp -R "${APP_PATH}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGE}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "==> Done: ${DMG_PATH}"

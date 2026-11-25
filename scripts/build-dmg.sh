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
BUNDLE_ID="com.nsrvel.Focus-Blocker"

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

SIGN_ARGS=()
if [[ -n "${CODE_SIGN_IDENTITY:-}" && -n "${DEVELOPMENT_TEAM:-}" ]]; then
  SIGN_ARGS=(
    "DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}"
    "CODE_SIGN_IDENTITY=${CODE_SIGN_IDENTITY}"
    "CODE_SIGN_STYLE=Manual"
  )
else
  DETECTED_NAME="$(security find-identity -v -p codesigning 2>/dev/null | sed -nE 's/.*"((Developer ID Application|Apple Development):[^"]*)".*/\1/p' | head -n 1 || true)"
  if [[ -n "${DETECTED_NAME}" ]]; then
    DETECTED_TEAM="$(security find-certificate -c "${DETECTED_NAME}" -p 2>/dev/null | openssl x509 -noout -subject 2>/dev/null | sed -nE 's/.*OU=([^,\/]*).*/\1/p' | head -n 1 || true)"
    if [[ -n "${DETECTED_TEAM}" ]]; then
      echo "==> Using signing identity: ${DETECTED_NAME} (Team: ${DETECTED_TEAM})"
      SIGN_ARGS=(
        "DEVELOPMENT_TEAM=${DETECTED_TEAM}"
        "CODE_SIGN_IDENTITY=${DETECTED_NAME}"
        "CODE_SIGN_STYLE=Manual"
      )
    fi
  fi
fi

echo "==> Building macOS app with xcodebuild..."
xcodebuild \
  -project "${XCODEPROJ}" \
  -scheme "${APP_NAME}" \
  -configuration Release \
  -derivedDataPath "${BUILD_DIR}/derived" \
  CONFIGURATION_BUILD_DIR="${EXPORT_DIR}" \
  ${SIGN_ARGS[@]+"${SIGN_ARGS[@]}"} \
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

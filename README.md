# Focus Blocker

An always-on Safari Web Extension (Manifest V3) that blocks **YouTube Shorts** and **TikTok**.

> **No toggle by design:** Focus Blocker is intentionally always on. There is no pause, snooze, or on/off switch.

## What It Blocks

- **YouTube Shorts**
  - Redirects `youtube.com/shorts/<VIDEO_ID>` (`www.` and `m.`) `main_frame` requests to `youtube.com/watch?v=<VIDEO_ID>` via `declarativeNetRequest` (`regexSubstitution`).
  - Handles in-page / SPA navigations (`yt-navigate-start`, `yt-navigate-finish`, `popstate`) at `document_start` in `extension/content-youtube.js`.
  - Injects CSS and a `MutationObserver` to hide Shorts shelves (`ytd-reel-shelf-renderer`, `ytd-rich-shelf-renderer`) and Shorts sidebar/guide entries.
- **TikTok**
  - Blocks `tiktok.com` `main_frame` requests via `declarativeNetRequest`.
  - Includes a `document_start` fallback in `extension/content-tiktok.js` that stops loading and replaces the page with `"diblokir oleh Focus Blocker"` if the network rule misses.

## Install Steps (macOS)

Building the Safari app wrapper and `.dmg` requires **macOS with Xcode** installed (`xcrun safari-web-extension-converter`, `xcodebuild`, `hdiutil`).

### Option 1: Build a `.dmg` with the script

```bash
chmod +x scripts/build-dmg.sh
./scripts/build-dmg.sh
```

This generates `dist/Focus-Blocker.dmg`. Open the DMG and drag **Focus Blocker.app** into **Applications**, then launch it once.

### Option 2: Open the generated Xcode project and Run

1. Convert the extension into an Xcode project on your Mac:
   ```bash
   xcrun safari-web-extension-converter extension/ --macos-only --app-name "Focus Blocker"
   ```
2. Open the generated `.xcodeproj` in Xcode and click **Run** (⌘R).

## Enable in Safari

1. Open **Safari** → **Settings…** (`⌘,`) → **Extensions**.
2. Check **Focus Blocker** to enable it.
3. Under permissions for **Focus Blocker**, grant access for `youtube.com` and `tiktok.com` (choose **Always Allow on Every Website** or allow both domains).
4. Note: Because Safari requires unsigned/development extensions to be allowed during testing, if you run from Xcode without signing, enable **Safari** → **Settings…** → **Advanced** → **Show features for web developers**, then **Develop** → **Allow Unsigned Extensions**.

## Repository Structure

```text
extension/
  manifest.json        # Manifest V3 config (always-on, no toggle)
  rules.json           # declarativeNetRequest rules for TikTok & Shorts
  content-youtube.js   # Shorts redirect + CSS/MutationObserver hiding
  content-tiktok.js    # Fallback page blocker ("diblokir oleh Focus Blocker")
  popup.html           # Static status popup (no toggle)
  icons/               # 16/32/48/128 PNG extension icons
assets/icons/          # 1024x1024 app icon + 16/32/48/128 PNG icons
scripts/build-dmg.sh   # macOS-only converter + xcodebuild + hdiutil script
```

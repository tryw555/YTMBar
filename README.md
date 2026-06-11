# YTMBar

YTMBar is a macOS menu bar player for YouTube Music. It keeps the current track, artist, album artwork, and playback controls in the menu bar, with a compact YouTube Music panel available when you need search, selection, or login.

> This project is not affiliated with YouTube, YouTube Music, or Google.

## Features

- Menu bar playback controls: previous, play/pause, next
- Three menu bar layouts:
  - Long: CD-style artwork, artist, title, previous/play/next
  - Medium: CD-style artwork, scrolling title/artist, previous/play/next
  - Compact: CD-style artwork, previous/play/next
- Rotating CD-style artwork while music is playing
- Hover preview with artwork, artist, and title
- Floating phone-sized YouTube Music panel for login, search, and playback selection
- macOS Now Playing integration
- Widget snapshot support through an app group
- `ytmbar://` URL commands for automation:
  - `ytmbar://open`
  - `ytmbar://previous`
  - `ytmbar://playpause`
  - `ytmbar://next`

## Download

Download the latest app from the GitHub Releases page.

Use `YTMBar-Xcode.app.zip` when available. It includes the app and widget extension from the Xcode build.

## Install

1. Download `YTMBar-Xcode.app.zip`.
2. Unzip it.
3. Move `YTMBar-Xcode.app` to `/Applications`.
4. Open the app.
5. Log in to YouTube Music in the small player panel.

Because current builds are ad-hoc signed and not notarized with an Apple Developer ID, macOS may block the first launch. If that happens:

1. Right-click the app.
2. Choose **Open**.
3. Confirm **Open** once.

For local testing, you can also remove quarantine:

```sh
xattr -dr com.apple.quarantine /Applications/YTMBar-Xcode.app
```

## Build From Source

Requirements:

- macOS 14 or later
- Xcode 26.5 or later
- Swift 6 toolchain
- XcodeGen

Install XcodeGen with Homebrew:

```sh
brew install xcodegen
```

Generate the Xcode project:

```sh
xcodegen generate
```

Build with Xcode:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project YTMBar.xcodeproj \
  -scheme YTMBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  build
```

You can also build the SwiftPM-only app bundle:

```sh
CONFIGURATION=debug scripts/build_app.sh
```

The SwiftPM bundle is useful for quick local testing. The Xcode build is recommended for widget-extension work.

## Privacy

YTMBar loads `https://music.youtube.com` in a local `WKWebView`. YouTube Music login is handled by WebKit on your Mac. The app does not run a separate server and does not intentionally transmit your playback data anywhere outside YouTube Music.

The app stores a local now-playing snapshot and artwork file in the app group container so the menu bar and widget can display the current track.

## Notes

- YouTube Music is a web app, so DOM or player changes on YouTube Music may require updates to YTMBar.
- Fully frictionless distribution on macOS requires Developer ID signing and notarization. The release zip in this repository is intended as a community/dev build.

## 한국어 안내

YTMBar는 macOS 메뉴막대에서 YouTube Music의 현재 곡, 가수, 앨범아트, 이전/재생/다음 버튼을 바로 보여주는 앱입니다. 작은 패널을 열면 YouTube Music 웹 화면에서 로그인, 검색, 곡 선택을 할 수 있습니다.

현재 릴리즈 빌드는 Apple Developer ID로 공증된 앱이 아니므로 처음 실행할 때 macOS가 막을 수 있습니다. 그 경우 앱을 우클릭한 뒤 **열기**를 선택하면 실행할 수 있습니다.

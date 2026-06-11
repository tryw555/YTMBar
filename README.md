# YTMBar

YTMBar is a macOS menu bar player for YouTube Music. It keeps the current track, artist, album artwork, and playback controls in the menu bar, with a compact YouTube Music panel available when you need search, selection, or login.

YTMBar는 macOS 메뉴막대에서 YouTube Music을 바로 제어할 수 있는 작은 플레이어입니다. 현재 재생 중인 곡, 가수, 앨범아트, 이전/재생/다음 버튼을 메뉴막대에 표시하고, 필요할 때 작은 YouTube Music 패널을 열어 로그인, 검색, 곡 선택을 할 수 있습니다.

> This project is not affiliated with YouTube, YouTube Music, or Google.
>
> 이 프로젝트는 YouTube, YouTube Music, Google과 공식적으로 관련이 없습니다.

## 한국어 빠른 안내

YTMBar는 YouTube Music을 자주 켜두는 macOS 사용자를 위한 메뉴막대 앱입니다. 브라우저나 큰 앱 창을 매번 열지 않아도 메뉴막대에서 바로 이전 곡, 재생/일시정지, 다음 곡을 누를 수 있고, 앨범아트와 곡 제목도 함께 확인할 수 있습니다.

주요 기능:

- 메뉴막대에서 이전 곡, 재생/일시정지, 다음 곡 제어
- 긴 버전, 보통 버전, 짧은 버전 3가지 메뉴막대 크기 지원
- 재생 중에는 CD처럼 회전하는 앨범아트
- 마우스를 올리면 현재 곡 정보 미리보기 표시
- 앨범아트나 곡 정보를 누르면 작은 YouTube Music 패널 열기
- 패널 안에서 YouTube Music 로그인, 검색, 곡 선택 가능
- macOS Now Playing 연동
- 위젯에서 현재 곡 정보를 볼 수 있도록 스냅샷 저장

설치 방법:

1. [Releases](https://github.com/tryw555/YTMBar/releases)에서 `YTMBar-Xcode.app.zip`을 받습니다.
2. 압축을 풉니다.
3. `YTMBar-Xcode.app`을 `/Applications` 폴더로 옮깁니다.
4. 앱을 실행합니다.
5. 작은 YouTube Music 패널에서 로그인합니다.

처음 실행할 때 macOS가 앱을 막을 수 있습니다. 현재 빌드는 Apple Developer ID로 공증된 앱이 아니기 때문입니다. 이 경우 앱을 우클릭한 뒤 **열기**를 선택하고 한 번 더 **열기**를 누르면 실행할 수 있습니다.

터미널로 격리 속성을 제거해 테스트할 수도 있습니다.

```sh
xattr -dr com.apple.quarantine /Applications/YTMBar-Xcode.app
```

주의사항:

- YouTube Music 웹 플레이어를 내부 `WKWebView`로 띄우는 방식입니다.
- YouTube Music 웹 화면 구조가 바뀌면 일부 제어 기능을 업데이트해야 할 수 있습니다.
- 경고 없이 자연스럽게 배포하려면 추후 Apple Developer ID 서명과 notarization이 필요합니다.

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

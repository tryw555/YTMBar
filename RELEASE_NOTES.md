# YTMBar 0.1.1

앱 아이콘을 추가한 배포 버전입니다.

## 한국어 요약

- macOS 앱 아이콘 추가
- Xcode 빌드용 `AppIcon` asset catalog 추가
- SwiftPM 간이 앱 번들용 `YTMBar.icns` 추가
- 앱과 위젯 버전을 `0.1.1`로 업데이트

## Highlights

- Added a custom macOS app icon
- Added an `AppIcon` asset catalog for Xcode builds
- Added `YTMBar.icns` for the SwiftPM app bundle
- Updated app and widget versions to `0.1.1`

## Previous Release: YTMBar 0.1.0

Initial public build.

첫 공개 배포 버전입니다.

## 한국어 요약

YTMBar 0.1.0은 macOS 메뉴막대에서 YouTube Music을 빠르게 제어할 수 있는 첫 공개 빌드입니다. 메뉴막대에서 현재 곡과 가수를 확인하고, 앨범아트와 이전/재생/다음 버튼으로 바로 조작할 수 있습니다.

### 주요 기능

- macOS 메뉴막대 YouTube Music 컨트롤
- 긴 버전, 보통 버전, 짧은 버전 3가지 표시 모드
- 재생 중 CD처럼 회전하는 앨범아트
- 마우스 hover 시 현재 곡 미리보기
- 로그인, 검색, 곡 선택을 위한 작은 YouTube Music 패널
- macOS Now Playing 연동
- 위젯 표시용 현재 곡 스냅샷 저장

### 알려진 제한

- 현재 앱은 ad-hoc 서명 상태이며 Apple 공증을 받지 않았습니다. 처음 실행할 때 macOS에서 우클릭 후 **열기**가 필요할 수 있습니다.
- YouTube Music 로그인과 재생은 내장 웹 플레이어에서 처리됩니다.
- YouTube Music 웹 UI가 바뀌면 일부 기능 업데이트가 필요할 수 있습니다.

## Highlights

- macOS menu bar YouTube Music controls
- Long, medium, and compact menu bar layouts
- CD-style artwork with playback animation
- Hover preview
- Floating YouTube Music panel
- Now Playing integration
- Widget snapshot support

## Known Limitations

- The app is ad-hoc signed and not notarized. macOS may require right-clicking the app and choosing **Open** on first launch.
- YouTube Music login and playback are handled by the embedded web player.
- YouTube Music web UI changes may require app updates.

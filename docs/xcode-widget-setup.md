# Xcode Project Notes

`YTMBar.xcodeproj` is generated from `project.yml` with XcodeGen.

Regenerate the project after changing targets or build settings:

```sh
xcodegen generate
```

## Targets

- `YTMBar`: macOS menu-bar app.
- `YTMBarWidgetExtension`: WidgetKit extension embedded in the app.
- `YTMBarShared`: shared framework used by the app and widget.

## Shared Data Flow

1. `YouTubeMusicViewController` observes YouTube Music playback state.
2. `PlayerPanelController` downloads the latest artwork.
3. `AppDelegate` updates the menu bar, Now Playing, and shared snapshot.
4. `NowPlayingSnapshotStore` writes JSON to the App Group container.
5. The WidgetKit timeline provider reads the same JSON and artwork file.

## App Group

Both app and widget use:

```text
group.com.ozwin.ytmbar
```

Entitlement baselines:

- `packaging/entitlements/YTMBar.entitlements`
- `packaging/entitlements/YTMBarWidget.entitlements`

For local command-line builds without an Apple team, use:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project YTMBar.xcodeproj \
  -scheme YTMBar \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Verification Checklist

- App launches as an accessory/menu-bar app.
- `YTMBar.app/Contents/PlugIns/YTMBarWidgetExtension.appex` exists.
- `ytmbar://open` opens the phone-sized player panel.
- YouTube Music login survives app relaunch.
- Menu-bar mode selection survives app relaunch.
- Current title, artist, playback state, and artwork update after track changes.
- Widget shows the latest title, artist, status, and artwork.

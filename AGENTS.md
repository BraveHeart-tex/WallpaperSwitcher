# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project Overview

WallpaperSwitcher is a small macOS SwiftUI menu bar app built for personal use. It has no Dock icon and runs as a status item utility. The main behavior is to keep separate light and dark wallpaper pools, apply the next wallpaper for the current macOS appearance, and optionally rotate wallpapers on a schedule.

## Code Layout

- `WallpaperSwitcher/WallpaperSwitcherApp.swift`
  - SwiftUI `@main` entry point.
  - Contains `AppDelegate`.
  - Creates `MenuBarController`.
  - Uses `AppearanceMonitor.shared`.
  - Applies the correct wallpaper on app launch.
- `WallpaperSwitcher/MenuBarController.swift`
  - Owns the `NSStatusItem` and menu actions.
  - Opens `SettingsView` in an `NSWindow` using `NSHostingController`.
  - The `Set wallpaper now` item should call `WallpaperCoordinator.shared.applyWallpaper(isDark:)`.
- `WallpaperSwitcher/SettingsView.swift`
  - SwiftUI settings UI.
  - Edits light and dark wallpaper URL arrays through `WallpaperCoordinator.shared`.
  - Contains rotation interval controls.
  - Uses `ServiceManagement` for launch-at-login.
- `WallpaperSwitcher/AppearanceMonitor.swift`
  - Singleton-style appearance monitor via `AppearanceMonitor.shared`.
  - Observes `AppleInterfaceThemeChangedNotification`.
  - Publishes `isDarkMode`.
- `WallpaperSwitcher/WallpaperCoordinator.swift`
  - Singleton via `WallpaperCoordinator.shared`.
  - Stores wallpaper URL arrays, rotation settings, and wallpaper indices.
  - Persists state in `UserDefaults`.
  - Applies wallpapers to all screens with `NSWorkspace`.
  - Attempts all-Spaces support by updating the Dock `desktoppicture.db` SQLite database and restarting Dock.

## Build Command

Use this command for verification:

```sh
xcodebuild -project WallpaperSwitcher.xcodeproj -scheme WallpaperSwitcher -configuration Debug -derivedDataPath ./.derivedData build
```

After running the build, remove `.derivedData` unless the user asks to keep it:

```sh
rm -rf .derivedData
```

The build may emit CoreSimulator warnings in sandboxed environments. Treat them as non-blocking if the macOS target still reports `BUILD SUCCEEDED`.

## Project Conventions

- Prefer AppKit APIs where the app interacts with menu bar, windows, wallpapers, or macOS system services.
- Keep state ownership in existing singletons:
  - Appearance state belongs in `AppearanceMonitor`.
  - Wallpaper lists, indices, rotation interval, and timer behavior belong in `WallpaperCoordinator`.
  - Menu bar actions belong in `MenuBarController`.
- Keep `SettingsView` focused on UI and write changes through `WallpaperCoordinator.shared`.
- Use `UserDefaults` for simple persisted app settings unless there is a clear reason to introduce another store.
- Do not edit `project.pbxproj` unless Xcode target membership or build settings require it. The project currently picks up Swift files placed under `WallpaperSwitcher/`.
- Avoid broad refactors. This is a small personal utility, so prefer straightforward code over abstractions that are not needed yet.

## macOS-Specific Notes

- `LSUIElement` is expected to be set in Info.plist/build settings so the app has no Dock icon.
- The menu bar icon uses the SF Symbol `photo.on.rectangle`.
- `ServiceManagement` login item changes should use `SMAppService.mainApp.register()` and `SMAppService.mainApp.unregister()`.
- All-Spaces wallpaper support touches `~/Library/Application Support/Dock/desktoppicture.db` and runs `killall Dock`. This depends on macOS internals and may break on future macOS versions.
- `NSWorkspace.shared.setDesktopImageURL(_:for:options:)` only affects detected screens/current behavior; keep the Dock database code separate and error-tolerant.

## Safety

- Do not run destructive commands like `git reset --hard` or `git checkout --` unless explicitly asked.
- Do not overwrite user changes. Check `git status --short` before and after edits.
- If changing wallpaper application behavior, keep failure paths non-fatal and log useful errors with `print`.
- Do not add network downloads or third-party dependencies without asking.

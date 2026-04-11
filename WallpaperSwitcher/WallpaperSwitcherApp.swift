//
//  WallpaperSwitcherApp.swift
//  WallpaperSwitcher
//
//  Created by Bora on 11.04.2026.
//

import SwiftUI

@main
struct WallpaperSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appearanceMonitor: AppearanceMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        appearanceMonitor = AppearanceMonitor { isDarkMode in
            let appearance = isDarkMode ? "dark" : "light"
            print("Appearance changed to: \(appearance)")
        }
    }
}

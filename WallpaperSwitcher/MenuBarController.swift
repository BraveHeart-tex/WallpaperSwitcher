//
//  MenuBarController.swift
//  WallpaperSwitcher
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import SwiftUI

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private var settingsWindow: NSWindow?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "photo.on.rectangle",
                accessibilityDescription: "Wallpaper Switcher"
            )
            image?.isTemplate = true

            button.image = image
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(
            title: "Set wallpaper now",
            action: #selector(setWallpaperNow),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        menu.items.forEach { $0.target = self }

        return menu
    }

    @objc private func setWallpaperNow() {
        WallpaperCoordinator.shared.applyWallpaper(isDark: AppearanceMonitor.shared.isDarkMode)
    }

    @objc private func openPreferences() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 760, height: 480))
        window.minSize = NSSize(width: 600, height: 400)
        window.isReleasedWhenClosed = false
        window.center()

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

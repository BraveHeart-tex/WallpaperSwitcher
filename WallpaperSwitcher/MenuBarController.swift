//
//  MenuBarController.swift
//  WallpaperSwitcher
//
//  Created by Bora on 11.04.2026.
//

import AppKit

final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem

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
        // Wallpaper switching will be wired up here.
    }

    @objc private func openPreferences() {
        // Preferences UI will be wired up here.
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

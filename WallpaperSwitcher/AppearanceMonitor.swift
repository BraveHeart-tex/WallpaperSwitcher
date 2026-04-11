//
//  AppearanceMonitor.swift
//  WallpaperSwitcher
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import Combine

private extension Notification.Name {
    static let appleInterfaceThemeChanged = Notification.Name("AppleInterfaceThemeChangedNotification")
}

final class AppearanceMonitor: NSObject, ObservableObject {
    @Published private(set) var isDarkMode: Bool

    private let onChange: (Bool) -> Void

    init(onChange: @escaping (Bool) -> Void = { _ in }) {
        isDarkMode = Self.resolveIsDarkMode()
        self.onChange = onChange

        super.init()

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(appearanceDidChange),
            name: .appleInterfaceThemeChanged,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(
            self,
            name: .appleInterfaceThemeChanged,
            object: nil
        )
    }

    @objc private func appearanceDidChange(_ notification: Notification) {
        Task { @MainActor in
            refreshAppearance()
        }
    }

    private func refreshAppearance() {
        let newValue = Self.resolveIsDarkMode()

        guard newValue != isDarkMode else {
            return
        }

        isDarkMode = newValue
        onChange(newValue)
    }

    private static func resolveIsDarkMode() -> Bool {
        let bestMatch = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])

        if bestMatch == .darkAqua {
            return true
        }

        if bestMatch == .aqua {
            return false
        }

        _ = UserDefaults(suiteName: "com.apple.universalaccess")?.object(forKey: "reduceTransparency") as? Bool
        return false
    }
}

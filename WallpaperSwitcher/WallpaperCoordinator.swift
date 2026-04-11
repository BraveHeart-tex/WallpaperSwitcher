//
//  WallpaperCoordinator.swift
//  WallpaperSwitcher
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import SQLite3

final class WallpaperCoordinator {
    static let shared = WallpaperCoordinator()

    var lightWallpapers: [URL] {
        didSet {
            lightWallpaperIndex = normalizedIndex(lightWallpaperIndex, count: lightWallpapers.count)
            persistState()
        }
    }

    var darkWallpapers: [URL] {
        didSet {
            darkWallpaperIndex = normalizedIndex(darkWallpaperIndex, count: darkWallpapers.count)
            persistState()
        }
    }

    private(set) var lightWallpaperIndex: Int {
        didSet {
            persistState()
        }
    }

    private(set) var darkWallpaperIndex: Int {
        didSet {
            persistState()
        }
    }

    private let defaults: UserDefaults
    private let dockDesktopPictureDatabaseURL: URL

    private enum DefaultsKey {
        static let lightWallpapers = "WallpaperCoordinator.lightWallpapers"
        static let darkWallpapers = "WallpaperCoordinator.darkWallpapers"
        static let lightWallpaperIndex = "WallpaperCoordinator.lightWallpaperIndex"
        static let darkWallpaperIndex = "WallpaperCoordinator.darkWallpaperIndex"
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dockDesktopPictureDatabaseURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Dock/desktoppicture.db")

        lightWallpapers = Self.loadURLs(forKey: DefaultsKey.lightWallpapers, from: defaults)
        darkWallpapers = Self.loadURLs(forKey: DefaultsKey.darkWallpapers, from: defaults)
        lightWallpaperIndex = defaults.integer(forKey: DefaultsKey.lightWallpaperIndex)
        darkWallpaperIndex = defaults.integer(forKey: DefaultsKey.darkWallpaperIndex)

        lightWallpaperIndex = normalizedIndex(lightWallpaperIndex, count: lightWallpapers.count)
        darkWallpaperIndex = normalizedIndex(darkWallpaperIndex, count: darkWallpapers.count)
    }

    func applyWallpaper(isDark: Bool) {
        guard let wallpaperURL = nextWallpaperURL(isDark: isDark) else {
            return
        }

        for screen in NSScreen.screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(
                    wallpaperURL,
                    for: screen,
                    options: [:]
                )
            } catch {
                print("Failed to apply wallpaper to screen \(screen): \(error.localizedDescription)")
            }
        }

        applyWallpaperToAllSpaces(wallpaperURL)
    }

    private func nextWallpaperURL(isDark: Bool) -> URL? {
        if isDark {
            guard !darkWallpapers.isEmpty else {
                return nil
            }

            let wallpaperURL = darkWallpapers[darkWallpaperIndex]
            darkWallpaperIndex = (darkWallpaperIndex + 1) % darkWallpapers.count
            return wallpaperURL
        }

        guard !lightWallpapers.isEmpty else {
            return nil
        }

        let wallpaperURL = lightWallpapers[lightWallpaperIndex]
        lightWallpaperIndex = (lightWallpaperIndex + 1) % lightWallpapers.count
        return wallpaperURL
    }

    private func persistState() {
        defaults.set(lightWallpapers.map(\.absoluteString), forKey: DefaultsKey.lightWallpapers)
        defaults.set(darkWallpapers.map(\.absoluteString), forKey: DefaultsKey.darkWallpapers)
        defaults.set(lightWallpaperIndex, forKey: DefaultsKey.lightWallpaperIndex)
        defaults.set(darkWallpaperIndex, forKey: DefaultsKey.darkWallpaperIndex)
    }

    private func applyWallpaperToAllSpaces(_ wallpaperURL: URL) {
        guard FileManager.default.fileExists(atPath: dockDesktopPictureDatabaseURL.path) else {
            print("Dock desktop picture database not found at \(dockDesktopPictureDatabaseURL.path)")
            return
        }

        do {
            try updateDockDesktopPictureDatabase(wallpaperPath: wallpaperURL.path)
            try reloadDock()
        } catch {
            print("Failed to apply wallpaper to all Spaces: \(error.localizedDescription)")
        }
    }

    private func updateDockDesktopPictureDatabase(wallpaperPath: String) throws {
        var database: OpaquePointer?

        guard sqlite3_open(dockDesktopPictureDatabaseURL.path, &database) == SQLITE_OK else {
            let message = database.map { sqlite3ErrorMessage($0) } ?? "Unable to open database."
            if let database {
                sqlite3_close(database)
            }
            throw WallpaperCoordinatorError.databaseOpenFailed(message)
        }

        defer {
            sqlite3_close(database)
        }

        let updateSQL = "UPDATE data SET value = ?;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, updateSQL, -1, &statement, nil) == SQLITE_OK else {
            throw WallpaperCoordinatorError.databaseUpdateFailed(sqlite3ErrorMessage(database))
        }

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_bind_text(statement, 1, wallpaperPath, -1, SQLITE_TRANSIENT) == SQLITE_OK else {
            throw WallpaperCoordinatorError.databaseUpdateFailed(sqlite3ErrorMessage(database))
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw WallpaperCoordinatorError.databaseUpdateFailed(sqlite3ErrorMessage(database))
        }
    }

    private func reloadDock() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw WallpaperCoordinatorError.dockReloadFailed(process.terminationStatus)
        }
    }

    private func sqlite3ErrorMessage(_ database: OpaquePointer?) -> String {
        guard let database, let errorMessage = sqlite3_errmsg(database) else {
            return "Unknown SQLite error."
        }

        return String(cString: errorMessage)
    }

    private static func loadURLs(forKey key: String, from defaults: UserDefaults) -> [URL] {
        defaults.stringArray(forKey: key)?.compactMap(URL.init(string:)) ?? []
    }

    private func normalizedIndex(_ index: Int, count: Int) -> Int {
        guard count > 0 else {
            return 0
        }

        return min(max(index, 0), count - 1)
    }
}

private enum WallpaperCoordinatorError: LocalizedError {
    case databaseOpenFailed(String)
    case databaseUpdateFailed(String)
    case dockReloadFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .databaseOpenFailed(let message):
            return "Could not open Dock desktop picture database: \(message)"
        case .databaseUpdateFailed(let message):
            return "Could not update Dock desktop picture database: \(message)"
        case .dockReloadFailed(let status):
            return "Could not reload Dock. killall exited with status \(status)."
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

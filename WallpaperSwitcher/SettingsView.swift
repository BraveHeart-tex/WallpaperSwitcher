//
//  SettingsView.swift
//  WallpaperSwitcher
//
//  Created by Bora on 11.04.2026.
//

import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var lightWallpapers: [URL] = []
    @State private var darkWallpapers: [URL] = []
    @State private var rotateWallpaper = false
    @State private var rotationInterval: WallpaperRotationInterval = .onLoginOnly
    @State private var launchAtLogin = false
    @State private var launchAtLoginStatusText = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                WallpaperSectionView(
                    title: "Light mode wallpapers",
                    wallpapers: $lightWallpapers,
                    onChange: { WallpaperCoordinator.shared.lightWallpapers = $0 }
                )

                Divider()

                WallpaperSectionView(
                    title: "Dark mode wallpapers",
                    wallpapers: $darkWallpapers,
                    onChange: { WallpaperCoordinator.shared.darkWallpapers = $0 }
                )
            }

            Divider()

            RotationSettingsView(
                rotateWallpaper: $rotateWallpaper,
                rotationInterval: $rotationInterval,
                launchAtLogin: $launchAtLogin,
                launchAtLoginStatusText: launchAtLoginStatusText,
                onLaunchAtLoginChange: setLaunchAtLogin
            )
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            lightWallpapers = WallpaperCoordinator.shared.lightWallpapers
            darkWallpapers = WallpaperCoordinator.shared.darkWallpapers
            rotateWallpaper = WallpaperCoordinator.shared.rotateWallpaper
            rotationInterval = WallpaperCoordinator.shared.rotationInterval
            refreshLaunchAtLoginStatus()
        }
        .onChange(of: rotateWallpaper) { _, newValue in
            WallpaperCoordinator.shared.rotateWallpaper = newValue
        }
        .onChange(of: rotationInterval) { _, newValue in
            WallpaperCoordinator.shared.rotationInterval = newValue
        }
    }

    private func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error.localizedDescription)")
        }

        refreshLaunchAtLoginStatus()
    }

    private func refreshLaunchAtLoginStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLogin = true
            launchAtLoginStatusText = "Enabled"
        case .requiresApproval:
            launchAtLogin = true
            launchAtLoginStatusText = "Requires approval in System Settings"
        case .notRegistered:
            launchAtLogin = false
            launchAtLoginStatusText = "Disabled"
        case .notFound:
            launchAtLogin = false
            launchAtLoginStatusText = "Login item unavailable"
        @unknown default:
            launchAtLogin = false
            launchAtLoginStatusText = "Status unavailable"
        }
    }
}

private struct RotationSettingsView: View {
    @Binding var rotateWallpaper: Bool
    @Binding var rotationInterval: WallpaperRotationInterval
    @Binding var launchAtLogin: Bool

    let launchAtLoginStatusText: String
    let onLaunchAtLoginChange: (Bool) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Rotate wallpaper", isOn: $rotateWallpaper)

                Text("Use the next image from the current appearance list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Interval", selection: $rotationInterval) {
                ForEach(WallpaperRotationInterval.allCases) { interval in
                    Text(interval.title).tag(interval)
                }
            }
            .frame(width: 190)

            Divider()
                .frame(height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        onLaunchAtLoginChange(newValue)
                    }
                ))

                Text(launchAtLoginStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WallpaperSectionView: View {
    let title: String
    @Binding var wallpapers: [URL]
    let onChange: ([URL]) -> Void

    @State private var selectedWallpapers: Set<URL> = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)

                Spacer()

                Text("\(wallpapers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(wallpapers, id: \.self) { wallpaper in
                        WallpaperThumbnailView(
                            url: wallpaper,
                            isSelected: selectedWallpapers.contains(wallpaper)
                        )
                        .onTapGesture {
                            toggleSelection(for: wallpaper)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .overlay {
                if wallpapers.isEmpty {
                    ContentUnavailableView(
                        "No images selected",
                        systemImage: "photo.on.rectangle",
                        description: Text("Add jpg, png, or heic files.")
                    )
                }
            }

            HStack(spacing: 10) {
                Button("Add images...") {
                    addImages()
                }

                Button("Remove selected") {
                    removeSelected()
                }
                .disabled(selectedWallpapers.isEmpty)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: wallpapers) { _, newValue in
            selectedWallpapers = selectedWallpapers.intersection(Set(newValue))
        }
    }

    private func addImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .heic]

        guard panel.runModal() == .OK else {
            return
        }

        let existingWallpapers = Set(wallpapers)
        let newWallpapers = panel.urls.filter { !existingWallpapers.contains($0) }

        guard !newWallpapers.isEmpty else {
            return
        }

        wallpapers.append(contentsOf: newWallpapers)
        onChange(wallpapers)
    }

    private func removeSelected() {
        wallpapers.removeAll { selectedWallpapers.contains($0) }
        selectedWallpapers.removeAll()
        onChange(wallpapers)
    }

    private func toggleSelection(for wallpaper: URL) {
        if selectedWallpapers.contains(wallpaper) {
            selectedWallpapers.remove(wallpaper)
        } else {
            selectedWallpapers.insert(wallpaper)
        }
    }
}

private struct WallpaperThumbnailView: View {
    let url: URL
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.12))
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }

            Text(url.deletingPathExtension().lastPathComponent)
                .font(.caption2)
                .lineLimit(1)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: isSelected ? 3 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

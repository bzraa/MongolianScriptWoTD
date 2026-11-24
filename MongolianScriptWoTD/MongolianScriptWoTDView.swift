//
//  MongolianScriptWoTD.swift
//  MongolianScriptWoTD
//
//  Created by Bazarsad Uurdmandakh on 2026.11.24.
//

import ScreenSaver
import SwiftUI
import os

private let log = Logger(subsystem: "SOLO.MongolianScriptWoTD", category: "saver")

enum SaverSettings {
    private static let key = "theme"

    private static var moduleName: String {
        Bundle(for: BundleToken.self).bundleIdentifier ?? "mn.words.saver"
    }

    static var theme: BackgroundTheme {
        get {
            let defaults = ScreenSaverDefaults(forModuleWithName: moduleName)
            defaults?.synchronize()   // pull the latest values from disk
            let raw = defaults?.string(forKey: key)
            log.notice("read theme = \(raw ?? "nil", privacy: .public)")
            return BackgroundTheme(rawValue: raw ?? "") ?? .blue
        }
        set {
            let defaults = ScreenSaverDefaults(forModuleWithName: moduleName)
            defaults?.set(newValue.rawValue, forKey: key)
            defaults?.synchronize()
            log.notice("saved theme = \(newValue.rawValue, privacy: .public)")
        }
    }
}

@objc(MongolianScriptWoTDView)
final class MongolianScriptWoTDView: ScreenSaverView {

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private var host: NSHostingView<ContentView>?

    private func setup() {
        FontLoader.registerFonts()

        let host = NSHostingView(rootView: ContentView(theme: SaverSettings.theme))
        host.frame = bounds
        host.autoresizingMask = [.width, .height]
        addSubview(host)
        self.host = host
    }

    override func startAnimation() {
        super.startAnimation()
        host?.rootView = ContentView(theme: SaverSettings.theme)
    }

    override var hasConfigureSheet: Bool { true }
    
    private final class ConfigWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { true }
    }

    private var sheetWindow: NSWindow?

    override var configureSheet: NSWindow? {
        if let sheetWindow { return sheetWindow }

        let size = NSSize(width: 380, height: 200)

        let hosting = NSHostingView(rootView: ConfigView { [weak self] in
            guard let window = self?.sheetWindow else { return }
            if let parent = window.sheetParent {
                parent.endSheet(window)
            } else {
                window.close()
            }
        })
        hosting.frame = NSRect(origin: .zero, size: size)

        let window = ConfigWindow(
            contentRect: hosting.frame,
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentView = hosting
        window.isReleasedWhenClosed = false   // so the reused window isn't deallocated
        sheetWindow = window
        return window
    }
}

struct ConfigView: View {
    @State private var theme = SaverSettings.theme
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Background", selection: $theme) {
                ForEach(BackgroundTheme.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.radioGroup)

            HStack {
                Spacer()
                Button("Done") {
                    SaverSettings.theme = theme
                    onDone()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

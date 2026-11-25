//
//  PreviewMSWoTDApp.swift
//  PreviewMSWoTD
//
//  Created by Bazarsad Uurdmandakh on 2026.11.25.
//

import SwiftUI

@main
struct PreviewMSWoTDApp: App {
    
    init() {
        _ = FontLoader.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(theme: .pink)
                .frame(minWidth: 900, minHeight: 600)
                .background(Color.black)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

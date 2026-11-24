//
//  BackgroundTheme.swift
//  MongolianScriptWoTD
//
//  Created by Bazarsad Uurdmandakh on 2026.11.24.
//

import SwiftUI

enum BackgroundTheme: String, CaseIterable, Identifiable {
    case blue, green, pink, black

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: "Blue"
        case .green: "Green"
        case .pink: "Pink"
        case .black: "Black"
        }
    }

    // bottom -> top
    var colors: [Color] {
        switch self {
        case .blue:
            [Color(.displayP3, red: 0.000, green: 0.470, blue: 0.706),
             Color(.displayP3, red: 0.322, green: 0.624, blue: 0.817),
             Color(.displayP3, red: 0.383, green: 0.763, blue: 0.935)]
        case .green:
            [Color(.displayP3, red: 0.000, green: 0.520, blue: 0.300),
             Color(.displayP3, red: 0.300, green: 0.700, blue: 0.470),
             Color(.displayP3, red: 0.450, green: 0.850, blue: 0.620)]
        case .pink:
            [Color(.displayP3, red: 0.800, green: 0.160, blue: 0.440),
             Color(.displayP3, red: 0.910, green: 0.450, blue: 0.640),
             Color(.displayP3, red: 0.980, green: 0.670, blue: 0.800)]
        case .black:
            [Color(.displayP3, red: 0.00, green: 0.00, blue: 0.00),
             Color(.displayP3, red: 0.07, green: 0.07, blue: 0.09),
             Color(.displayP3, red: 0.15, green: 0.15, blue: 0.19)]
        }
    }

    // explicit color, otherwise black text would vanish on the black theme
    var wordColor: Color {
        .white
    }
}

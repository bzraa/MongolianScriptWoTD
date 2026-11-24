import CoreText
import Foundation

final class BundleToken {}

let mongolianFontName = "Classical Mongolian Dashitseden"

enum FontLoader {
    private static let registerOnce: Void = {
        let bundle = Bundle(for: BundleToken.self)
        for ext in ["ttf", "otf"] {
            let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
            for url in urls {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    print("Font registration failed for \(url.lastPathComponent): \(String(describing: error?.takeRetainedValue()))")
                }
            }
        }
    }()

    static func registerFonts() {
        _ = registerOnce
    }
}

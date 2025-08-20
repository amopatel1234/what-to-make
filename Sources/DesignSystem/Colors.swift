import SwiftUI
import UIKit

// MARK: - Color Tokens
public extension Color {
    /// Primary brand accent (from Assets.xcassets > AccentColor).
    static var fpAccent: Color { .accentColor }
    static var fpSecondaryColor: Color { .fpSecondary }

    // Semantic neutrals (system adaptive).
    static var fpBackground: Color { Color(uiColor: .systemBackground) }
    static var fpSurface: Color { Color(uiColor: .secondarySystemBackground) }
    static var fpSeparator: Color { Color(uiColor: .separator) }
    static var fpLabel: Color { Color(uiColor: .label) }
    static var fpSecondaryLabel: Color { Color(uiColor: .secondaryLabel) }

    // Status (brand later if needed).
    static var fpSuccess: Color { .green }
    static var fpWarning: Color { .orange }
    static var fpError: Color { .red }
}

// MARK: - Safe asset lookup (no recursion / collisions)
private extension Color {
    /// Returns a Color if an asset with `name` exists, else nil.
    static func fpAsset(_ name: String, bundle: Bundle = .main) -> Color? {
        if let ui = UIColor(named: name, in: bundle, compatibleWith: nil) {
            return Color(uiColor: ui)
        }
        return nil
    }
}

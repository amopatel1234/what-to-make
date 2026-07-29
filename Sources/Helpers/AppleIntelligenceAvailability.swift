//
//  AppleIntelligenceAvailability.swift
//  whattomake
//
//  Created by Cursor on 29/07/2026.
//

import Foundation
import FoundationModels

/// Coarse Apple Intelligence state for Add/Edit Recipe UI gating.
///
/// Distinguishes hardware/model unavailability (hide AI sections) from
/// “device supports it but the user hasn’t turned it on” (show controls disabled
/// with a Settings hint).
enum AppleIntelligenceAvailability: Equatable, Sendable {
    /// On-device model can run right now.
    case available
    /// Device supports Apple Intelligence, but it is off in Settings.
    case notEnabled
    /// Device ineligible, model not ready, or other unavailable reason.
    case unavailable

    /// Whether paste / suggest / Image Playground UI should appear.
    var showsFeatures: Bool {
        switch self {
        case .available, .notEnabled:
            return true
        case .unavailable:
            return false
        }
    }

    /// Whether AI actions (extract, suggest, generate image) may run.
    var allowsActions: Bool {
        self == .available
    }

    /// Shown next to disabled AI controls when the user can enable Apple Intelligence.
    var enablementHintMessage: String? {
        switch self {
        case .notEnabled:
            return Self.notEnabledHintMessage
        case .available, .unavailable:
            return nil
        }
    }

    /// Shared copy for Settings enablement hints and related errors.
    static let notEnabledHintMessage =
        "Turn on Apple Intelligence in Settings to use this feature."

    /// Live status from ``SystemLanguageModel/default``.
    static var current: AppleIntelligenceAvailability {
        status(for: SystemLanguageModel.default.availability)
    }

    /// Maps Foundation Models availability into app UI state (unit-testable).
    static func status(
        for availability: SystemLanguageModel.Availability
    ) -> AppleIntelligenceAvailability {
        switch availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return status(forUnavailableReason: reason)
        }
    }

    /// Maps an unavailable reason into app UI state (unit-testable).
    static func status(
        forUnavailableReason reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> AppleIntelligenceAvailability {
        switch reason {
        case .appleIntelligenceNotEnabled:
            return .notEnabled
        case .deviceNotEligible, .modelNotReady:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }
}

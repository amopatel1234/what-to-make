//
//  DaySelectionStorage.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

import Foundation
import SwiftUI

/// Encodes and decodes weekday selection persisted via `@AppStorage`.
enum DaySelectionStorage {
    static let defaultValue = ""
    private static let canonicalDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    /// Registers empty day selection default in `UserDefaults`.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            AppStorageKey.selectedDays.rawValue: defaultValue
        ])
    }

    /// Decodes comma-separated day identifiers into a validated set.
    static func decode(_ raw: String) -> Set<String> {
        let allowed = Set(canonicalDays)
        return Set(
            raw.split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty && allowed.contains($0) }
        )
    }

    /// Encodes selected days in canonical Mon→Sun order for stable persistence.
    static func encode(_ days: Set<String>) -> String {
        canonicalDays.filter { days.contains($0) }.joined(separator: ",")
    }

    /// Returns canonical weekday order for menu generation.
    static func orderedDays(from days: Set<String>) -> [String] {
        canonicalDays.filter { days.contains($0) }
    }

    /// Toggle binding backed by comma-separated `@AppStorage` raw value.
    static func toggleBinding(for day: String, raw: Binding<String>) -> Binding<Bool> {
        Binding(
            get: { decode(raw.wrappedValue).contains(day) },
            set: { isOn in
                var days = decode(raw.wrappedValue)
                if isOn {
                    days.insert(day)
                } else {
                    days.remove(day)
                }
                raw.wrappedValue = encode(days)
            }
        )
    }
}

//
//  DayDietConstraint.swift
//  whattomake
//
//  Created by Amish Patel on 25/07/2026.
//

import Foundation
import SwiftUI

/// Encodes and decodes per-day diet constraints persisted via `@AppStorage`.
///
/// Storage format: `Mon=vegetarian,Thu=vegan`. Days with ``DayDietConstraint/any`` are omitted.
enum DayDietConstraintStorage {
    static let defaultValue = ""
    private static let canonicalDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    /// Registers empty diet-constraint default in `UserDefaults`.
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            AppStorageKey.dayDietConstraints.rawValue: defaultValue
        ])
    }

    /// Decodes `Day=constraint` pairs into a day → constraint map (``any`` omitted).
    static func decode(_ raw: String) -> [String: DayDietConstraint] {
        let allowedDays = Set(canonicalDays)
        var result: [String: DayDietConstraint] = [:]
        for token in raw.split(separator: ",") {
            let parts = token.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let day = parts[0]
            guard allowedDays.contains(day),
                  let constraint = DayDietConstraint(rawValue: parts[1]),
                  constraint != .any else { continue }
            result[day] = constraint
        }
        return result
    }

    /// Encodes non-``any`` constraints in canonical Mon→Sun order.
    static func encode(_ constraints: [String: DayDietConstraint]) -> String {
        canonicalDays.compactMap { day in
            guard let constraint = constraints[day], constraint != .any else { return nil }
            return "\(day)=\(constraint.rawValue)"
        }.joined(separator: ",")
    }

    /// Returns the constraint for `day`, defaulting to ``DayDietConstraint/any``.
    static func constraint(for day: String, in raw: String) -> DayDietConstraint {
        decode(raw)[day] ?? .any
    }

    /// Removes the stored constraint for `day` (used when the day is deselected).
    static func clearing(_ day: String, from raw: String) -> String {
        var constraints = decode(raw)
        constraints.removeValue(forKey: day)
        return encode(constraints)
    }

    /// Binding for a day's diet constraint backed by the comma-separated raw value.
    static func binding(for day: String, raw: Binding<String>) -> Binding<DayDietConstraint> {
        Binding(
            get: { constraint(for: day, in: raw.wrappedValue) },
            set: { newValue in
                var constraints = decode(raw.wrappedValue)
                if newValue == .any {
                    constraints.removeValue(forKey: day)
                } else {
                    constraints[day] = newValue
                }
                raw.wrappedValue = encode(constraints)
            }
        )
    }
}

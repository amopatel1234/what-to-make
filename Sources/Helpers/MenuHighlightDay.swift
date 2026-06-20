//
//  MenuHighlightDay.swift
//  whattomake
//
//  Created by Amish Patel on 20/06/2026.
//

import Foundation
import SwiftUI

/// Resolves which menu day to emphasize as today or the next upcoming entry.
enum MenuHighlightDay {
    /// Whether the highlighted day is the current weekday or the next planned day.
    enum Kind: Equatable {
        case today
        case upNext
    }

    /// A menu day to highlight in the weekly plan list.
    struct Result: Equatable {
        let day: String
        let kind: Kind
    }

    private static let canonicalDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    /// Returns the menu day to highlight for ``referenceDate``.
    ///
    /// If the current weekday appears in ``menuDays``, that day is returned as ``Kind/today``.
    /// Otherwise the next day in the Mon→Sun cycle (wrapping after Sunday) is returned as ``Kind/upNext``.
    static func resolve(
        menuDays: [String],
        on referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Result? {
        let plannedDays = Set(menuDays)
        guard !plannedDays.isEmpty else { return nil }

        let todayIndex = canonicalIndex(for: referenceDate, calendar: calendar)
        let today = canonicalDays[todayIndex]

        if plannedDays.contains(today) {
            return Result(day: today, kind: .today)
        }

        for offset in 1...7 {
            let index = (todayIndex + offset) % canonicalDays.count
            let day = canonicalDays[index]
            if plannedDays.contains(day) {
                return Result(day: day, kind: .upNext)
            }
        }

        return nil
    }

    private static func canonicalIndex(for date: Date, calendar: Calendar) -> Int {
        switch calendar.component(.weekday, from: date) {
        case 2: return 0
        case 3: return 1
        case 4: return 2
        case 5: return 3
        case 6: return 4
        case 7: return 5
        case 1: return 6
        default: return 0
        }
    }
}

// MARK: - Reference date for previews and snapshot tests

private struct MenuReferenceDateKey: EnvironmentKey {
    static let defaultValue = Date()
}

extension EnvironmentValues {
    /// Calendar date used when resolving which menu day to highlight.
    var menuReferenceDate: Date {
        get { self[MenuReferenceDateKey.self] }
        set { self[MenuReferenceDateKey.self] = newValue }
    }
}

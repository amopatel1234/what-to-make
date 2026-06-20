//
//  MenuHighlightDayTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@MainActor
@Suite
struct MenuHighlightDayTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test
    func highlightsTodayWhenMenuIncludesCurrentWeekday() {
        let wednesday = date(year: 2026, month: 6, day: 17)
        let result = MenuHighlightDay.resolve(
            menuDays: ["Mon", "Wed", "Fri"],
            on: wednesday,
            calendar: calendar
        )
        #expect(result == MenuHighlightDay.Result(day: "Wed", kind: .today))
    }

    @Test
    func highlightsNextPlannedDayWhenTodayIsNotOnMenu() {
        let saturday = date(year: 2026, month: 6, day: 20)
        let result = MenuHighlightDay.resolve(
            menuDays: ["Mon", "Wed", "Fri"],
            on: saturday,
            calendar: calendar
        )
        #expect(result == MenuHighlightDay.Result(day: "Mon", kind: .upNext))
    }

    @Test
    func highlightsSaturdayWhenTodayIsSaturdayAndOnMenu() {
        let saturday = date(year: 2026, month: 6, day: 20)
        let result = MenuHighlightDay.resolve(
            menuDays: ["Sat", "Mon"],
            on: saturday,
            calendar: calendar
        )
        #expect(result == MenuHighlightDay.Result(day: "Sat", kind: .today))
    }

    @Test
    func highlightsMondayWhenWeekendIsNotOnMenu() {
        let saturday = date(year: 2026, month: 6, day: 20)
        let result = MenuHighlightDay.resolve(
            menuDays: ["Mon"],
            on: saturday,
            calendar: calendar
        )
        #expect(result == MenuHighlightDay.Result(day: "Mon", kind: .upNext))
    }

    @Test
    func returnsNilForEmptyMenuDays() {
        let result = MenuHighlightDay.resolve(menuDays: [], on: date(year: 2026, month: 6, day: 20), calendar: calendar)
        #expect(result == nil)
    }
}

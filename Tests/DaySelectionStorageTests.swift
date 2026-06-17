//
//  DaySelectionStorageTests.swift
//  whattomake
//

@testable import ForkPlan
import SwiftUI
import Testing

@Suite
struct DaySelectionStorageTests {
    @Test
    func decodeEmptyStringReturnsEmptySet() {
        #expect(DaySelectionStorage.decode("") == [])
    }

    @Test
    func decodeCommaSeparatedDays() {
        let decoded = DaySelectionStorage.decode("Mon,Wed,Fri")
        #expect(decoded == ["Mon", "Wed", "Fri"])
    }

    @Test
    func decodeFiltersInvalidTokens() {
        let decoded = DaySelectionStorage.decode("Mon,BadDay,Sun")
        #expect(decoded == ["Mon", "Sun"])
    }

    @Test
    func decodeIgnoresEmptySegments() {
        let decoded = DaySelectionStorage.decode("Mon,,Wed")
        #expect(decoded == ["Mon", "Wed"])
    }

    @Test
    func encodeOrdersDaysCanonically() {
        let encoded = DaySelectionStorage.encode(["Wed", "Mon"])
        #expect(encoded == "Mon,Wed")
    }

    @Test
    func encodeEmptySetReturnsEmptyString() {
        #expect(DaySelectionStorage.encode([]) == "")
    }

    @Test
    func encodeDecodeRoundtripIsStable() {
        let raw = "Mon,Wed,Fri"
        let encoded = DaySelectionStorage.encode(DaySelectionStorage.decode(raw))
        #expect(encoded == raw)
    }

    @Test
    func orderedDaysReturnsCanonicalOrder() {
        let ordered = DaySelectionStorage.orderedDays(from: ["Wed", "Mon"])
        #expect(ordered == ["Mon", "Wed"])
    }

    @Test
    func orderedDaysReturnsEmptyArrayForEmptySet() {
        #expect(DaySelectionStorage.orderedDays(from: []) == [])
    }

    @Test
    func toggleBindingEncodesSelection() {
        var raw = DaySelectionStorage.defaultValue
        let binding = Binding(
            get: { raw },
            set: { raw = $0 }
        )
        let monToggle = DaySelectionStorage.toggleBinding(for: "Mon", raw: binding)
        monToggle.wrappedValue = true
        #expect(raw == "Mon")

        let wedToggle = DaySelectionStorage.toggleBinding(for: "Wed", raw: binding)
        wedToggle.wrappedValue = true
        #expect(raw == "Mon,Wed")

        monToggle.wrappedValue = false
        #expect(raw == "Wed")
    }
}

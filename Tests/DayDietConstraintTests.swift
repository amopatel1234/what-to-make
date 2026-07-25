//
//  DayDietConstraintTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftUI
import Testing

@Suite
struct DayDietConstraintTests {
    @Test
    func decodeEmptyReturnsEmptyMap() {
        #expect(DayDietConstraintStorage.decode("") == [:])
    }

    @Test
    func decodeParsesValidPairs() {
        let decoded = DayDietConstraintStorage.decode("Mon=vegetarian,Thu=vegan")
        #expect(decoded == ["Mon": .vegetarian, "Thu": .vegan])
    }

    @Test
    func decodeDropsAnyAndInvalidTokens() {
        let decoded = DayDietConstraintStorage.decode("Mon=any,Wed=vegan,Bad=vegan,Fri=nope")
        #expect(decoded == ["Wed": .vegan])
    }

    @Test
    func encodeOmitsAnyAndOrdersCanonically() {
        let encoded = DayDietConstraintStorage.encode([
            "Wed": .vegan,
            "Mon": .vegetarian,
            "Fri": .any
        ])
        #expect(encoded == "Mon=vegetarian,Wed=vegan")
    }

    @Test
    func encodeEmptyMapReturnsEmptyString() {
        #expect(DayDietConstraintStorage.encode([:]) == "")
    }

    @Test
    func constraintDefaultsToAny() {
        #expect(DayDietConstraintStorage.constraint(for: "Mon", in: "") == .any)
        #expect(DayDietConstraintStorage.constraint(for: "Mon", in: "Tue=vegan") == .any)
        #expect(DayDietConstraintStorage.constraint(for: "Tue", in: "Tue=vegan") == .vegan)
    }

    @Test
    func clearingRemovesDay() {
        let cleared = DayDietConstraintStorage.clearing("Mon", from: "Mon=vegetarian,Thu=vegan")
        #expect(cleared == "Thu=vegan")
    }

    @Test
    func bindingUpdatesRawValue() {
        var raw = DayDietConstraintStorage.defaultValue
        let binding = Binding(
            get: { raw },
            set: { raw = $0 }
        )
        let monDiet = DayDietConstraintStorage.binding(for: "Mon", raw: binding)
        monDiet.wrappedValue = .vegetarian
        #expect(raw == "Mon=vegetarian")
        monDiet.wrappedValue = .any
        #expect(raw == "")
    }

    @Test
    func dietaryKindSatisfiesConstraints() {
        #expect(RecipeDietaryKind.standard.satisfies(.any))
        #expect(!RecipeDietaryKind.standard.satisfies(.vegetarian))
        #expect(!RecipeDietaryKind.standard.satisfies(.vegan))
        #expect(RecipeDietaryKind.vegetarian.satisfies(.vegetarian))
        #expect(!RecipeDietaryKind.vegetarian.satisfies(.vegan))
        #expect(RecipeDietaryKind.vegan.satisfies(.vegetarian))
        #expect(RecipeDietaryKind.vegan.satisfies(.vegan))
    }
}

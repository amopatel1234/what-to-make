//
//  UITestBase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


// UITestBase.swift
import XCTest

class UITestBase: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Launch

    func launchApp(with arguments: [String]) {
        app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
    }

    // MARK: - Waits

    @discardableResult
    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5, name: String = "") -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Expected '\(name.isEmpty ? element.debugDescription : name)' to exist within \(timeout)s.")
        return exists
    }

    @discardableResult
    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5, name: String = "") -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if element.exists && element.isHittable { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTFail("Expected '\(name.isEmpty ? element.debugDescription : name)' to be hittable within \(timeout)s.")
        return false
    }

    // MARK: - Actions

    func tap(_ element: XCUIElement, name: String = "") {
        waitForHittable(element, name: name)
        element.tap()
    }

    func clearAndType(_ element: XCUIElement, text: String, name: String = "") {
        waitForHittable(element, name: name)
        element.tap()
        if let current = element.value as? String, !current.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            element.typeText(deletes)
        }
        element.typeText(text)
    }

    // MARK: - Toggles

    // Robustly interpret a toggle value across iOS variants
    func isToggleOn(_ toggle: XCUIElement) -> Bool {
        guard let raw = toggle.value as? String else { return false }
        switch raw.lowercased() {
        case "1", "on", "true": return true
        default: return false
        }
    }

    // Helper to tap the row's visible day label ("Mon", "Tue") next to the switch
    @discardableResult
    func tapDayLabel(_ day: String) -> Bool {
        let label = app.staticTexts[day]
        if label.exists && label.isHittable { label.tap(); return true }
        app.swipeUp()
        if label.exists && label.isHittable { label.tap(); return true }
        app.swipeDown()
        if label.exists && label.isHittable { label.tap(); return true }
        return false
    }

    /// Robustly forces a SwiftUI Toggle to the desired state on iOS 18.
    /// Tries: center tap → edge tap → label tap → short press, with verification after each.
    func ensureToggle(_ toggle: XCUIElement, on desiredState: Bool, dayLabel: String, name: String = "") {
        waitForExistence(toggle, name: name.isEmpty ? "Toggle" : name)

        // Early exit if already correct
        if isToggleOn(toggle) == desiredState { return }

        let attempts = 6
        for attempt in 1...attempts {
            // Scroll into view if needed
            if !toggle.isHittable { app.swipeUp() }

            // Strategy 1: center tap
            if toggle.isHittable {
                toggle.tap()
            } else {
                // if still not hittable, tap via coordinate at center
                let center = toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                center.tap()
            }

            // Verify
            if waitForToggleValue(toggle, equals: desiredState, timeout: 0.7) { return }

            // Strategy 2: tap near the thumb (right edge is often more reliable)
            if toggle.isHittable {
                let nearThumb = toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
                nearThumb.tap()
                if waitForToggleValue(toggle, equals: desiredState, timeout: 0.7) { return }
            }

            // Strategy 3: tap the row's label ("Mon", "Tue", etc.)
            _ = tapDayLabel(dayLabel)
            if waitForToggleValue(toggle, equals: desiredState, timeout: 0.7) { return }

            // Strategy 4: short press on the switch (often wakes up Form rows)
            if toggle.isHittable {
                toggle.press(forDuration: 0.05)
                if waitForToggleValue(toggle, equals: desiredState, timeout: 0.7) { return }
            }

            // Small pause before next attempt
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))

            if attempt == attempts {
                XCTFail("Toggle '\(name.isEmpty ? toggle.debugDescription : name)' not in expected state \(desiredState ? "ON" : "OFF") after \(attempts) attempts.")
            }
        }
    }

    // Tiny helper: wait briefly for toggle value to update after an interaction
    @discardableResult
    private func waitForToggleValue(_ toggle: XCUIElement, equals desired: Bool, timeout: TimeInterval) -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if isToggleOn(toggle) == desired { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
    }

    
    func element(withId identifier: String) -> XCUIElement {
        // More robust than app.otherElements[...] for nested/scrolling containers
        return app.descendants(matching: .any)[identifier]
    }
    
    /// Scrolls up/down while waiting for an element (by accessibility id) to appear.
    @discardableResult
    func waitForElementWithScrolling(
        id: String,
        timeout: TimeInterval = 6,
        name: String? = nil
    ) -> XCUIElement? {
        let query = app.descendants(matching: .any)
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let element = query[id]
            if element.exists { return element }
            // Try gentle scrolls to reveal generated content in forms
            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            if element.exists { return element }
            app.swipeDown()
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTFail("Expected element '\(name ?? id)' to appear within \(timeout)s.")
        return nil
    }

    /// After tapping Generate, poll for either a success row or an error message.
    func waitForMenuResult(days: [String], timeout: TimeInterval = 6) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            // Success path: any day row appears
            if days.contains(where: { app.descendants(matching: .any)["menuItem_\($0)"].exists }) {
                return true
            }
            // Error path: validation/error message appears
            if app.staticTexts["menuValidationMessage"].exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return false
    }

    // Add this helper at the bottom of UITestBase.swift
    func addIngredient(_ text: String) {
        let newIngredientField = app.textFields["newIngredientField"]
        let addIngredientButton = app.buttons["addIngredientButton"]

        // Ensure visible & focusable
        if !newIngredientField.isHittable { app.swipeUp() }
        waitForHittable(newIngredientField, name: "New Ingredient Field")

        // Focus (some devices need two taps to bring up keyboard in a sheet)
        newIngredientField.tap()
        if !app.keyboards.keys.element(boundBy: 0).exists { newIngredientField.tap() }

        clearAndType(newIngredientField, text: text, name: "New Ingredient Field")

        // Press Add
        waitForHittable(addIngredientButton, name: "Add Ingredient Button")
        addIngredientButton.tap()
    }
}

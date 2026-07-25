//
//  MenuIntentSupportTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@MainActor
@Suite
struct MenuIntentSupportTests {
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
    func todaysMealReportsMissingMenu() {
        let result = MenuIntentSupport.todaysMeal(menu: nil)
        #expect(result.dialog.contains("No menu yet"))
        #expect(result.recipeName == nil)
    }

    @Test
    func todaysMealHighlightsTodayRecipe() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let pasta = Recipe(name: "Pasta")
        let tacos = Recipe(name: "Tacos")
        context.insert(pasta)
        context.insert(tacos)
        let menu = Menu(days: ["Mon", "Wed"], recipes: [pasta, tacos])
        context.insert(menu)
        try context.save()

        let wednesday = date(year: 2026, month: 6, day: 17)
        let result = MenuIntentSupport.todaysMeal(
            menu: menu,
            referenceDate: wednesday,
            calendar: calendar
        )

        #expect(result.dialog == "Today you're having Tacos.")
        #expect(result.recipeName == "Tacos")
        #expect(result.day == "Wed")
        #expect(result.kind == .today)
    }

    @Test
    func todaysMealHighlightsUpNextWhenTodayMissing() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let pasta = Recipe(name: "Pasta")
        context.insert(pasta)
        let menu = Menu(days: ["Mon"], recipes: [pasta])
        context.insert(menu)
        try context.save()

        let saturday = date(year: 2026, month: 6, day: 20)
        let result = MenuIntentSupport.todaysMeal(
            menu: menu,
            referenceDate: saturday,
            calendar: calendar
        )

        #expect(result.dialog == "Up next (Mon): Pasta.")
        #expect(result.kind == .upNext)
    }

    @Test
    func weeklyMenuDialogListsDaysAndRecipes() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let pasta = Recipe(name: "Pasta")
        let tacos = Recipe(name: "Tacos")
        context.insert(pasta)
        context.insert(tacos)
        let menu = Menu(days: ["Mon", "Tue"], recipes: [pasta, tacos])
        context.insert(menu)
        try context.save()

        let dialog = MenuIntentSupport.weeklyMenuDialog(menu: menu)
        #expect(dialog == "Mon: Pasta. Tue: Tacos.")
    }

    @Test
    func generationSuccessDialogPrefixesSummary() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let pasta = Recipe(name: "Pasta")
        context.insert(pasta)
        let menu = Menu(days: ["Fri"], recipes: [pasta])
        context.insert(menu)
        try context.save()

        let dialog = MenuIntentSupport.generationSuccessDialog(menu: menu)
        #expect(dialog == "New plan ready. Fri: Pasta.")
    }

    @Test
    func savedSelectedDaysReadsUserDefaults() {
        let defaults = UserDefaults(suiteName: "MenuIntentSupportTests.days")!
        defaults.removePersistentDomain(forName: "MenuIntentSupportTests.days")
        defaults.set("Mon,Wed", forKey: AppStorageKey.selectedDays.rawValue)

        let days = MenuIntentSupport.savedSelectedDays(defaults: defaults)
        #expect(days == Set(["Mon", "Wed"]))
    }

    @Test
    func latestMenuReturnsNewestSnapshot() throws {
        let container = try makeTestContainer()
        let context = ModelContext(container)
        let olderRecipe = Recipe(name: "Old")
        let newerRecipe = Recipe(name: "New")
        context.insert(olderRecipe)
        context.insert(newerRecipe)
        let older = Menu(
            generatedDate: date(year: 2026, month: 6, day: 1),
            days: ["Mon"],
            recipes: [olderRecipe]
        )
        let newer = Menu(
            generatedDate: date(year: 2026, month: 6, day: 10),
            days: ["Tue"],
            recipes: [newerRecipe]
        )
        context.insert(older)
        context.insert(newer)
        try context.save()

        let latest = try MenuIntentSupport.latestMenu(in: context)
        #expect(latest?.recipeNames == ["New"])
        #expect(latest?.days == ["Tue"])
    }
}

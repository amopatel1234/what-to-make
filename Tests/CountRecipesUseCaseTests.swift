// filepath: /Users/amishpatel/Projects/what-to-make/Tests/FetchMenusUseCaseTests.swift
//
//  FetchMenusUseCaseTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Testing
@testable import Forkcast

struct FetchMenusUseCaseTests {
    @Test
    func testExecuteReturnsAllMenus() async throws {
        let menuRepo = MockMenuRepository()
        // Seed menus
        let m1 = Menu(days: ["Mon"], recipes: [Recipe(name: "A")])
        let m2 = Menu(days: ["Tue","Wed"], recipes: [Recipe(name: "B"), Recipe(name: "C")])
        try await menuRepo.add(m1)
        try await menuRepo.add(m2)

        let useCase = FetchMenusUseCase(repository: menuRepo)
        let menus = try await useCase.execute()
        #expect(menus.count == 2)
        #expect(menus.first?.days.isEmpty == false)
    }
}

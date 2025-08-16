// filepath: /Users/amishpatel/Projects/what-to-make/Tests/DeleteRecipeUseCaseTests.swift
//
//  DeleteRecipeUseCaseTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Foundation
import Testing
@testable import Forkcast

struct DeleteRecipeUseCaseTests {
    @Test
    func testExecuteDeletesRecipeAndImageFileIfPresent() async throws {
        // Arrange: create a temp image file
        let filename = "unit_test_img_\(UUID().uuidString.prefix(6)).jpg"
        let fileURL = ImageStore.dir.appendingPathComponent(filename)
        let dummyData = Data(repeating: 0xFF, count: 128)
        try dummyData.write(to: fileURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        // Seed repo with a recipe referencing that file
        let repo = MockRecipeRepository()
        let recipe = Recipe(name: "ToDelete", notes: nil, imageFilename: filename)
        try await repo.add(recipe)
        #expect(repo.recipes.count == 1)

        // Act
        let useCase = DeleteRecipeUseCase(repository: repo)
        try await useCase.execute(recipe)

        // Assert: recipe removed and file cleaned up
        #expect(repo.recipes.isEmpty)
        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
    }
}

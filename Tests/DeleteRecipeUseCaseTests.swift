// filepath: /Users/amishpatel/Projects/what-to-make/Tests/DeleteRecipeUseCaseTests.swift
//
//  DeleteRecipeUseCaseTests.swift
//
import Foundation
import Testing
@testable import ForkPlan

@MainActor
struct DeleteRecipeUseCaseTests {
    @Test
    func testExecuteDeletesRecipeAndImageFileIfPresent() async throws {
        let filename = "unit_test_img_\(UUID().uuidString.prefix(6)).jpg"
        let fileURL = ImageStore.dir.appendingPathComponent(filename)
        let dummyData = Data(repeating: 0xFF, count: 128)
        try dummyData.write(to: fileURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let repo = MockRecipeRepository()
        let recipe = Recipe(name: "ToDelete", notes: nil, imageFilename: filename)
        try await repo.add(recipe)
        #expect(repo.recipes.count == 1)

        let useCase = DeleteRecipeUseCase(repository: repo)
        try await useCase.execute(recipe)

        #expect(repo.recipes.isEmpty)
        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
    }
}

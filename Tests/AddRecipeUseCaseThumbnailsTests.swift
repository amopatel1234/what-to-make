// filepath: /Users/amishpatel/Projects/what-to-make/Tests/AddRecipeUseCaseThumbnailsTests.swift
//
//  AddRecipeUseCaseThumbnailsTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Testing
@testable import Forkcast

struct AddRecipeUseCaseThumbnailsTests {
    @Test
    func testExecutePersistsThumbnailAndFilename() async throws {
        let repo = MockRecipeRepository()
        let useCase = AddRecipeUseCase(repository: repo)
        let thumb = "BASE64_THUMBNAIL"
        let file = "img_ABC123.jpg"
        try await useCase.execute(name: "WithPhoto", notes: nil, thumbnailBase64: thumb, imageFilename: file)
        #expect(repo.recipes.count == 1)
        let saved = try #require(repo.recipes.first)
        #expect(saved.thumbnailBase64 == thumb)
        #expect(saved.imageFilename == file)
    }
}

//
//  AddRecipeViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


// AddRecipeViewModelTests.swift
import Testing
@testable import ForkPlan
import UIKit

@MainActor
struct AddRecipeViewModelTests {

    @Test
    func testSaveRecipeSuccess() async throws {
        let repo = MockRecipeRepository()
        let useCase = AddRecipeUseCase(repository: repo)
        let vm = AddRecipeViewModel(addRecipeUseCase: useCase)

        vm.name = "Pasta"
        vm.notes = "Yum"

        let result = await vm.saveRecipe()
        #expect(result == true)
        #expect(vm.errorMessage == nil)

        #expect(repo.recipes.count == 1)
        if let saved = repo.recipes.first {
            #expect(saved.name == "Pasta")
            #expect(saved.notes == "Yum")
        } else {
            #expect(Bool(false), "Expected a saved recipe but repo was empty")
        }
    }

    @Test
    func testSaveRecipeFailsWhenNameEmpty() async throws {
        let repo = MockRecipeRepository()
        let useCase = AddRecipeUseCase(repository: repo)
        let vm = AddRecipeViewModel(addRecipeUseCase: useCase)

        vm.name = "   "

        let result = await vm.saveRecipe()
        #expect(result == false)
        #expect(vm.errorMessage != nil)
        #expect(repo.recipes.isEmpty)
    }

    @Test
    func testResetClearsState() async throws {
        let vm = AddRecipeViewModel(addRecipeUseCase: AddRecipeUseCase(repository: MockRecipeRepository()))
        vm.name = "X"
        vm.notes = "N"
        vm.errorMessage = "E"

        vm.reset()

        #expect(vm.name.isEmpty)
        #expect(vm.notes.isEmpty)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Image Loading Helpers
    private func makeViewModel() -> AddRecipeViewModel {
        let repo = MockRecipeRepository()
        let add = AddRecipeUseCase(repository: repo)
        return AddRecipeViewModel(addRecipeUseCase: add)
    }

    private func makeJPEGData(color: UIColor = .red, size: CGSize = CGSize(width: 12, height: 12)) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    @Test
    func testHandleLoadedImageData_success_setsPreviewThumbnailAndSavesFile() async throws {
        let vm = makeViewModel()
        let data = makeJPEGData()

        await vm.handleLoadedImageData(data)

        #expect(vm.previewImage != nil)
        let thumb = try #require(vm.thumbnailBase64)
        #expect(ImageCodec.image(fromBase64: thumb) != nil)
        let filename = try #require(vm.imageFilename)

        let fileURL = ImageStore.dir.appendingPathComponent(filename)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        ImageStore.delete(named: filename)
        #expect(FileManager.default.fileExists(atPath: fileURL.path) == false)
        #expect(vm.errorMessage == nil)
    }

    @Test
    func testHandleLoadedImageData_invalidData_setsErrorAndNoImages() async throws {
        let vm = makeViewModel()
        let invalid = Data(repeating: 0x00, count: 32)

        await vm.handleLoadedImageData(invalid)

        #expect(vm.previewImage == nil)
        #expect(vm.thumbnailBase64 == nil)
        #expect(vm.imageFilename == nil)
        #expect(vm.errorMessage == "Could not load photo.")
    }

    @Test
    func testLoadSelectedImage_whenNoSelection_doesNothing() async throws {
        let vm = makeViewModel()
        vm.loadSelectedImage()
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(vm.previewImage == nil)
        #expect(vm.thumbnailBase64 == nil)
        #expect(vm.imageFilename == nil)
        #expect(vm.errorMessage == nil)
    }
}

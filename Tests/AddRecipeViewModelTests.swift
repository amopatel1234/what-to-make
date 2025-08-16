//
//  AddRecipeViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


// AddRecipeViewModelTests.swift
import Testing
@testable import ForkPlan

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
}

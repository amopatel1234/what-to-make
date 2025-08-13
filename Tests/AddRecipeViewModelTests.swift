//
//  AddRecipeViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


// AddRecipeViewModelTests.swift
import Testing
@testable import whattomake

@MainActor
struct AddRecipeViewModelTests {

    @Test
    func testAddIngredientFlow() async throws {
        let vm = AddRecipeViewModel(addRecipeUseCase: AddRecipeUseCase(repository: MockRecipeRepository()))

        vm.newIngredient = "  Tomato  "
        vm.addIngredientIfValid()

        // ✅ Expect trimmed value stored by the VM
        #expect(vm.ingredients == ["Tomato"])
        #expect(vm.newIngredient.isEmpty)

        vm.newIngredient = ""    // ignored
        vm.addIngredientIfValid()
        #expect(vm.ingredients.count == 1)

        vm.updateIngredient("Tomato (chopped)", at: 0)
        #expect(vm.ingredients == ["Tomato (chopped)"])

        vm.removeIngredient(at: 0)
        #expect(vm.ingredients.isEmpty)
    }

    @Test
    func testSaveRecipeSuccessCleansIngredients() async throws {
        let repo = MockRecipeRepository()
        let useCase = AddRecipeUseCase(repository: repo)
        let vm = AddRecipeViewModel(addRecipeUseCase: useCase)

        vm.name = "Pasta"
        vm.ingredients = ["  Pasta  ", "Sauce", "", "  "]
        vm.notes = "Yum"

        let result = await vm.saveRecipe()
        #expect(result == true)
        #expect(vm.errorMessage == nil)

        // Verify what actually got persisted
        #expect(repo.recipes.count == 1)
        if let saved = repo.recipes.first {
            #expect(saved.name == "Pasta")
            #expect(saved.ingredients == ["Pasta", "Sauce"])   // trimmed + filtered
            #expect(saved.notes == "Yum")
        } else {
            #expect(Bool(false), "Expected a saved recipe but repo was empty")
        }
    }

    @Test
    func testSaveRecipeFailsWhenNoIngredients() async throws {
        let repo = MockRecipeRepository()
        let useCase = AddRecipeUseCase(repository: repo)
        let vm = AddRecipeViewModel(addRecipeUseCase: useCase)

        vm.name = "Empty Dish"
        vm.ingredients = [] // nothing to save

        let result = await vm.saveRecipe()
        #expect(result == false)
        #expect(vm.errorMessage != nil)
        #expect(repo.recipes.isEmpty) // nothing persisted
    }

    @Test
    func testResetClearsState() async throws {
        let vm = AddRecipeViewModel(addRecipeUseCase: AddRecipeUseCase(repository: MockRecipeRepository()))
        vm.name = "X"
        vm.ingredients = ["A"]
        vm.newIngredient = "B"
        vm.notes = "N"
        vm.errorMessage = "E"

        vm.reset()

        #expect(vm.name.isEmpty)
        #expect(vm.ingredients.isEmpty)
        #expect(vm.newIngredient.isEmpty)
        #expect(vm.notes.isEmpty)
        #expect(vm.errorMessage == nil)
    }
}


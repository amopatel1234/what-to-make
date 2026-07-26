//
//  RecipeImagePlaygroundPresenter.swift
//  whattomake
//
//  Created by Cursor on 26/07/2026.
//

import ImagePlayground
import SwiftUI

// MARK: - iOS 26 presentation (swap point for iOS 27)

/// Maps a ``RecipeImageGenerationRequest`` into Image Playground concepts and presents the sheet.
///
/// ## Versioning
/// - **iOS 26 (current):** `.imagePlaygroundSheet` + ``ImagePlaygroundConcept``.
///   Do **not** introduce `ImageCreator` — Apple removes it in iOS 27.
/// - **iOS 27:** keep ``RecipeImagePlaygroundPrompt``; update ``playgroundConcepts(for:)`` and
///   this modifier for new sheet options / styles / availability environment keys
///   (see the repo GitHub issue for the migration checklist).
struct RecipeImagePlaygroundSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let request: RecipeImageGenerationRequest
    let onImageData: (Data) -> Void
    let onFailure: (String) -> Void

    func body(content: Content) -> some View {
        content
            .imagePlaygroundSheet(
                isPresented: $isPresented,
                concepts: Self.playgroundConcepts(for: request),
                onCompletion: { url in
                    loadGeneratedImage(from: url)
                },
                onCancellation: nil
            )
    }

    /// Builds framework concepts from the version-agnostic prompt helper.
    ///
    /// Isolated so iOS 27 can remap the same request into updated concept APIs.
    static func playgroundConcepts(for request: RecipeImageGenerationRequest) -> [ImagePlaygroundConcept] {
        var concepts: [ImagePlaygroundConcept] = RecipeImagePlaygroundPrompt.conceptTexts(for: request)
            .map { .text($0) }

        if let notes = RecipeImagePlaygroundPrompt.notesExtractionSource(for: request) {
            concepts.append(.extracted(from: notes, title: "Recipe notes"))
        }

        return concepts
    }

    private func loadGeneratedImage(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            onImageData(data)
        } catch {
            onFailure("Couldn't load the generated image. Try again or choose a photo.")
        }
    }
}

extension View {
    /// Seeds Image Playground from recipe fields and returns generated image bytes.
    ///
    /// Call sites stay stable across OS versions — swap ``RecipeImagePlaygroundSheetModifier``
    /// internals for iOS 27.
    func recipeImagePlaygroundSheet(
        isPresented: Binding<Bool>,
        request: RecipeImageGenerationRequest,
        onImageData: @escaping (Data) -> Void,
        onFailure: @escaping (String) -> Void = { _ in }
    ) -> some View {
        modifier(
            RecipeImagePlaygroundSheetModifier(
                isPresented: isPresented,
                request: request,
                onImageData: onImageData,
                onFailure: onFailure
            )
        )
    }
}

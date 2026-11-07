//
//  WebsiteRecipeDraft.swift
//  ForkPlan
//

import Foundation

/// Portable, reviewable website metadata. Never a persisted recipe or an AI result.
struct WebsiteRecipeDraft: Equatable, Sendable {
    var name: String
    var description: String?
    var ingredientLines: [String]
    /// Nil means the website did not explicitly specify a supported dietary kind.
    var dietaryKind: RecipeDietaryKind?
    /// Metadata only; extraction does not download images.
    var imageURL: URL?
}

/// Preserves the submitted source separately from the final redirect destination.
struct WebsiteRecipeExtraction: Equatable, Sendable {
    var sourceURL: URL
    var resolvedURL: URL
    var recipes: [WebsiteRecipeDraft]
}

/// Recoverable failures for the website-only extraction pipeline.
enum WebsiteRecipeError: Error, Equatable, LocalizedError {
    case invalidURL
    case unsafeDestination
    case resolutionFailed
    case tooManyRedirects
    case invalidRedirect
    case httpStatus(Int)
    case unsupportedContentType
    case responseTooLarge
    case unsupportedEncoding
    case insecureConnection
    case timedOut
    case networkFailure
    case noRecipeMetadata

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Enter a public HTTP or HTTPS recipe URL."
        case .unsafeDestination: return "Local and private network addresses cannot be imported."
        case .resolutionFailed: return "The recipe website address couldn't be resolved."
        case .tooManyRedirects: return "The recipe website redirected too many times."
        case .invalidRedirect: return "The recipe website returned an invalid redirect."
        case .httpStatus(let code): return "The recipe website returned HTTP \(code)."
        case .unsupportedContentType: return "That link did not return an HTML webpage."
        case .responseTooLarge: return "That webpage is too large to import."
        case .unsupportedEncoding: return "The webpage's text encoding isn't supported."
        case .insecureConnection: return "The website requires an insecure connection. Try its HTTPS address."
        case .timedOut: return "The recipe website took too long to respond."
        case .networkFailure: return "The recipe website couldn't be downloaded."
        case .noRecipeMetadata: return "No supported recipe metadata was found on that webpage."
        }
    }
}

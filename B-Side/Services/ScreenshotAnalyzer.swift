//
//  ScreenshotAnalyzer.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import UIKit
import FoundationModels

enum ScreenshotAnalyzerError: LocalizedError {

    case modelUnavailable
    case invalidImage


    var errorDescription: String? {

        switch self {

        case .modelUnavailable:
            return "Apple Intelligence is unavailable."

        case .invalidImage:
            return "The screenshot could not be processed."
        }
    }
}


@available(iOS 27.0, *)
final class ScreenshotAnalyzer {

    private let model =
        SystemLanguageModel.default


    func analyze(
        image: UIImage,
        existingCategories: [String]
    ) async throws -> ScreenshotAnalysis {

        guard model.isAvailable else {
            throw ScreenshotAnalyzerError
                .modelUnavailable
        }


        guard let cgImage =
            image.cgImage
        else {
            throw ScreenshotAnalyzerError
                .invalidImage
        }


        let session =
            LanguageModelSession(
                model: model,
                instructions: """
                You organize screenshots for B-Side.

                Understand the screenshot using both
                visual and textual context.

                Infer the likely purpose of saving it.

                Generate a dynamic category from the likely reason the screenshot
                was saved, not only the objects visible in it. Categories are never
                limited to a predefined list. Use natural display text, usually 1–3
                words, and never camelCase or enum-style names.

                If an existing category represents the same purpose, reuse its exact
                display name. Avoid near-duplicates unless the purposes genuinely differ.

                IMPORTANT: Prefer a small, coherent set of reusable collections over
                creating a new collection for every screenshot. Compare meaning and
                likely future use, not just wording. Screenshots saved for the same
                intent should share one collection even when their visible content,
                app, brand, or phrasing differs.

                For example, interface references, onboarding examples, and layout
                ideas can all reuse "Design Inspiration" when that collection exists.
                Restaurant recommendations and places to eat on the same trip can reuse
                one relevant restaurant or trip collection rather than splitting into
                near-identical categories.
                """
            )


        let categoryContext: String

        if existingCategories.isEmpty {

            categoryContext =
                """
                No automatic categories exist yet.
                Create an appropriate category.
                """

        } else {

            categoryContext =
                """
                Existing automatic categories:

                \(existingCategories.map { "- \($0)" }.joined(separator: "\n"))

                First compare the screenshot's likely purpose with every name above.
                Reuse an exact name whenever the intent is substantially similar.

                Create a new concise category only when none represents the purpose.
                """
        }


        let response =
            try await session.respond(
                generating:
                    ScreenshotAnalysis.self
            ) {

                """
                Analyze this screenshot.

                \(categoryContext)

                Focus on why the screenshot may be useful,
                not merely the objects visible in it.
                """

                Attachment(cgImage)
            }


        return response.content
    }
}

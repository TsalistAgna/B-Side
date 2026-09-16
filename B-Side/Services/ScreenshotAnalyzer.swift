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
            return "Apple Intelligence is not available."

        case .invalidImage:
            return "The screenshot could not be processed."
        }
    }
}


@available(iOS 27.0, *)
final class ScreenshotAnalyzer {

    private let model = SystemLanguageModel.default


    func analyze(
        image: UIImage
    ) async throws -> ScreenshotAnalysis {

        // Make sure Apple Foundation Model is available.
        guard model.isAvailable else {
            throw ScreenshotAnalyzerError.modelUnavailable
        }


        // PhotoKit normally gives us a UIImage backed by CGImage.
        guard let cgImage = image.cgImage else {
            throw ScreenshotAnalyzerError.invalidImage
        }


        /*
         Create a new session for each screenshot.

         Screenshot analyses are independent, so we don't need
         previous screenshots filling the session context.
         */
        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are the intelligence behind B-Side, an app that helps people rediscover the meaning behind their saved screenshots.

            Your goal is not simply to describe what appears in a screenshot.
            Your goal is to infer the most likely reason the person chose to save it.

            For every screenshot, consider:

            - visible text and interface
            - people, objects, products, places, and visual details
            - conversations or social media content
            - events, dates, tickets, and plans
            - articles, educational content, or things to read later
            - food, recipes, restaurants, and recommendations
            - design, creative, or visual references
            - products or things the person may want to buy
            - any other contextual clues that suggest future intent

            Ask yourself:

            "What would this person probably want to remember, revisit,
            reference, or act on later?"

            Prioritize the user's likely intention over surface-level visual similarity.

            For example:
            - A screenshot of a restaurant should not simply become "Food".
              If it appears to be something the user wants to visit,
              interpret it as a place worth revisiting.
            - A screenshot of shoes should not simply become "Fashion".
              Consider whether the user may be saving them as something to buy.
            - A screenshot of an app interface may be saved as design inspiration,
              rather than because of the app itself.

            When the intention is unclear:
            - Do not invent specific personal motivations.
            - Prefer a broader, factual interpretation.
            - Use cautious wording rather than presenting uncertain intent as fact.

            Generate:
            1. A short, meaningful title that captures what is worth remembering.
            2. A concise rediscovery message that helps the user immediately understand
               why this screenshot might matter when they encounter it again later.
            3. The single most appropriate B-Side category based primarily on likely purpose.

            Keep the output:
            - concise
            - natural
            - useful when rediscovered weeks or months later
            - specific when evidence supports it
            - neutral when intent is uncertain

            Avoid:
            - generic descriptions of everything visible
            - unnecessarily long explanations
            - inventing information not supported by the screenshot
            - overly confident assumptions about personal intent
            """
        )


        let response = try await session.respond(
            generating: ScreenshotAnalysis.self,
            options: GenerationOptions(
                samplingMode: .greedy
            )
        ) {

            """
            Analyze this screenshot and infer the most likely reason the user chose to save it.

            Focus on the screenshot's probable future value to the user:
            what they may want to remember, revisit, reference, compare, buy, visit, read, or act on later.

            Use the visible content only as evidence for inferring intent.
            Do not categorize the screenshot based only on the objects, app, or visual appearance.

            If the user's intent is ambiguous:
            - prefer a broader interpretation
            - avoid inventing personal details
            - use neutral, cautious wording

            Return the result based on the screenshot's likely purpose for future rediscovery.
            """
            Attachment(cgImage)
        }


        return response.content
    }
}

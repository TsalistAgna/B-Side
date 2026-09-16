//
//  ScreenshotAnalysis.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import FoundationModels

@Generable
enum BSideCategory: CaseIterable, Equatable, Hashable {
    case thingsToBuy
    case placesToVisit
    case designInspiration
    case food
    case events
    case conversations
    case workStudy
    case travel
    case memesFun
    case readLater
}

@Generable
struct ScreenshotAnalysis {

    @Guide(
        description: """
            Create a concise title that captures the most useful thing to remember
            about this screenshot.

            Prefer meaning or purpose over a generic visual description.

            Good:
            - Cafe to Visit
            - Shoes to Consider
            - Onboarding Inspiration
            - Event to Remember

            Avoid:
            - Instagram Screenshot
            - Product Image
            - Food Photo
            - App Screen

            Maximum 4 words.
            """
    )
    var title: String

    @Guide(
        description: """
            Write one short, friendly sentence that helps the user quickly understand
            why this screenshot might be worth revisiting.

            The message should feel like a gentle rediscovery prompt,
            not a confident statement about the user's personal intention.

            Base it on the likely value of the screenshot:
            something they may have wanted to revisit, remember, compare,
            buy, visit, read, reference, or act on later.

            Prefer:
            - "This café looked worth checking out. Still interested?"
            - "You kept this design for inspiration. Worth another look?"
            - "This product stood out before. Still considering it?"
            - "You saved this event earlier. Want to revisit the details?"

            Avoid:
            - claiming exactly why the user saved it
            - inventing personal plans or motivations
            - simply describing what is visible
            - repeating the title

            If intent is unclear, use neutral wording based on what can be safely inferred.

            Maximum 18 words.
            """
    )
    var rediscoveryDescription: String
    
    @Guide(
        description: """
        Write a concise description of what the screenshot appears to contain
        and why it may be useful to revisit later.

        Include the most relevant visible context, such as:
        - place, product, event, article, conversation, recipe, or interface
        - notable names, topics, or details when clearly visible
        - the likely future value of the screenshot

        Describe the likely purpose carefully without presenting the user's
        intention as certain.

        Prefer wording such as:
        - "This appears to show..."
        - "It may have been saved as..."
        - "This could be useful for..."

        Avoid:
        - listing every visible detail
        - repeating the title or rediscovery message
        - inventing information that is not supported by the screenshot
        - stating personal intent as fact
        - overly generic descriptions

        The description should help the user quickly understand the screenshot
        even if they no longer remember its original context.

        Maximum 45 words.
        """
    )
    var detailDescription: String
    
    @Guide(
        description: """
        Generate 3 to 4 short tags that capture the most useful searchable
        context of this screenshot.

        Tags should help the user rediscover the screenshot later.

        Prioritize:
        - specific subject or item
        - place or location
        - activity or purpose
        - relevant topic or category context

        Good examples:
        - Udon
        - Ubud
        - Restaurant
        - UI Inspiration
        - Sneakers
        - Running Shoes
        - Recipe
        - Concert

        Prefer meaningful, specific tags over generic visual labels.

        Avoid:
        - Screenshot
        - Image
        - App
        - Photo
        - overly broad or redundant tags
        - tags that repeat the same meaning
        - details that are not clearly supported by the screenshot

        Keep each tag concise, preferably 1 to 3 words.

        If the screenshot contains a clearly identifiable name, place,
        product, or topic that would improve future search, include it.

        Return 2 to 4 unique tags.
        """
    )
    var tags: [String]

    @Guide(
        description: """
            Choose the B-Side category that best represents the screenshot's
            likely future purpose.

            Categorize based primarily on why the screenshot may be useful later,
            not only on the objects, app, or visual content shown.

            Examples:
            - restaurant recommendation → Places to Visit
            - product page → Things to Buy
            - interface reference → Design Inspiration
            - article → Read Later
            - recipe → Recipes & Food
            - ticket or event details → Events & Tickets

            If several categories are possible, choose the one that best reflects
            the most likely reason the user would want to rediscover the screenshot.

            If intent is uncertain, prefer the broader and safer category.
            """
    )
    var category: BSideCategory
}

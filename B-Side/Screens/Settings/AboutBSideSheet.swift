//
//  AboutBSideSheet.swift
//  B-Side
//

import SwiftUI

struct AboutBSideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BSideInfoSheet(
            icon: "opticaldisc",
            title: "Side-B",
            buttonTitle: "Done"
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Rediscover what you saved.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(
                    "Side-B uses on-device intelligence to understand, organize, and help you find your screenshots again."
                )
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .lineSpacing(3)

                HStack {
                    Text("Version")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Text(version)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(16)
                .background(Color.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.borderDefault, lineWidth: 1)
                }
            }
        } action: {
            dismiss()
        }
    }

    private var version: String {
        let shortVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        switch (shortVersion, build) {
        case let (.some(version), .some(build)):
            return "\(version) (\(build))"
        case let (.some(version), .none):
            return version
        case let (.none, .some(build)):
            return build
        case (.none, .none):
            return "Unavailable"
        }
    }
}

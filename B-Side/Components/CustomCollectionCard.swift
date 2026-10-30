//
//  CustomCollectionCard.swift
//  Side-B
//

import SwiftUI

struct CustomCollectionCard: View {
    let collection: CustomCollection
    let trackCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: BSideLayout.spacingMD) {
            HStack {
                Spacer()
                Image(collection.vinylStyle.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 104, height: 104)
                    .accessibilityHidden(true)
                Spacer()
            }

            VStack(alignment: .leading, spacing: BSideLayout.spacingXS) {
                Text(collection.name)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(trackCount) tracks")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(BSideLayout.spacingLG)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: BSideLayout.radiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: BSideLayout.radiusCard)
                .stroke(Color.borderDefault, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(collection.name)
        .accessibilityValue("\(trackCount) tracks")
    }
}

//
//  ManageScreenshotDataSheet.swift
//  B-Side
//

import SwiftUI

struct ManageScreenshotDataSheet: View {
    @Environment(\.dismiss) private var dismiss

    let trackCount: Int
    let collectionCount: Int
    let onClear: () -> Void

    @State private var showClearConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.accentText)
                    .frame(width: 64, height: 64)
                    .background(Color.surfaceSecondary)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text("Manage Side-B Data")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                VStack(spacing: 0) {
                    dataRow(title: "Tracks stored in Side-B", count: trackCount)

                    SettingsDivider()

                    dataRow(title: "Custom Collections", count: collectionCount)
                }
                .background(Color.bSideBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.borderDefault, lineWidth: 1)
                }

                Text(
                    "Side-B stores analysis and collection information locally. Your original screenshots stay in Photos."
                )
                    .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

                Button {
                    showClearConfirmation = true
                } label: {
                    Text("Clear Side-B Data")
                        .font(.headline)
                        .foregroundStyle(Color.destructiveForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(minHeight: BSideLayout.buttonMinimumHeight)
                        .background(Color.destructiveBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2))
                }
                .buttonStyle(.plain)
                .disabled(trackCount == 0 && collectionCount == 0)
                .opacity(trackCount == 0 && collectionCount == 0 ? 0.45 : 1)
            }
            .padding(24)
        }
        .padding(.top, BSideLayout.spacingMD)
        .background(Color.bSideBackground.ignoresSafeArea())
        .sheet(isPresented: $showClearConfirmation) {
            DestructiveConfirmationSheet(
                icon: "externaldrive",
                title: "Clear Side-B Data?",
                message: "This removes all Tracks, analysis, and custom collections from Side-B. Your original screenshots will remain in Photos.",
                destructiveButtonTitle: "Clear Data"
            ) {
                onClear()
                dismiss()
            }
                    .presentationDetents([.medium, .large])
            .presentationCornerRadius(BSideLayout.radiusSheet)
            .presentationDragIndicator(.visible)
        }
    }

    private func dataRow(
        title: String,
        count: Int
    ) -> some View {
        HStack {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text(count.formatted())
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentText)
        }
        .padding(17)
    }
}

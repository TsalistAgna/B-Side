//
//  DeleteConfirmationSheet.swift
//  B-Side
//

import SwiftUI

struct DeleteConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let message: String
    let deleteButtonTitle: String
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(Color.blue3)
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            Image(systemName: "trash")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(Color.red)
                .frame(width: 66, height: 66)
                .background(Color.red.opacity(0.8))
                .clipShape(Circle())

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.blue10)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.bSideSecondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(spacing: 12) {
                Button {
                    onDelete()
                    dismiss()
                } label: {
                    Text(deleteButtonTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.blue10)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.bSideBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color.bSideBackground.ignoresSafeArea())
    }
}

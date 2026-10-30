//
//  EditCollectionSheet.swift
//  B-Side
//

import SwiftUI

struct EditCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let showsCustomOptions: Bool
    let onSave: (String, VinylStyle, Bool) -> Void

    @State private var name: String
    @State private var vinylStyle: VinylStyle
    @State private var autoOrganize: Bool

    init(
        title: String = "Edit Collection",
        name: String,
        vinylStyle: VinylStyle = .pink,
        autoOrganize: Bool = false,
        showsCustomOptions: Bool,
        onSave: @escaping (String, VinylStyle, Bool) -> Void
    ) {
        self.title = title
        self.showsCustomOptions = showsCustomOptions
        self.onSave = onSave
        _name = State(initialValue: name)
        _vinylStyle = State(initialValue: vinylStyle)
        _autoOrganize = State(initialValue: autoOrganize)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Button { dismiss() } label: {
                        Text("Cancel")
                            .padding(.vertical, 10)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .foregroundStyle(Color.accentText)

                    Spacer()

                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Collection Name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)

                    TextField("Collection name", text: $name, axis: .vertical)
                        .foregroundStyle(Color.textPrimary)
                        .padding()
                        .frame(minHeight: 58)
                        .background(Color.bSideBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderDefault, lineWidth: 1)
                        }
                }

                if showsCustomOptions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Vinyl")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textPrimary)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ],
                            spacing: 10
                        ) {
                            ForEach(VinylStyle.allCases) { style in
                                Button {
                                    vinylStyle = style
                                } label: {
                                    VinylOption(
                                        style: style,
                                        isSelected: vinylStyle == style
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Toggle("Let AI Auto-Organize", isOn: $autoOrganize)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .tint(Color.accentPrimary)
                }

                Button {
                    onSave(cleanName, vinylStyle, autoOrganize)
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: BSideLayout.buttonMinimumHeight)
                        .background(canSave ? Color.accentPrimary : Color.controlDisabled)
                        .clipShape(RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
            .padding(24)
        }
        .background(Color.bSideBackground.ignoresSafeArea())
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !cleanName.isEmpty
    }
}

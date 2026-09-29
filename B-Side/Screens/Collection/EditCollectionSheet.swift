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
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.bSideBlue)

                    Spacer()

                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.blue10)

                    Spacer()

                    Color.clear.frame(width: 50, height: 1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Collection Name")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.blue10)

                    TextField("Collection name", text: $name)
                        .foregroundStyle(Color.blue10)
                        .padding()
                        .frame(height: 58)
                        .background(Color.bSideBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue4, lineWidth: 1)
                        }
                }

                if showsCustomOptions {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Vinyl")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.blue10)

                        HStack(spacing: 10) {
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
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.blue10)
                        .tint(Color.bSideBlue)
                }

                Button {
                    onSave(cleanName, vinylStyle, autoOrganize)
                    dismiss()
                } label: {
                    Text("Save Changes")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canSave ? Color.bSideBlue : Color.blue3)
                        .clipShape(Capsule())
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

//
//  AppColors.swift
//  Side-B
//

import SwiftUI

extension Color {
    // MARK: - Base Palette

    static let blue1 = Color(hex: "E9F0FD")
    static let blue2 = Color(hex: "CADAFB")
    static let blue3 = Color(hex: "A0BCF8")
    static let blue4 = Color(hex: "749DF5")
    static let blue5 = Color(hex: "4B80F2")
    static let blue6 = Color(hex: "2364EF")
    static let blue7 = Color(hex: "1E55CB")
    static let blue8 = Color(hex: "1947AA")
    static let blue9 = Color(hex: "143988")
    static let blue10 = Color(hex: "102D6C")

    static let red1 = Color(hex: "FFF8FD")
    static let red2 = Color(hex: "FFEEF9")
    static let red3 = Color(hex: "FFE0F5")
    static let red4 = Color(hex: "FED2F0")
    static let red5 = Color(hex: "FEC4EB")
    static let red6 = Color(hex: "FEB7E7")
    static let red7 = Color(hex: "D89CC4")
    static let red8 = Color(hex: "B482A4")
    static let red9 = Color(hex: "916884")
    static let red10 = Color(hex: "725268")

    // MARK: - Side-B Semantic Colors

    static let bSideBackground = Color(hex: "FFFFFB")
    static let surfacePrimary = bSideBackground
    static let surfaceSecondary = blue1
    static let surfaceElevated = Color.white

    static let textPrimary = blue10
    static let textSecondary = blue8
    static let textTertiary = blue7

    static let accentPrimary = blue6
    static let accentText = blue7
    static let accentForeground = Color.white
    static let accentSoft = blue1

    /// Use for meaningful boundaries and interactive outlines.
    static let borderDefault = blue6
    /// Decorative-only border; do not use as the sole state indicator.
    static let borderSubtle = blue4
    static let divider = blue3.opacity(0.65)

    static let destructiveForeground = Color(hex: "AF3040")
    static let destructiveBackground = Color(hex: "FAD9DC")
    static let destructiveIconBackground = Color(hex: "FFE4E6")

    static let tagForeground = red10
    static let tagBackground = red2
    static let decorativeAccent = blue3
    static let decorativePink = red4
    static let controlDisabled = blue3

    // Legacy aliases retained while views migrate to semantic names.
    static let bSideBlue = accentPrimary
    static let bSideDarkBlue = textPrimary
    static let bSideSecondaryText = textSecondary
    static let bSidePrivacyText = textSecondary
    static let bSidePink = red6

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)

        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

enum BSideLayout {
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 14
    static let spacingLG: CGFloat = 20
    static let spacingXL: CGFloat = 24

    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusCard: CGFloat = 16
    static let radiusSheet: CGFloat = 30

    static let minimumTouchTarget: CGFloat = 44
    static let buttonMinimumHeight: CGFloat = 52
}

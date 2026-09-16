//
//  AppColors.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

import SwiftUI

extension Color {
    
    // MARK: - Blue Palette
    
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
    
    
    // MARK: - Red Palette
    
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
    
    
    // MARK: - B-Side Semantic Colors
    
    /// Main B-Side blue
    static let bSideBlue = Color.blue6
    
    /// Dark blue for headings
    static let bSideDarkBlue = Color.blue10
    
    /// Main app background
    static let bSideBackground = Color(hex: "FFFFFB")
    
    /// Secondary text
    static let bSideSecondaryText = Color.blue8
    
    /// Small / subtle information text
    static let bSidePrivacyText = Color.blue3
    
    /// Optional pink accent
    static let bSidePink = Color.red6
    
    
    init(hex: String) {
           let hex = hex.trimmingCharacters(
               in: CharacterSet.alphanumerics.inverted
           )
           
           var value: UInt64 = 0
           Scanner(string: hex).scanHexInt64(&value)
           
           let red = Double((value >> 16) & 0xFF) / 255
           let green = Double((value >> 8) & 0xFF) / 255
           let blue = Double(value & 0xFF) / 255
           
           self.init(
               red: red,
               green: green,
               blue: blue
           )
       }
}

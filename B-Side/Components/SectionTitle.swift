//
//  SectionTitle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct SectionTitle: View {
    
    let title: String
    
    var body: some View {
        
        Text(title)
            .font(
                .title3.weight(.medium)
            )
            .foregroundStyle(
                Color.textPrimary
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }
}

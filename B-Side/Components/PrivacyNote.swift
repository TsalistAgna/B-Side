//
//  PrivacyNote.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct PrivacyNote: View {

    var body: some View {
        HStack(spacing: 6) {

            Image(systemName: "lock.fill")
                .font(.caption2)
                .accessibilityHidden(true)

            Text("On supported devices, screenshot analysis happens on-device.")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.bSidePrivacyText)
    }
}

#Preview {
    PrivacyNote()
}

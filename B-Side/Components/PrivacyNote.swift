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
                .font(.system(size: 11))

            Text("Your screenshots are analyzed\nprivately on your device")
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(Color.bSidePrivacyText)
    }
}

#Preview {
    PrivacyNote()
}

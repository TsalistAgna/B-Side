//
//  SplashView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct SplashView: View {

    var body: some View {
        ZStack {
            Color.bSideBackground
                .ignoresSafeArea()

            Image("bsideLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 170)
        }
    }
}

#Preview {
    SplashView()
}

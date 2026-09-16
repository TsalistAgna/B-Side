//
//  ContentView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct ContentView: View {

    @State private var showSplash = true
    @State private var hasFinishedOnboarding = false

    var body: some View {

        Group {

            if showSplash {

                SplashView()

            } else if hasFinishedOnboarding {

                MainTabView()

            } else {

                OnboardingView(
                    onOrganizeTracks: {
                        withAnimation {
                            hasFinishedOnboarding = true
                        }
                    }
                )
            }
        }
        .onAppear {

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 1.5
            ) {

                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

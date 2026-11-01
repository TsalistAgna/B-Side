//
//  ContentView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()
    @State private var firstRunDestination: FirstRunDestination = .home
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showSplash = true
    @AppStorage(AppPreferences.hasFinishedOnboardingKey)
    private var hasFinishedOnboarding = false

    var body: some View {

        Group {

            if showSplash {

                SplashView()

            } else if hasFinishedOnboarding {

                MainTabView(viewModel: viewModel, firstRunDestination: firstRunDestination)

            } else {

                OnboardingView(
                    viewModel: viewModel,
                    onFinish: { destination in
                        firstRunDestination = destination
                        withAnimation(reduceMotion ? nil : .default) {
                            AppPreferences.completeOnboarding()
                        }
                    }
                )
            }
        }
        .task {
            viewModel.configurePersistence(context: modelContext)
        }
        .onAppear {

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 1.5
            ) {

                withAnimation(reduceMotion ? nil : .default) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

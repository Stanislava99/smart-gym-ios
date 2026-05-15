//
//  AppNavigationView.swift
//  SmartGym
//

import SwiftUI

enum AppDestination: String, CaseIterable {
    case home = "Home"
    case gym = "Gym"
    case profile = "Profile"
}

struct AppNavigationView: View {
    @State private var isLoggedIn = false
    @State private var isLoadingAuth = true
    @State private var selectedTab: AppDestination = .home
    @State private var homeViewModel = HomeViewModel()

    var body: some View {
        Group {
            if isLoadingAuth {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.canvas)
            } else if !isLoggedIn {
                LoginView(
                    viewModel: AuthViewModel(),
                    onLoginSuccess: { isLoggedIn = true }
                )
            } else {
                TabView(selection: $selectedTab) {
                    HomeView(viewModel: homeViewModel, onGymTap: { selectedTab = .gym })
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(AppDestination.home)

                    GymInfoView()
                        .tabItem { Label("Gym", systemImage: "building.2") }
                        .tag(AppDestination.gym)

                    ProfileView(
                        viewModel: ProfileViewModel(),
                        onSignOut: { isLoggedIn = false }
                    )
                    .tabItem { Label("Profile", systemImage: "person") }
                    .tag(AppDestination.profile)
                }
            }
        }
        .task {
            isLoggedIn = await AuthRepository().isLoggedIn
            isLoadingAuth = false
        }
    }
}
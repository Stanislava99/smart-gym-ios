//
//  AppNavigationView.swift
//  SmartGym
//

import SwiftUI

enum AppDestination: String, CaseIterable {
    case home = "Home"
    case workouts = "Workouts"
    case gym = "Gym"
    case profile = "Profile"
}

struct AppNavigationView: View {
    @State private var isLoggedIn = false
    @State private var isLoadingAuth = true
    @State private var selectedTab: AppDestination = .home
    @State private var showAddSheet = false
    @State private var workoutsViewModel = WorkoutsViewModel()

    var body: some View {
        Group {
            if isLoadingAuth {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !isLoggedIn {
                LoginView(
                    viewModel: AuthViewModel(),
                    onLoginSuccess: { isLoggedIn = true }
                )
            } else {
                ZStack(alignment: .bottomTrailing) {
                    TabView(selection: $selectedTab) {
                        HomeView(viewModel: HomeViewModel(), onGymTap: { selectedTab = .gym })
                            .tabItem { Label("Home", systemImage: "house") }
                            .tag(AppDestination.home)

                        WorkoutsView(viewModel: workoutsViewModel, onAddTapped: { showAddSheet = true })
                            .tabItem { Label("Workouts", systemImage: "figure.run") }
                            .tag(AppDestination.workouts)

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

                    if selectedTab == .home {
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(AppColors.surface)
                                .frame(width: 56, height: 56)
                                .background(AppColors.neutralDark)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.bottom, 80)
                    }
                }
                .sheet(isPresented: $showAddSheet) {
                    AddWorkoutSheet(viewModel: workoutsViewModel)
                }
            }
        }
        .task {
            isLoggedIn = await AuthRepository().isLoggedIn
            isLoadingAuth = false
        }
    }
}

// MARK: - Add Workout Sheet

private struct AddWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: WorkoutsViewModel

    @State private var title: String = ""
    @State private var date: String = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var exerciseSearchQuery: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.cardGap) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Add workout")
                        .font(.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Log a workout for a specific date.")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                }

                VStack(spacing: AppSpacing.sm) {
                    TextField("Workout name", text: $title)
                        .textFieldStyle(.roundedBorder)

                    TextField("Date (YYYY-MM-DD)", text: $date)
                        .textFieldStyle(.roundedBorder)

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Exercises")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    if viewModel.newWorkoutExercises.isEmpty {
                        Text("No exercises added yet.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        ForEach(viewModel.newWorkoutExercises) { exercise in
                            Text("\(exercise.name) – \(exercise.sets.count) sets")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    TextField("Search exercises", text: $exerciseSearchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: exerciseSearchQuery) { _, newValue in
                            Task {
                                await viewModel.searchExercises(query: newValue)
                            }
                        }

                    if viewModel.isSearchingExercises {
                        Text("Searching...")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    } else if !viewModel.searchResults.isEmpty {
                        let results = viewModel.searchResults
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(results, id: \.id) { exercise in
                                Button {
                                    viewModel.addExerciseFromSearch(exercise)
                                    exerciseSearchQuery = ""
                                    viewModel.searchResults = []
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .font(.subheadline)
                                                .foregroundStyle(AppColors.textPrimary)
                                            let subtitle = exercise.primaryMuscles.joined(separator: " • ")
                                            if !subtitle.isEmpty {
                                                Text(subtitle)
                                                    .font(.caption)
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Text("Add")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.accentLavender)
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    Task {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        isSaving = true
                        await viewModel.addWorkout(
                            title: title.trimmingCharacters(in: .whitespaces),
                            workoutDate: date,
                            notes: notes.isEmpty ? nil : notes
                        )
                        isSaving = false
                        viewModel.clearNewWorkoutExercises()
                        dismiss()
                    }
                } label: {
                    Text(isSaving ? "Saving..." : "Save workout")
                        .font(.headline)
                        .foregroundStyle(AppColors.surface)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.neutralDark)
                        .clipShape(Capsule())
                }
                .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(AppSpacing.base)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppColors.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColors.accentLavender)
                }
            }
        }
    }
}

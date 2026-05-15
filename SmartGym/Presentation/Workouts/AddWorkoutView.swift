//
//  AddWorkoutView.swift
//  SmartGym
//

import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: WorkoutsViewModel

    var onWorkoutSaved: (() -> Void)?

    @State private var title: String = ""
    @State private var suggestedTitle: String?
    @State private var selectedDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var exerciseSearchQuery: String = ""
    @State private var isSearchPresented: Bool = false
    @State private var detailWorkout: WorkoutIdentifier?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    headerSection

                    PrimaryCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            workoutMetaSection
                            Divider()
                            exercisesSection
                        }
                    }
                }
                .padding(AppSpacing.base)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .background(AppColors.canvas)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, AppSpacing.base)
                    .padding(.bottom, AppSpacing.base)
            }
            .sheet(isPresented: $isSearchPresented) {
                ExerciseSearchSheet(
                    query: $exerciseSearchQuery,
                    isPresented: $isSearchPresented,
                    viewModel: viewModel
                )
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(
                item: $detailWorkout,
                onDismiss: {
                    // After returning from workout details, go back to the originating tab.
                    dismiss()
                }
            ) { workout in
                NavigationStack {
                    WorkoutDetailView(workoutId: workout.id)
                }
            }
            .onAppear {
                if suggestedTitle == nil {
                    let base = makeSuggestedTitle(for: viewModel.newWorkoutExercises)
                    suggestedTitle = base
                    if title.trimmingCharacters(in: .whitespaces).isEmpty {
                        title = base
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Add workout")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
            Text("Log your workout with sets, reps, and weight.")
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var workoutMetaSection: some View {
        VStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Workout name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
                TextField("e.g. Full Body, Push", text: $title)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.neutralLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Date")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Notes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
                TextField("Optional notes about this workout", text: $notes, axis: .vertical)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.neutralLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .lineLimit(2...4)
            }
        }
    }

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Exercises")
                .font(.headline)
                .foregroundStyle(AppColors.textPrimary)

            if viewModel.newWorkoutExercises.isEmpty {
                Text("No exercises added yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(Array(viewModel.newWorkoutExercises.enumerated()), id: \.element.id) { index, exercise in
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(exercise.name)
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textPrimary)

                            if let subtitle = makeExerciseSubtitle(exercise), !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            // Sets editor
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                let isCardio = (exercise.bodyPart ?? "").localizedCaseInsensitiveContains("cardio")
                                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                                    HStack(spacing: AppSpacing.sm) {
                                        Text("Set \(set.setNumber)")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.textSecondary)
                                            .frame(width: 48, alignment: .leading)

                                        if isCardio {
                                            TextField(
                                                "Min",
                                                text: bindingForDuration(exerciseId: exercise.id, setIndex: setIndex)
                                            )
                                            .keyboardType(.numberPad)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(AppColors.neutralLight)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                            TextField(
                                                "Km",
                                                text: bindingForDistance(exerciseId: exercise.id, setIndex: setIndex)
                                            )
                                            .keyboardType(.decimalPad)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(AppColors.neutralLight)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                            TextField(
                                                "Stairs",
                                                text: bindingForStairs(exerciseId: exercise.id, setIndex: setIndex)
                                            )
                                            .keyboardType(.numberPad)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(AppColors.neutralLight)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        } else {
                                            TextField(
                                                "Reps",
                                                text: bindingForReps(exerciseId: exercise.id, setIndex: setIndex)
                                            )
                                            .keyboardType(.numberPad)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(AppColors.neutralLight)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                            TextField(
                                                "Kg",
                                                text: bindingForWeight(exerciseId: exercise.id, setIndex: setIndex)
                                            )
                                            .keyboardType(.decimalPad)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(AppColors.neutralLight)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                    }
                                }

                                HStack(spacing: AppSpacing.sm) {
                                    Button {
                                        addSet(to: exercise.id)
                                        updateSuggestedTitleIfNeeded()
                                    } label: {
                                        Text("Add set")
                                            .font(.caption)
                                            .foregroundStyle(AppColors.accentLavender)
                                    }

                                    if exercise.sets.count > 1 {
                                        Button {
                                            removeLastSet(from: exercise.id)
                                            updateSuggestedTitleIfNeeded()
                                        } label: {
                                            Text("Remove last")
                                                .font(.caption)
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
            }

            // Exercise search
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Add exercises")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)

                Button {
                    isSearchPresented = true
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                        Text(
                            exerciseSearchQuery.isEmpty
                                ? "Search exercises"
                                : exerciseSearchQuery
                        )
                        .foregroundStyle(
                            exerciseSearchQuery.isEmpty
                                ? AppColors.textSecondary
                                : AppColors.textPrimary
                        )
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppColors.neutralLight)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                isSaving = true
                do {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.dateFormat = "yyyy-MM-dd"
                    let isoDate = formatter.string(from: selectedDate)

                    let workout = try await viewModel.addWorkout(
                        title: title.trimmingCharacters(in: .whitespaces),
                        workoutDate: isoDate,
                        notes: notes.isEmpty ? nil : notes
                    )
                    viewModel.clearNewWorkoutExercises()
                    onWorkoutSaved?()
                    detailWorkout = WorkoutIdentifier(id: workout.id)
                } catch {
                    // Keep simple: surface error text via viewModel.error
                    viewModel.error = error.localizedDescription
                }
                isSaving = false
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

    // MARK: - Helpers

    private func makeExerciseSubtitle(_ exercise: WorkoutsViewModel.NewWorkoutExercise) -> String? {
        let parts = [
            exercise.bodyPart,
            exercise.targetMuscle,
            exercise.equipment
        ].compactMap { $0 }.filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " • ")
    }

    private func bindingForReps(exerciseId: UUID, setIndex: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return "" }
                let reps = viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].reps
                return reps.map { String($0) } ?? ""
            },
            set: { newValue in
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return }
                let intValue = Int(newValue)
                viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].reps = intValue
            }
        )
    }

    private func bindingForWeight(exerciseId: UUID, setIndex: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return "" }
                let weight = viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].weight
                return weight.map { String($0) } ?? ""
            },
            set: { newValue in
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return }
                let doubleValue = Double(newValue)
                viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].weight = doubleValue
            }
        )
    }

    private func bindingForDuration(exerciseId: UUID, setIndex: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return "" }
                let minutes = viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].durationMinutes
                return minutes.map { String($0) } ?? ""
            },
            set: { newValue in
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return }
                let intValue = Int(newValue)
                viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].durationMinutes = intValue
            }
        )
    }

    private func bindingForDistance(exerciseId: UUID, setIndex: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return "" }
                let distance = viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].distanceKm
                return distance.map { String($0) } ?? ""
            },
            set: { newValue in
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return }
                let doubleValue = Double(newValue)
                viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].distanceKm = doubleValue
            }
        )
    }

    private func bindingForStairs(exerciseId: UUID, setIndex: Int) -> Binding<String> {
        Binding<String>(
            get: {
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return "" }
                let stairs = viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].stairsClimbed
                return stairs.map { String($0) } ?? ""
            },
            set: { newValue in
                guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }),
                      viewModel.newWorkoutExercises[exerciseIndex].sets.indices.contains(setIndex)
                else { return }
                let intValue = Int(newValue)
                viewModel.newWorkoutExercises[exerciseIndex].sets[setIndex].stairsClimbed = intValue
            }
        )
    }

    private func addSet(to exerciseId: UUID) {
        guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        let currentSets = viewModel.newWorkoutExercises[exerciseIndex].sets
        let nextNumber = (currentSets.last?.setNumber ?? currentSets.count) + 1
        viewModel.newWorkoutExercises[exerciseIndex].sets.append(
            WorkoutsViewModel.NewWorkoutSet(
                setNumber: nextNumber,
                reps: nil,
                weight: nil
            )
        )
    }

    private func removeLastSet(from exerciseId: UUID) {
        guard let exerciseIndex = viewModel.newWorkoutExercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        guard viewModel.newWorkoutExercises[exerciseIndex].sets.count > 1 else { return }
        viewModel.newWorkoutExercises[exerciseIndex].sets.removeLast()
    }

    private func makeSuggestedTitle(for exercises: [WorkoutsViewModel.NewWorkoutExercise]) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5...11:
            timeOfDay = "Morning"
        case 12...17:
            timeOfDay = "Afternoon"
        default:
            timeOfDay = "Evening"
        }

        let names = exercises.map { ex in
            let source = (ex.bodyPart ?? "") + " " + (ex.targetMuscle ?? "")
            return source.lowercased()
        }

        let hasLower = names.contains { text in
            ["leg", "quad", "hamstring", "glute", "calf"].contains { key in text.contains(key) }
        }
        let hasUpper = names.contains { text in
            ["chest", "back", "shoulder", "bicep", "tricep", "arm"].contains { key in text.contains(key) }
        }

        let bodyLabel: String
        if hasUpper && hasLower {
            bodyLabel = "Full body"
        } else if hasLower {
            bodyLabel = "Lower body"
        } else if hasUpper {
            bodyLabel = "Upper body"
        } else {
            bodyLabel = "Workout"
        }

        return "\(timeOfDay) – \(bodyLabel)"
    }

    private func updateSuggestedTitleIfNeeded() {
        let newSuggestion = makeSuggestedTitle(for: viewModel.newWorkoutExercises)
        if title.trimmingCharacters(in: .whitespaces).isEmpty || title == suggestedTitle {
            title = newSuggestion
        }
        suggestedTitle = newSuggestion
    }
}

// MARK: - Exercise Search Sheet

private struct ExerciseSearchSheet: View {
    @Binding var query: String
    @Binding var isPresented: Bool
    @Bindable var viewModel: WorkoutsViewModel

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.textSecondary)
                    TextField("Search exercises", text: $query)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($isSearchFocused)
                        .onChange(of: query) { _, newValue in
                            Task {
                                await viewModel.searchExercises(query: newValue)
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppColors.neutralLight)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if viewModel.isSearchingExercises {
                    Text("Searching...")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if viewModel.searchResults.isEmpty, !query.isEmpty {
                    Text("No exercises found.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            ForEach(viewModel.searchResults, id: \.id) { exercise in
                                Button {
                                    viewModel.addExerciseFromSearch(exercise)
                                    query = ""
                                    viewModel.searchResults = []
                                    isPresented = false
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
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
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AppColors.accentLavender)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                }
                            }
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                }
                Spacer()
            }
            .padding(AppSpacing.base)
            .background(AppColors.canvas)
            .navigationTitle("Search exercises")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                isSearchFocused = true
                await viewModel.searchExercises(query: query)
            }
        }
    }
}

// MARK: - Helpers

private struct WorkoutIdentifier: Identifiable {
    let id: String
}




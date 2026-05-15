//
//  WorkoutDetailView.swift
//  SmartGym
//

import SwiftUI

struct WorkoutDetailView: View {
    let workoutId: String
    /// Called when this workout is deleted so the list can remove it without refetching.
    var onWorkoutDeleted: (() -> Void)?
    /// Called when this workout is updated so the list can update that item without refetching.
    var onWorkoutUpdated: ((MemberWorkout) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var workout: MemberWorkout?
    @State private var trainedMuscles: [Exercise.MuscleId: Int] = [:]
    @State private var exercises: [WorkoutExerciseDetail] = []
    @State private var totalKg: Double = 0
    @State private var totalSets: Int = 0
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var isEditing = false
    @State private var editTitle: String = ""
    @State private var editDate: String = ""
    @State private var editNotes: String = ""
    @State private var isSavingEdit = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    /// Load exercises only once per workout; skip refetch when switching back to this tab.
    @State private var loadedWorkoutId: String?
    private let workoutRepository = WorkoutRepository()
    private let exerciseService = ExerciseService.shared

    var body: some View {
        Group {
            if isLoading {
                WorkoutDetailLoadingView()
            } else if let error = loadError {
                ErrorWithRetryView(message: error) {
                    Task { await loadDetail(forceRefresh: true) }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text(workout?.title ?? "Workout summary")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)

                                if let workout {
                                    if let notes = workout.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.body)
                                            .foregroundStyle(AppColors.textSecondary)
                                            .padding(.top, AppSpacing.xs)
                                    }
                                }
                                if let date = workout?.workoutDate {
                                    Text(Self.formattedDate(date))
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }

                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack(spacing: AppSpacing.sm) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.accentBlue)
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "dumbbell")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Total volume")
                                            .font(.headline)
                                            .foregroundStyle(AppColors.textPrimary)
                                        Text("\(Int(totalKg)) kg lifted")
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                }

                                if let primary = primaryMusclesLabel {
                                    Text("Primary: \(primary)")
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                if let secondary = secondaryMusclesLabel {
                                    Text("Secondary: \(secondary)")
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.textSecondary)
                                }

                                if totalSets > 0 {
                                    let averagePerSet = totalKg / Double(totalSets)
                                    Text("\(totalSets) sets across \(exercises.count) exercises · avg \(Int(averagePerSet)) kg per set")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                            }
                        }

                        if !exercises.isEmpty {
                            PrimaryCard {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Exercises")
                                        .font(.headline)
                                        .foregroundStyle(AppColors.textPrimary)
                                    ForEach(exercises, id: \.id) { exercise in
                                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                            Text(exercise.name)
                                                .font(.subheadline)
                                                .foregroundStyle(AppColors.textPrimary)
                                            ForEach(exercise.sets, id: \.setNumber) { set in
                                                Text("\(set.reps ?? 0) × \(set.weight ?? 0, specifier: "%.1f") kg")
                                                    .font(.caption)
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.base)
                }
                .refreshable {
                    loadedWorkoutId = nil
                    await loadDetail(forceRefresh: true)
                }
            }
        }
        .background(AppColors.canvas)
        .navigationTitle(workout?.title ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") {
                        guard let workout else { return }
                        editTitle = workout.title
                        editDate = workout.workoutDate
                        editNotes = workout.notes ?? ""
                        isEditing = true
                    }
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete workout")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .task(id: workoutId) {
            await loadDetail()
        }
        .alert("Delete workout?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button(isDeleting ? "Deleting..." : "Delete", role: .destructive) {
                guard !isDeleting else { return }
                Task {
                    isDeleting = true
                    do {
                        try await workoutRepository.deleteWorkout(id: workoutId)
                        await MainActor.run {
                            onWorkoutDeleted?()
                            dismiss()
                        }
                    } catch {
                        // Keep simple for now; surface via best-effort navigation-only feedback.
                    }
                    isDeleting = false
                }
            }
        } message: {
            Text("This will remove this workout and all of its sets.")
        }
        .sheet(isPresented: $isEditing) {
            EditWorkoutSheet(
                title: $editTitle,
                date: $editDate,
                notes: $editNotes,
                isSaving: $isSavingEdit,
                onSave: {
                    guard !editTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    Task {
                        isSavingEdit = true
                        do {
                            let updated = try await workoutRepository.updateWorkout(
                                id: workoutId,
                                title: editTitle.trimmingCharacters(in: .whitespaces),
                                workoutDate: editDate,
                                notes: editNotes.isEmpty ? nil : editNotes
                            )
                            await MainActor.run {
                                workout = updated
                                onWorkoutUpdated?(updated)
                                isEditing = false
                            }
                        } catch {
                            // Keep simple: ignore for now; could be surfaced via a dedicated error state.
                        }
                        isSavingEdit = false
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .onChange(of: workoutId) {
            loadedWorkoutId = nil
        }
    }

    @MainActor
    private func loadDetail(forceRefresh: Bool = false) async {
        // Refetch only when opening a different workout (or first load). Don't refetch on tab re-appear.
        if !forceRefresh, loadedWorkoutId == workoutId, !exercises.isEmpty {
            isLoading = false
            return
        }
        loadedWorkoutId = workoutId
        isLoading = true
        loadError = nil
        await ExerciseService.shared.loadIfNeeded()
        do {
            let loaded = try await workoutRepository.getWorkout(id: workoutId)
            guard let loaded else {
                loadError = "Workout not found."
                isLoading = false
                return
            }
            workout = loaded
            let ids = await workoutRepository.getExerciseExternalIds(forWorkoutId: workoutId)
            trainedMuscles = exerciseService.computeTrainedMuscles(forExerciseIds: ids)
            let details = try await workoutRepository.getWorkoutExercisesWithSets(workoutId: workoutId)
            exercises = details
            let allSets = details.flatMap { $0.sets }
            totalSets = allSets.count
            totalKg = allSets.reduce(0) { sum, set in
                let reps = Double(set.reps ?? 0)
                let weight = set.weight ?? 0
                return sum + reps * weight
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

private extension WorkoutDetailView {
    private var sortedTrainedMuscles: [(key: Exercise.MuscleId, value: Int)] {
        trainedMuscles
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in lhs.value > rhs.value }
    }

    private var primaryMusclesLabel: String? {
        let names = sortedTrainedMuscles
            .prefix(2)
            .map { muscleDisplayName(for: $0.key) }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    private var secondaryMusclesLabel: String? {
        let names = sortedTrainedMuscles
            .dropFirst(2)
            .prefix(3)
            .map { muscleDisplayName(for: $0.key) }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }

    private func muscleDisplayName(for id: Exercise.MuscleId) -> String {
        switch id {
        case "chest": return "Chest"
        case "back": return "Back"
        case "shoulders": return "Shoulders"
        case "biceps": return "Biceps"
        case "triceps": return "Triceps"
        case "core": return "Core"
        case "glutes": return "Glutes"
        case "quads": return "Quads"
        case "hamstrings": return "Hamstrings"
        case "calves": return "Calves"
        default:
            return id.capitalized
        }
    }
}

private struct WorkoutDetailLoadingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 160)
                        SkeletonView(height: 80)
                            .frame(maxWidth: .infinity)
                    }
                }
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 140)
                        SkeletonView(height: 14)
                            .frame(width: 200)
                        SkeletonView(height: 14)
                            .frame(width: 120)
                    }
                }
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 80)
                        SkeletonView(height: 14)
                            .frame(width: 180)
                        SkeletonView(height: 14)
                            .frame(width: 160)
                    }
                }
            }
            .padding(AppSpacing.base)
        }
    }
}

private extension WorkoutDetailView {
    static func formattedDate(_ isoDate: String) -> String {
        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = isoFormatter.date(from: isoDate) else { return isoDate }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}

// MARK: - Detail models

struct WorkoutExerciseDetail {
    struct WorkoutSetDetail {
        let setNumber: Int
        let reps: Int?
        let weight: Double?
    }

    let id: String
    let name: String
    let sets: [WorkoutSetDetail]
}

// MARK: - Edit sheet

private struct EditWorkoutSheet: View {
    @Binding var title: String
    @Binding var date: String
    @Binding var notes: String
    @Binding var isSaving: Bool

    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout info") {
                    TextField("Workout name", text: $title)
                    TextField("Date (YYYY-MM-DD)", text: $date)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle("Edit workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSave()
                    } label: {
                        Text(isSaving ? "Saving..." : "Save")
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}


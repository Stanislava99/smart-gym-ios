//
//  EditProfileView.swift
//  SmartGym
//
//  Design system: Primary card, rounded inputs, accent button
//  Edit name, surname, image, start weight, goal
//

import SwiftUI
import PhotosUI
import UIKit

struct EditProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = ""
    @State private var selectedBirthDate = Self.defaultBirthDate
    @State private var isBirthDatePickerPresented = false
    @State private var heightCm = ""
    @State private var weightKg = ""
    @State private var goal = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    /// True while the library item is being decoded (avoid saving before bytes are ready).
    @State private var isResolvingPhoto = false
    /// After a successful explicit Save+dismiss we skip autosave because data is already persisted.
    @State private var suppressDisappearAutosaveBecauseSaveSucceeded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                    // Profile image picker
                    PrimaryCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Profile Photo")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            HStack(spacing: AppSpacing.base) {
                                PhotosPicker(
                                    selection: $selectedPhoto,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Group {
                                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } else if let urlString = viewModel.member?.avatarUrl, let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                default:
                                                    avatarPlaceholder
                                                }
                                            }
                                        } else {
                                            avatarPlaceholder
                                        }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                }
                                .onChange(of: selectedPhoto) { _, newItem in
                                    Task {
                                        await MainActor.run {
                                            isResolvingPhoto = newItem != nil
                                        }
                                        guard let item = newItem else {
                                            await MainActor.run {
                                                selectedImageData = nil
                                                isResolvingPhoto = false
                                            }
                                            return
                                        }
                                        defer {
                                            Task { @MainActor in
                                                isResolvingPhoto = false
                                            }
                                        }
                                        if let raw = try? await item.loadTransferable(type: Data.self),
                                           let normalized = Self.normalizePhotoData(raw) {
                                            await MainActor.run {
                                                selectedImageData = normalized
                                            }
                                        }
                                    }
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Change photo")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppColors.accentLavender)
                                    Text("Tap to select from library")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }

                    PrimaryCard {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            AppTextInput(title: "First name", text: $firstName)
                            AppTextInput(title: "Last name", text: $lastName)
                            birthDatePicker
                            AppTextInput(title: "Height (cm)", text: $heightCm, keyboardType: .decimalPad)
                            AppTextInput(title: "Start weight (kg)", text: $weightKg, keyboardType: .decimalPad)
                            AppTextInput(
                                title: "Goal (kg or description)",
                                text: $goal,
                                axis: .vertical,
                                lineLimit: 2...4
                            )
                        }
                    }

                    if let err = viewModel.error, !err.isEmpty {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            let saved = await persistProfileChanges()
                            if saved {
                                suppressDisappearAutosaveBecauseSaveSucceeded = true
                                dismiss()
                            }
                        }
                    } label: {
                        Text(saveButtonTitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.accentLavender)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .disabled(viewModel.isSaving || isResolvingPhoto)
                }
                .padding(AppSpacing.base)
            }
            .background(AppColors.canvas)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.error = nil
                viewModel.startEditProfile()
                populateForm(from: viewModel.editProfileState)
            }
            .onChange(of: viewModel.editProfileState) { _, newEdit in
                populateForm(from: newEdit)
            }
            .onDisappear {
                guard viewModel.member != nil else { return }
                guard !suppressDisappearAutosaveBecauseSaveSucceeded else {
                    suppressDisappearAutosaveBecauseSaveSucceeded = false
                    return
                }
                guard !viewModel.isSaving else { return }
                Task {
                    _ = await persistProfileChanges()
                }
            }
        }
    }

    private func persistProfileChanges() async -> Bool {
        viewModel.updateEdit(EditProfileState(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            birthDate: birthDate.trimmingCharacters(in: .whitespacesAndNewlines),
            heightCm: Double(heightCm.trimmingCharacters(in: .whitespacesAndNewlines)),
            weightKg: Double(weightKg.trimmingCharacters(in: .whitespacesAndNewlines)),
            goal: goal.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        let imageToUpload = selectedImageData.flatMap { Self.normalizePhotoData($0) }
        let saved = await viewModel.saveProfile(avatarImageData: imageToUpload)
        return saved
    }

    /// Re-encode picker output as JPEG so storage content-type matches bytes (fixes HEIF/PNG from library).
    private static func normalizePhotoData(_ data: Data) -> Data? {
        if data.isEmpty { return nil }
        guard let ui = UIImage(data: data) else {
            return data
        }
        return ui.jpegData(compressionQuality: 0.88) ?? data
    }

    private var birthDatePicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Birth date")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)

            Button {
                isBirthDatePickerPresented = true
            } label: {
                HStack {
                    Text(birthDate.isEmpty ? "Select birth date" : Self.displayDateFormatter.string(from: selectedBirthDate))
                        .font(.body)
                        .foregroundStyle(birthDate.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.body.weight(.medium))
                        .foregroundStyle(AppColors.accentLavender)
                }
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.md)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background(AppColors.neutralLight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isBirthDatePickerPresented) {
                NavigationStack {
                    DatePicker(
                        "Birth date",
                        selection: $selectedBirthDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(AppColors.accentLavender)
                    .padding(AppSpacing.base)
                    .navigationTitle("Birth date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                birthDate = Self.birthDateFormatter.string(from: selectedBirthDate)
                                isBirthDatePickerPresented = false
                            }
                            .foregroundStyle(AppColors.accentLavender)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func populateForm(from edit: EditProfileState?) {
        guard let edit else { return }
        firstName = edit.firstName
        lastName = edit.lastName
        birthDate = edit.birthDate
        selectedBirthDate = Self.birthDateFormatter.date(from: edit.birthDate) ?? Self.defaultBirthDate
        heightCm = edit.heightCm.map { String($0) } ?? ""
        weightKg = edit.weightKg.map { String($0) } ?? ""
        goal = edit.goal
    }

    private static let defaultBirthDate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()

    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter
    }()

    private var avatarPlaceholder: some View {
        Circle()
            .fill(AppColors.accentLavender.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(AppColors.accentLavender)
            }
    }

    private var saveButtonTitle: String {
        if viewModel.isSaving { return "Saving..." }
        if isResolvingPhoto { return "Preparing photo..." }
        return "Save"
    }
}

//
//  EditProfileView.swift
//  SmartGym
//
//  Design system: Primary card, rounded inputs, accent button
//  Edit name, surname, image, start weight, goal
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = ""
    @State private var heightCm = ""
    @State private var weightKg = ""
    @State private var goal = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?

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
                                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                            selectedImageData = data
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
                            TextField("First name", text: $firstName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Last name", text: $lastName)
                                .textFieldStyle(.roundedBorder)
                            TextField("Age", text: $age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("Height (cm)", text: $heightCm)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("Start weight (kg)", text: $weightKg)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("Goal (kg or description)", text: $goal, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Button {
                        viewModel.updateEdit(
                            firstName: firstName.isEmpty ? nil : firstName,
                            lastName: lastName.isEmpty ? nil : lastName,
                            age: Int(age),
                            heightCm: Double(heightCm),
                            weightKg: Double(weightKg),
                            goal: goal.isEmpty ? nil : goal
                        )
                        Task {
                            await viewModel.saveProfile(avatarImageData: selectedImageData)
                            dismiss()
                        }
                    } label: {
                        Text(viewModel.isSaving ? "Saving..." : "Save")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.accentLavender)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .disabled(viewModel.isSaving)
                }
                .padding(AppSpacing.base)
            }
            .background(AppColors.canvas)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .onAppear { viewModel.startEditProfile() }
            .onChange(of: viewModel.editProfileState) { _, newEdit in
                guard let e = newEdit else { return }
                firstName = e.firstName
                lastName = e.lastName
                age = e.age.map { String($0) } ?? ""
                heightCm = e.heightCm.map { String($0) } ?? ""
                weightKg = e.weightKg.map { String($0) } ?? ""
                goal = e.goal
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(AppColors.accentLavender.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(AppColors.accentLavender)
            }
    }
}

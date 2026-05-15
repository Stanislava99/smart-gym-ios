//
//  SchedulePTView.swift
//  SmartGym
//

import SwiftUI

struct SchedulePTView: View {
    @Bindable var homeViewModel: HomeViewModel
    @State private var scheduleViewModel = SchedulePTViewModel()

    var body: some View {
        Group {
            if scheduleViewModel.isLoading {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                        SkeletonView(height: 28)
                            .frame(width: 280)
                        SkeletonView(height: 18)
                            .frame(maxWidth: .infinity)
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                SkeletonView(height: 18)
                                    .frame(width: 140)
                                HStack(spacing: AppSpacing.sm) {
                                    SkeletonView(height: 34)
                                        .frame(width: 96)
                                    SkeletonView(height: 34)
                                        .frame(width: 112)
                                    SkeletonView(height: 34)
                                        .frame(width: 88)
                                }
                            }
                        }
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                SkeletonView(height: 18)
                                    .frame(width: 120)
                                SkeletonView(height: 44)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                SkeletonView(height: 18)
                                    .frame(width: 150)
                                SkeletonView()
                                    .frame(height: 96)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        SkeletonView(height: 48)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.screenVertical)
                }
            } else if let error = scheduleViewModel.error {
                VStack(spacing: AppSpacing.md) {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                    Button("Try again") {
                        Task { await scheduleViewModel.loadTrainers(member: homeViewModel.member) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppSpacing.screenHorizontal)
            } else if scheduleViewModel.trainers.isEmpty {
                VStack {
                    PrimaryCard {
                        Text("Your gym doesn’t have personal trainers.")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, AppSpacing.screenHorizontal)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                        Text("Schedule a meeting with a personal trainer")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Send your details and a trainer will contact you.")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)

                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Choose a trainer")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: AppSpacing.sm) {
                                        ForEach(scheduleViewModel.trainers, id: \.id) { trainer in
                                            let isSelected = scheduleViewModel.selectedTrainerId == trainer.id
                                            Button {
                                                scheduleViewModel.selectedTrainerId = trainer.id
                                            } label: {
                                                Text(trainer.fullName)
                                                    .font(.subheadline)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: AppRadius.sm)
                                                            .fill(isSelected ? AppColors.accentLavender : AppColors.neutralLight)
                                                    )
                                                    .foregroundStyle(isSelected ? Color.white : AppColors.textPrimary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Preferred time")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                TextField("When would you like to meet?", text: $scheduleViewModel.preferredTime)
                                    .textFieldStyle(.plain)
                                    .padding(.vertical, 8)
                            }
                        }

                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Additional details")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                TextField(
                                    "Share your goals or availability…",
                                    text: $scheduleViewModel.message,
                                    axis: .vertical
                                )
                                .lineLimit(3...6)
                                .textFieldStyle(.plain)
                                .padding(.vertical, 8)
                            }
                        }

                        if scheduleViewModel.requestSent {
                            Text("Request sent. Your trainer will contact you.")
                                .font(.body)
                                .foregroundStyle(AppColors.accentMint)
                        }

                        Button {
                            Task {
                                await scheduleViewModel.submitRequest(member: homeViewModel.member, gym: homeViewModel.gym)
                            }
                        } label: {
                            if scheduleViewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send request")
                                    .font(.headline)
                            }
                        }
                        .disabled(scheduleViewModel.isSubmitting || !scheduleViewModel.canSubmit)
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.screenVertical)
                }
            }
        }
        .background(AppColors.canvas)
        .navigationTitle("Schedule with trainer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await scheduleViewModel.loadTrainers(member: homeViewModel.member)
        }
    }
}


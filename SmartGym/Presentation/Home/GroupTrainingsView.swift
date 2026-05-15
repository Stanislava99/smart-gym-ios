//
//  GroupTrainingsView.swift
//  SmartGym
//

import SwiftUI

struct GroupTrainingsView: View {
    let groups: [GroupTraining]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Available group trainings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)

                if groups.isEmpty {
                    PrimaryCard {
                        Text("No group trainings are available at this gym yet.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    ForEach(groups) { group in
                        GroupTrainingCard(group: group)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.screenVertical)
        }
        .background(AppColors.canvas)
        .navigationTitle("Group Trainings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GroupTrainingCard: View {
    let group: GroupTraining

    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(group.title)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text(priceText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Text("Trainer: \(group.trainerName ?? "TBA")")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                if !group.slots.isEmpty {
                    Text(group.slots.map(formatSlot).joined(separator: "\n"))
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let description = group.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var priceText: String {
        group.price == 0 ? "Free" : String(format: "%.2f", group.price)
    }

    private func formatSlot(_ slot: GroupTrainingSlot) -> String {
        let start = String(slot.startTime.prefix(5))
        let end = slot.endTime.map { " - \(String($0.prefix(5)))" } ?? ""
        return "\(weekdayName(slot.weekday)) \(start)\(end)"
    }

    private func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 0: return "Sunday"
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        default: return "Day \(weekday)"
        }
    }
}

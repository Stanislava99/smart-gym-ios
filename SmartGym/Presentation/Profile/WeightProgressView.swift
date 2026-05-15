//
//  WeightProgressView.swift
//  SmartGym
//

import Charts
import SwiftUI

struct WeightProgressView: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var weightKg = ""
    @State private var loggedAt = Date()
    @State private var notes = ""

    private var logs: [MemberWeightLog] {
        viewModel.weightLogs.sorted { $0.loggedDate < $1.loggedDate }
    }

    private var latestWeight: Double? {
        logs.last?.weightKg ?? viewModel.member?.weightKg
    }

    private var startWeight: Double? {
        viewModel.member?.weightKg
    }

    private var progressText: String {
        guard let startWeight, let latestWeight else { return "Log your first weight to start tracking." }
        let delta = latestWeight - startWeight
        if abs(delta) < 0.05 {
            return "No change from your start weight yet."
        }
        return "\(delta > 0 ? "+" : "")\(String(format: "%.1f", delta)) kg from start"
    }

    private var parsedWeight: Double? {
        Double(weightKg.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                summaryCard
                logWeightCard
                chartCard
                recentLogsCard
            }
            .padding(AppSpacing.base)
        }
        .background(AppColors.canvas)
        .navigationTitle("Weight Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadWeightLogs()
        }
        .refreshable {
            await viewModel.loadWeightLogs()
        }
    }

    private var summaryCard: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Progress")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: AppSpacing.sm) {
                    WeightSummaryItem(title: "Start", value: formattedWeight(startWeight))
                    WeightSummaryItem(title: "Latest", value: formattedWeight(latestWeight))
                    WeightSummaryItem(title: "Entries", value: "\(logs.count)")
                }

                Text(progressText)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var logWeightCard: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Log Weight")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                AppTextInput(title: "Weight (kg)", text: $weightKg, keyboardType: .decimalPad)

                DatePicker("Date", selection: $loggedAt, in: ...Date(), displayedComponents: .date)
                    .font(.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .tint(AppColors.accentLavender)

                AppTextInput(
                    title: "Notes",
                    text: $notes,
                    axis: .vertical,
                    lineLimit: 2...4
                )

                if let error = viewModel.weightLogError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    saveWeight()
                } label: {
                    Text(viewModel.isSavingWeightLog ? "Saving..." : "Add entry")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(canSave ? AppColors.accentLavender : AppColors.textTertiary)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
                .disabled(!canSave || viewModel.isSavingWeightLog)
            }
        }
    }

    private var chartCard: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Trend")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                if viewModel.isLoadingWeightLogs {
                    SkeletonView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                } else if logs.isEmpty {
                    emptyTrendView
                } else {
                    Chart {
                        if let startWeight {
                            RuleMark(y: .value("Start weight", startWeight))
                                .foregroundStyle(AppColors.accentMint)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Start")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(AppColors.accentMint)
                                }
                        }

                        ForEach(logs) { log in
                            LineMark(
                                x: .value("Date", log.loggedDate),
                                y: .value("Weight", log.weightKg)
                            )
                            .foregroundStyle(AppColors.accentLavender)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", log.loggedDate),
                                y: .value("Weight", log.weightKg)
                            )
                            .foregroundStyle(AppColors.accentLavender)
                        }
                    }
                    .chartYAxisLabel("kg")
                    .frame(height: 220)
                }
            }
        }
    }

    private var recentLogsCard: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Recent Entries")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)

                if logs.isEmpty {
                    Text("No weight entries yet.")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ForEach(logs.suffix(6).reversed()) { log in
                        WeightLogRow(log: log)
                        if log.id != logs.suffix(6).first?.id {
                            Divider()
                                .background(AppColors.borderSubtle)
                        }
                    }
                }
            }
        }
    }

    private var emptyTrendView: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title2)
                .foregroundStyle(AppColors.accentLavender)
            Text("Your progress graph will appear after your first log.")
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }

    private var canSave: Bool {
        guard let parsedWeight else { return false }
        return parsedWeight > 0 && parsedWeight < 500
    }

    private func saveWeight() {
        guard let parsedWeight else { return }
        Task {
            let saved = await viewModel.saveWeightLog(
                weightKg: parsedWeight,
                loggedAt: loggedAt,
                notes: notes
            )
            if saved {
                weightKg = ""
                notes = ""
                loggedAt = Date()
            }
        }
    }

    private func formattedWeight(_ value: Double?) -> String {
        value.map { String(format: "%.1f kg", $0) } ?? "—"
    }
}

private struct WeightSummaryItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColors.neutralLight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

private struct WeightLogRow: View {
    let log: MemberWeightLog

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.displayDateFormatter.string(from: log.loggedDate))
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer()
            Text(String(format: "%.1f kg", log.weightKg))
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.accentLavender)
        }
        .padding(.vertical, AppSpacing.sm)
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        return formatter
    }()
}

//
//  PaymentHistoryView.swift
//  SmartGym
//

import SwiftUI

struct PaymentHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaymentHistoryViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                PaymentHistoryLoadingView()
            } else if let error = viewModel.error {
                ErrorWithRetryView(message: error) {
                    Task { await viewModel.load() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                        Text("Payment History")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.textPrimary)

                        if let member = viewModel.member {
                            CurrentPaymentStatusCard(member: member)
                        }

                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                HStack {
                                    Text("Recent Payments")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Spacer()
                                    Text("\(viewModel.payments.count) total")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                                if viewModel.payments.isEmpty {
                                    EmptyPaymentsState()
                                } else {
                                    ForEach(viewModel.payments.indices, id: \.self) { index in
                                        let payment = viewModel.payments[index]
                                        PaymentHistoryRow(payment: payment)
                                        if index < viewModel.payments.count - 1 {
                                            Divider()
                                                .background(AppColors.borderSubtle.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.base)
                }
            }
        }
        .background(AppColors.canvas)
        .navigationTitle("Payment History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CurrentPaymentStatusCard: View {
    let member: Member

    private var normalizedStatus: String {
        member.status.lowercased()
    }

    private var statusColor: Color {
        switch normalizedStatus {
        case "active": return AppColors.accentMint
        case "expired": return AppColors.accentPeach
        default: return AppColors.accentBlue
        }
    }

    private var statusDescription: String {
        switch normalizedStatus {
        case "active": return "Membership is active"
        case "expired": return "Membership needs renewal"
        default: return "Membership status"
        }
    }

    private var validUntil: String {
        guard let endDate = member.subscriptionEndDate, !endDate.isEmpty else {
            return "No end date"
        }
        return PaymentDisplayFormatter.date(endDate)
    }

    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Current Status")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(statusDescription)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Text(member.status.displayLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.neutralDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(statusColor)
                        .clipShape(Capsule())
                }

                HStack {
                    Text("Valid until")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text(validUntil)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.neutralLight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }
        }
    }
}

private struct PaymentHistoryRow: View {
    let payment: Payment

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            PaymentDateBadge(date: payment.paymentDate)

            VStack(alignment: .leading, spacing: 2) {
                Text(payment.paymentMethod.paymentMethodLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(PaymentDisplayFormatter.date(payment.paymentDate))
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text(PaymentDisplayFormatter.amount(payment.amount))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

private struct PaymentDateBadge: View {
    let date: String

    private var parsedDate: Date? {
        PaymentDisplayFormatter.parseDate(date)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(parsedDate.map { PaymentDisplayFormatter.month($0) } ?? "PAY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
            Text(parsedDate.map { PaymentDisplayFormatter.day($0) } ?? "--")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(width: 58, height: 58)
        .background(AppColors.neutralLight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

private struct EmptyPaymentsState: View {
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("No payments yet")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
            Text("Your completed payments will appear here.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.neutralLight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}

private enum PaymentDisplayFormatter {
    static func amount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount.rounded()))"
    }

    static func date(_ date: String) -> String {
        guard let parsedDate = parseDate(date) else {
            return date
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: parsedDate)
    }

    static func month(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func parseDate(_ date: String) -> Date? {
        if let isoDate = ISO8601DateFormatter().date(from: date) {
            return isoDate
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let parsedDate = formatter.date(from: date) {
            return parsedDate
        }

        guard date.count >= 10 else {
            return nil
        }
        return formatter.date(from: String(date.prefix(10)))
    }
}

private extension String {
    var displayLabel: String {
        split { $0 == "_" || $0 == "-" || $0 == " " }
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

private extension Optional where Wrapped == String {
    var paymentMethodLabel: String {
        switch self?.lowercased() {
        case "cash": return "Cash payment"
        case "card": return "Card payment"
        case "bank_transfer": return "Bank transfer"
        case "other": return "Other payment"
        case nil, "": return "Payment"
        default: return self?.displayLabel ?? "Payment"
        }
    }
}

// MARK: - Payment history loading (skeleton matching content)

private struct PaymentHistoryLoadingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                SkeletonView(height: 24)
                    .frame(width: 180)
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 120)
                        SkeletonView(height: 14)
                            .frame(width: 160)
                    }
                }
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 140)
                        SkeletonView(height: 14)
                            .frame(maxWidth: .infinity)
                        SkeletonView(height: 14)
                            .frame(width: 200)
                    }
                }
            }
            .padding(AppSpacing.base)
        }
    }
}

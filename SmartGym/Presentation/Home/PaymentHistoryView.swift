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
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                        Text("Payment History")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.textPrimary)

                        if let member = viewModel.member {
                            PrimaryCard {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Current Status")
                                        .font(.headline)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text("Status: \(member.status)")
                                        .font(.body)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }

                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Recent Payments")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                if viewModel.payments.isEmpty {
                                    Text("No payments yet")
                                        .font(.body)
                                        .foregroundStyle(AppColors.textSecondary)
                                } else {
                                    ForEach(viewModel.payments, id: \.id) { payment in
                                        Text("\(payment.paymentDate): \(payment.amount)")
                                            .font(.body)
                                            .foregroundStyle(AppColors.textSecondary)
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

//
//  ErrorWithRetryView.swift
//  SmartGym
//
//  Shared error state: message + retry button.
//

import SwiftUI

struct ErrorWithRetryView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(message)
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: retry)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.accentLavender)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}

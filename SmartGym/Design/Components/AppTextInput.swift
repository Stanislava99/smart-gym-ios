//
//  AppTextInput.swift
//  SmartGym
//
//  Rounded input style aligned with DESIGN_SYSTEM_PROFILE.md.
//

import SwiftUI

struct AppTextInput: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textInputAutocapitalization: TextInputAutocapitalization = .sentences
    var textContentType: UITextContentType? = nil
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)

            inputField
                .font(.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.md)
                .frame(minHeight: 48)
                .background(AppColors.neutralLight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var inputField: some View {
        if let lineLimit {
            TextField(title, text: $text, axis: axis)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .applyTextContentType(textContentType)
                .lineLimit(lineLimit)
        } else {
            TextField(title, text: $text, axis: axis)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(textInputAutocapitalization)
                .applyTextContentType(textContentType)
        }
    }
}

/// Password field matching `AppTextInput` styling (DESIGN_SYSTEM_PROFILE.md).
struct AppSecureTextInput: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)

            SecureField(title, text: $text)
                .textContentType(.password)
                .font(.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.md)
                .frame(minHeight: 48)
                .background(AppColors.neutralLight)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(AppColors.borderSubtle, lineWidth: 1)
                )
        }
    }
}

private extension View {
    @ViewBuilder
    func applyTextContentType(_ type: UITextContentType?) -> some View {
        if let type {
            self.textContentType(type)
        } else {
            self
        }
    }
}

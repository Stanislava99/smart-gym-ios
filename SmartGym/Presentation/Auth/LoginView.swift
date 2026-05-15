//
//  LoginView.swift
//  SmartGym
//

import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    var onLoginSuccess: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                VStack(spacing: AppSpacing.md) {
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)

                    Text("Smart Gym")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Member App")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.sm)

                VStack(alignment: .leading, spacing: AppSpacing.base) {
                    if viewModel.isLoading {
                        LoginLoadingView()
                    } else {
                        AppTextInput(
                            title: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textInputAutocapitalization: .never,
                            textContentType: .emailAddress
                        )

                        AppSecureTextInput(title: "Password", text: $password)

                        if let error = viewModel.error {
                            Text(error)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                                if viewModel.isLoggedIn { onLoginSuccess() }
                            }
                        } label: {
                            Text("Sign In")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.surface)
                        .background(AppColors.accentLavender)
                        .clipShape(Capsule())
                        .padding(.top, AppSpacing.sm)
                    }
                }
                .padding(AppSpacing.base)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.xxl)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.canvas.ignoresSafeArea())
        .onChange(of: viewModel.isLoggedIn) { _, loggedIn in
            if loggedIn { onLoginSuccess() }
        }
    }
}

private struct LoginLoadingView: View {
    var body: some View {
        VStack(spacing: AppSpacing.base) {
            SkeletonView(height: 48)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            SkeletonView(height: 48)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            SkeletonView(height: 48)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        }
    }
}

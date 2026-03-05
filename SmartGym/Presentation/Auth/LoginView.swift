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
            VStack(spacing: 24) {
                Text("Smart Gym")
                    .font(.largeTitle)
                Text("Member App")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    if let error = viewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("Sign In") {
                            Task {
                                await viewModel.signIn(email: email, password: password)
                                if viewModel.isLoggedIn { onLoginSuccess() }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .padding()
        }
        .onChange(of: viewModel.isLoggedIn) { _, loggedIn in
            if loggedIn { onLoginSuccess() }
        }
    }
}

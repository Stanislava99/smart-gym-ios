//
//  AuthViewModel.swift
//  SmartGym
//

import Foundation

@MainActor
@Observable
final class AuthViewModel {
    var isLoading = false
    var error: String?
    var isLoggedIn = false

    private let authRepository = AuthRepository()

    init() {
        Task { await checkAuthState() }
    }

    func checkAuthState() async {
        isLoggedIn = await authRepository.isLoggedIn
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            try await authRepository.signIn(email: email, password: password)
            isLoggedIn = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            try await authRepository.signUp(email: email, password: password)
            isLoggedIn = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        try? await authRepository.signOut()
        isLoggedIn = false
    }

    func clearError() {
        error = nil
    }
}

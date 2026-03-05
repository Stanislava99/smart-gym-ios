//
//  AuthRepository.swift
//  SmartGym
//

import Foundation
import Supabase

final class AuthRepository {
    private let client = AppSupabase.client

    var currentSession: Session? {
        get async { try? await client.auth.session }
    }

    var currentUser: User? {
        get async { try? await client.auth.session.user }
    }

    var isLoggedIn: Bool {
        get async { (try? await client.auth.session) != nil }
    }

    func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
}

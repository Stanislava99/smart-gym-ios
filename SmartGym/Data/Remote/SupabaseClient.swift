//
//  SupabaseClient.swift
//  SmartGym
//
//  Created for Smart Gym member app.
//

import Foundation
import Supabase

enum AppSupabase {
    static let anonKey: String = {
        // 1. From Config.plist (edit Config.plist with your anon key from Supabase Dashboard -> API)
        if let configURL = Bundle.main.url(forResource: "Config", withExtension: "plist"),
           let data = try? Data(contentsOf: configURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let k = plist["SUPABASE_ANON_KEY"] as? String, !k.isEmpty, !k.contains("REPLACE") {
            return k
        }
        // 2. From environment (Xcode scheme -> Run -> Environment Variables)
        if let k = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !k.isEmpty {
            return k
        }
        return "REPLACE_WITH_YOUR_ANON_KEY"
    }()

    static let client: SupabaseClient = {
        let url = URL(string: "https://ywpxdolvmrobczzyyfgt.supabase.co")!
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()

    /// Base URL for invoking Supabase Edge Functions from the client.
    static var functionsBaseURL: URL {
        let base = URL(string: "https://ywpxdolvmrobczzyyfgt.supabase.co")!
        return base
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
    }
}

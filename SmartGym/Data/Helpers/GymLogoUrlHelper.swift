//
//  GymLogoUrlHelper.swift
//  SmartGym
//
//  Resolves gym logo URL for display. If the URL is a Supabase gym-logos public path,
//  fetches a signed URL so it works when the bucket is private (like the web app).
//

import Foundation
import Supabase

private let gymLogosPublicPrefix = "/storage/v1/object/public/gym-logos/"
private let signedUrlTtlSec = 60 * 60 // 1 hour
private let cacheBufferMin = 10 // refresh 10 min before expiry

private var signedUrlCache: [String: (url: String, expiresAt: Date)] = [:]

private func getCachedSignedUrl(path: String) -> String? {
    guard let entry = signedUrlCache[path] else { return nil }
    let refreshAt = entry.expiresAt.addingTimeInterval(-Double(cacheBufferMin * 60))
    guard Date() < refreshAt else { return nil }
    return entry.url
}

private func setCachedSignedUrl(path: String, url: String) {
    signedUrlCache[path] = (url, Date().addingTimeInterval(TimeInterval(signedUrlTtlSec)))
}

/// Extracts the storage path from a Supabase gym-logos public URL, or nil if not applicable.
private func extractStoragePath(from urlString: String) -> String? {
    guard let range = urlString.range(of: gymLogosPublicPrefix) else { return nil }
    let after = String(urlString[range.upperBound...])
    let path = after.components(separatedBy: "?").first ?? after
    return path.isEmpty ? nil : path
}

/// Returns a URL suitable for displaying the gym logo. For Supabase gym-logos URLs,
/// fetches a signed URL when the bucket is private. Otherwise returns the URL as-is.
func resolveGymLogoUrl(_ logoUrl: String?) async -> String? {
    guard let logoUrl = logoUrl, !logoUrl.isEmpty else { return nil }
    guard let path = extractStoragePath(from: logoUrl) else { return logoUrl }
    if let cached = getCachedSignedUrl(path: path) { return cached }
    do {
        let signed = try await AppSupabase.client.storage
            .from("gym-logos")
            .createSignedURL(path: path, expiresIn: signedUrlTtlSec)
        setCachedSignedUrl(path: path, url: signed.absoluteString)
        return signed.absoluteString
    } catch {
        // Fall back to original URL (may work if bucket is public)
    }
    return logoUrl
}

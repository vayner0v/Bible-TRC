//
//  SupabaseService.swift
//  Bible v1
//
//  Supabase client configuration and management
//

import Foundation
import Supabase

/// Singleton service for Supabase client access
@MainActor
final class SupabaseService {
    static let shared = SupabaseService()
    
    /// The Supabase client instance
    /// Note: Always check `isConfigured` before using this client
    let client: SupabaseClient
    
    /// Whether Supabase is properly configured with real credentials
    let isConfigured: Bool
    
    private init() {
        // Load credentials from Secrets.plist
        if let secrets = SupabaseService.loadSecrets(),
           let urlString = secrets["SUPABASE_URL"] as? String,
           let anonKey = secrets["SUPABASE_ANON_KEY"] as? String,
           let url = URL(string: urlString),
           !urlString.isEmpty,
           !anonKey.isEmpty,
           !urlString.contains("your-project"),
           !urlString.contains("placeholder"),
           urlString.hasPrefix("https://") {
            
            // Create properly configured client
            self.client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: anonKey,
                options: .init(
                    auth: .init(
                        flowType: .pkce,
                        autoRefreshToken: true,
                        emitLocalSessionAsInitialSession: true
                    )
                )
            )
            self.isConfigured = true
            print("✅ Supabase: Client configured successfully")
        } else {
            // Create a dummy client that won't be used
            // This avoids "invalid reuse" errors by only creating one instance
            print("⚠️ Supabase: Secrets.plist not configured. Community features will be unavailable.")
            self.client = SupabaseClient(
                supabaseURL: URL(string: "https://disabled.supabase.co")!,
                supabaseKey: "disabled_key_placeholder_do_not_use"
            )
            self.isConfigured = false
        }
    }
    
    /// Load secrets from Secrets.plist
    private static func loadSecrets() -> [String: Any]? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return dict
    }
    
    /// Check if Supabase is available before making calls
    func ensureConfigured() throws {
        guard isConfigured else {
            throw SupabaseServiceError.notConfigured
        }
    }
}

/// Errors specific to SupabaseService
enum SupabaseServiceError: LocalizedError {
    case notConfigured
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please add your credentials to Secrets.plist"
        }
    }
}


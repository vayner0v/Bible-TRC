//
//  GoogleSignInService.swift
//  Bible v1
//
//  Google Sign-In using Supabase OAuth flow
//

import Foundation
import Combine
import AuthenticationServices
import Supabase
import UIKit

/// Google Sign-In service using ASWebAuthenticationSession
@MainActor
final class GoogleSignInService: NSObject, ObservableObject {
    static let shared = GoogleSignInService()
    
    @Published private(set) var isLoading = false
    
    private var webAuthSession: ASWebAuthenticationSession?
    
    private override init() {
        super.init()
    }
    
    /// Start Google Sign-In flow
    func signIn() async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Get the OAuth URL from Supabase
        let redirectURL = URL(string: "vaynerov.Bible-v1://auth/callback")!
        
        do {
            let url = try SupabaseService.shared.client.auth.getOAuthSignInURL(
                provider: .google,
                redirectTo: redirectURL
            )
            
            // Present the web authentication session
            try await presentWebAuth(url: url, callbackScheme: "vaynerov.Bible-v1")
        } catch {
            throw AuthError.googleSignInFailed
        }
    }
    
    /// Present web authentication session
    private func presentWebAuth(url: URL, callbackScheme: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(throwing: AuthError.googleSignInFailed)
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.googleSignInFailed)
                    return
                }
                
                // Handle the callback URL
                Task {
                    do {
                        try await self.handleCallback(url: callbackURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            
            self.webAuthSession = session
            
            if !session.start() {
                continuation.resume(throwing: AuthError.googleSignInFailed)
            }
        }
    }
    
    /// Handle the OAuth callback URL
    private func handleCallback(url: URL) async throws {
        // The callback URL contains the session info
        // Supabase SDK should automatically handle this
        let session = try await SupabaseService.shared.client.auth.session(from: url)
        
        // Cache the auth provider for "Last used" badge
        SettingsStore.shared.lastUsedAuthProvider = "google"
        SettingsStore.shared.lastSignedInEmail = session.user.email
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension GoogleSignInService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                // Fallback with windowScene
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    return UIWindow(windowScene: scene)
                }
                fatalError("No window scene available")
            }
            return window
        }
    }
}

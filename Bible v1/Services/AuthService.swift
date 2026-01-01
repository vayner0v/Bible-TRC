//
//  AuthService.swift
//  Bible v1
//
//  Manages user authentication using AWS Amplify Cognito
//

import Foundation
import SwiftUI
import Combine
import Amplify
import AWSCognitoAuthPlugin

// MARK: - Auth State

/// Represents the current authentication state
enum AuthState: Equatable {
    case unknown
    case signedOut
    case signingIn
    case signedIn(userId: String)
    case confirmingSignUp(email: String)
    case error(String)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.signedOut, .signedOut), (.signingIn, .signingIn):
            return true
        case let (.signedIn(l), .signedIn(r)):
            return l == r
        case let (.confirmingSignUp(l), .confirmingSignUp(r)):
            return l == r
        case let (.error(l), .error(r)):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - App Auth Error

/// Authentication errors (named AppAuthError to avoid conflict with Amplify.AuthError)
enum AppAuthError: LocalizedError {
    case signUpFailed(String)
    case signInFailed(String)
    case confirmationFailed(String)
    case signOutFailed(String)
    case sessionExpired
    case userNotFound
    case invalidCredentials
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .confirmationFailed(let message):
            return "Confirmation failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .userNotFound:
            return "No account found with this email."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - User Model

/// Represents authenticated user data
struct AuthUser: Identifiable, Equatable {
    let id: String
    let email: String
    var givenName: String?
    var familyName: String?
    var provider: AuthProvider
    
    var displayName: String {
        if let given = givenName {
            if let family = familyName {
                return "\(given) \(family)"
            }
            return given
        }
        return email
    }
}

/// Authentication provider used
enum AuthProvider: String, Codable {
    case email = "email"
    case apple = "apple"
    case google = "google"
    case unknown = "unknown"
}

// MARK: - Auth Service

/// Manages all authentication operations
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var currentUser: AuthUser?
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// Quick check if user is authenticated
    var isAuthenticated: Bool {
        if case .signedIn = authState {
            return true
        }
        return false
    }
    
    // MARK: - Private Properties
    
    private var authListener: AnyCancellable?
    private var isConfigured = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure Amplify with Cognito plugin
    /// Call this once at app launch
    func configure() async {
        guard !isConfigured else { return }
        
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            isConfigured = true
            
            // Listen for auth events
            setupAuthListener()
            
            // Check current auth session
            await checkAuthSession()
            
            print("✅ Amplify configured successfully")
        } catch {
            print("❌ Failed to configure Amplify: \(error)")
            authState = .error("Failed to initialize authentication")
        }
    }
    
    // MARK: - Auth Session Check
    
    /// Check if user is already signed in
    func checkAuthSession() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            
            if session.isSignedIn {
                // Fetch user attributes
                await fetchCurrentUser()
            } else {
                authState = .signedOut
                currentUser = nil
            }
        } catch {
            print("Auth session check failed: \(error)")
            authState = .signedOut
            currentUser = nil
        }
    }
    
    // MARK: - Email/Password Sign Up
    
    /// Sign up with email and password
    func signUp(email: String, password: String, givenName: String? = nil, familyName: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var userAttributes: [AuthUserAttribute] = [
            .init(.email, value: email)
        ]
        
        if let givenName = givenName, !givenName.isEmpty {
            userAttributes.append(.init(.givenName, value: givenName))
        }
        
        if let familyName = familyName, !familyName.isEmpty {
            userAttributes.append(.init(.familyName, value: familyName))
        }
        
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes)
        
        do {
            let result = try await Amplify.Auth.signUp(
                username: email,
                password: password,
                options: options
            )
            
            switch result.nextStep {
            case .confirmUser:
                authState = .confirmingSignUp(email: email)
            case .done:
                // Auto-confirmed, sign in
                try await signIn(email: email, password: password)
            case .completeAutoSignIn:
                // Auto sign-in after sign up
                await fetchCurrentUser()
            }
        } catch let error as AuthError {
            let message = parseAmplifyError(error)
            errorMessage = message
            throw AppAuthError.signUpFailed(message)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.signUpFailed(message)
        }
    }
    
    // MARK: - Confirm Sign Up
    
    /// Confirm sign up with verification code
    func confirmSignUp(email: String, code: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await Amplify.Auth.confirmSignUp(
                for: email,
                confirmationCode: code
            )
            
            if result.isSignUpComplete {
                authState = .signedOut
            }
        } catch let error as AuthError {
            let message = parseAmplifyError(error)
            errorMessage = message
            throw AppAuthError.confirmationFailed(message)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.confirmationFailed(message)
        }
    }
    
    // MARK: - Resend Confirmation Code
    
    /// Resend confirmation code
    func resendConfirmationCode(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            _ = try await Amplify.Auth.resendSignUpCode(for: email)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.unknown(message)
        }
    }
    
    // MARK: - Email/Password Sign In
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        authState = .signingIn
        
        defer { isLoading = false }
        
        do {
            let result = try await Amplify.Auth.signIn(
                username: email,
                password: password
            )
            
            if result.isSignedIn {
                await fetchCurrentUser()
            } else {
                // Handle additional steps if needed
                switch result.nextStep {
                case .confirmSignUp:
                    authState = .confirmingSignUp(email: email)
                default:
                    authState = .signedOut
                }
            }
        } catch let error as AuthError {
            authState = .signedOut
            let message = parseAmplifyError(error)
            errorMessage = message
            throw AppAuthError.signInFailed(message)
        } catch {
            authState = .signedOut
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.signInFailed(message)
        }
    }
    
    // MARK: - Social Sign In
    
    /// Sign in with Apple
    func signInWithApple(presentationAnchor: AuthUIPresentationAnchor? = nil) async throws {
        isLoading = true
        errorMessage = nil
        authState = .signingIn
        
        defer { isLoading = false }
        
        do {
            let result = try await Amplify.Auth.signInWithWebUI(
                for: .apple,
                presentationAnchor: presentationAnchor ?? getWindow()
            )
            
            if result.isSignedIn {
                await fetchCurrentUser(provider: .apple)
            } else {
                authState = .signedOut
            }
        } catch let error as AuthError {
            authState = .signedOut
            let message = parseAmplifyError(error)
            errorMessage = message
            throw AppAuthError.signInFailed(message)
        } catch {
            authState = .signedOut
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.signInFailed(message)
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle(presentationAnchor: AuthUIPresentationAnchor? = nil) async throws {
        isLoading = true
        errorMessage = nil
        authState = .signingIn
        
        defer { isLoading = false }
        
        do {
            let result = try await Amplify.Auth.signInWithWebUI(
                for: .google,
                presentationAnchor: presentationAnchor ?? getWindow()
            )
            
            if result.isSignedIn {
                await fetchCurrentUser(provider: .google)
            } else {
                authState = .signedOut
            }
        } catch let error as AuthError {
            authState = .signedOut
            let message = parseAmplifyError(error)
            errorMessage = message
            throw AppAuthError.signInFailed(message)
        } catch {
            authState = .signedOut
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.signInFailed(message)
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out current user
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Amplify.Auth.signOut() doesn't throw - it always succeeds locally
        _ = await Amplify.Auth.signOut()
        authState = .signedOut
        currentUser = nil
    }
    
    // MARK: - Password Reset
    
    /// Request password reset
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            _ = try await Amplify.Auth.resetPassword(for: email)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.unknown(message)
        }
    }
    
    /// Confirm password reset with code and new password
    func confirmResetPassword(email: String, newPassword: String, code: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await Amplify.Auth.confirmResetPassword(
                for: email,
                with: newPassword,
                confirmationCode: code
            )
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            throw AppAuthError.unknown(message)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Fetch current user attributes
    private func fetchCurrentUser(provider: AuthProvider = .email) async {
        do {
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            let user = try await Amplify.Auth.getCurrentUser()
            
            var email = ""
            var givenName: String?
            var familyName: String?
            
            for attribute in attributes {
                switch attribute.key {
                case .email:
                    email = attribute.value
                case .givenName:
                    givenName = attribute.value
                case .familyName:
                    familyName = attribute.value
                default:
                    break
                }
            }
            
            currentUser = AuthUser(
                id: user.userId,
                email: email,
                givenName: givenName,
                familyName: familyName,
                provider: provider
            )
            
            authState = .signedIn(userId: user.userId)
            
        } catch {
            print("Failed to fetch user: \(error)")
            authState = .signedOut
            currentUser = nil
        }
    }
    
    /// Setup listener for auth events
    private func setupAuthListener() {
        authListener = Amplify.Hub.publisher(for: .auth)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                switch payload.eventName {
                case HubPayload.EventName.Auth.signedIn:
                    Task { await self?.fetchCurrentUser() }
                case HubPayload.EventName.Auth.signedOut:
                    self?.authState = .signedOut
                    self?.currentUser = nil
                case HubPayload.EventName.Auth.sessionExpired:
                    self?.authState = .signedOut
                    self?.currentUser = nil
                default:
                    break
                }
            }
    }
    
    /// Parse Amplify error to user-friendly message
    private func parseAmplifyError(_ error: AuthError) -> String {
        // AuthError is an enum with associated values
        // We check the error description for common patterns
        let description = error.errorDescription
        
        if description.contains("Incorrect username or password") ||
           description.contains("not authorized") {
            return "Invalid email or password."
        } else if description.contains("User does not exist") ||
                  description.contains("user not found") {
            return "No account found with this email."
        } else if description.contains("User already exists") {
            return "An account with this email already exists."
        } else if description.contains("Invalid verification code") {
            return "Invalid verification code. Please try again."
        } else if description.contains("Password") {
            return description
        } else {
            return description
        }
    }
    
    /// Get the key window for presentation
    private func getWindow() -> AuthUIPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Type Alias for Window

typealias AuthUIPresentationAnchor = UIWindow


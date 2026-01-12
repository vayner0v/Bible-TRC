//
//  AuthService.swift
//  Bible v1
//
//  Authentication service with Apple, Google, and Email/Password support
//  NOTE: Email/password can be disabled in the future - see REMOVABLE_EMAIL_AUTH markers
//

import Foundation
import Supabase
import Combine
import AuthenticationServices
import CryptoKit

/// Authentication provider type
enum AuthProvider: String, CaseIterable {
    case apple = "apple"
    case google = "google"
    case email = "email" // REMOVABLE_EMAIL_AUTH: Remove this case when disabling email auth
    
    var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        case .email: return "Email"
        }
    }
    
    var iconName: String {
        switch self {
        case .apple: return "apple.logo"
        case .google: return "g.circle.fill"
        case .email: return "envelope.fill"
        }
    }
}

/// User profile data
struct UserProfile: Codable, Equatable {
    let id: UUID
    let email: String
    var displayName: String?
    var avatarUrl: String?
    let createdAt: Date
    let provider: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case provider
    }
    
    init(id: UUID, email: String, displayName: String? = nil, avatarUrl: String? = nil, createdAt: Date, provider: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
        self.provider = provider
    }
}

/// Authentication state
enum AuthState: Equatable {
    case loading
    case localOnly
    case signedOut
    case signedIn(UserProfile)
    
    var isAuthenticated: Bool {
        if case .signedIn = self { return true }
        return false
    }
    
    var isLocalOnly: Bool {
        if case .localOnly = self { return true }
        return false
    }
    
    var user: UserProfile? {
        if case .signedIn(let profile) = self { return profile }
        return nil
    }
}

/// Authentication error types
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case invalidCredentials
    case networkError
    case notConfigured
    case appleSignInFailed
    case googleSignInFailed
    case cancelled
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with a number and special character"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Unable to connect. Please check your internet connection"
        case .notConfigured:
            return "Cloud sync is not configured"
        case .appleSignInFailed:
            return "Sign in with Apple failed. Please try again"
        case .googleSignInFailed:
            return "Sign in with Google failed. Please try again"
        case .cancelled:
            return "Sign in was cancelled"
        case .unknown(let message):
            return message
        }
    }
}

/// Authentication service with Apple, Google, and Email/Password support
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    @Published private(set) var authState: AuthState = .loading
    @Published private(set) var isLoading = false
    
    // MARK: - Private Properties
    
    private var authStateTask: Task<Void, Never>?
    private var currentNonce: String?
    
    // MARK: - Initialization
    
    private init() {
        // Check if local-only mode is enabled
        if SettingsStore.shared.localOnlyMode {
            authState = .localOnly
        } else {
            Task {
                await checkAuthState()
                listenToAuthChanges()
            }
        }
    }
    
    // MARK: - Local-Only Mode
    
    /// Enable local-only mode (no cloud sync)
    func enableLocalOnlyMode() {
        SettingsStore.shared.localOnlyMode = true
        authState = .localOnly
        authStateTask?.cancel()
    }
    
    /// Disable local-only mode and check for existing session
    func disableLocalOnlyMode() async {
        SettingsStore.shared.localOnlyMode = false
        await checkAuthState()
        listenToAuthChanges()
    }
    
    // MARK: - Sign In with Apple
    
    /// Generate a random nonce for Apple Sign In
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    /// Get SHA256 hash of nonce for Apple Sign In request
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    /// Sign in with Apple using ID token
    func signInWithApple(idToken: String, nonce: String) async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            
            let profile = createProfile(from: session.user, provider: "apple")
            authState = .signedIn(profile)
            SettingsStore.shared.localOnlyMode = false
            
            // Cache the auth provider for quick sign-in
            SettingsStore.shared.lastUsedAuthProvider = "apple"
            SettingsStore.shared.lastSignedInEmail = profile.email
        } catch {
            throw AuthError.appleSignInFailed
        }
    }
    
    /// Handle Apple Sign In authorization result
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = appleIDCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                throw AuthError.appleSignInFailed
            }
            
            try await signInWithApple(idToken: identityToken, nonce: nonce)
            
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                throw AuthError.cancelled
            }
            throw AuthError.appleSignInFailed
        }
    }
    
    // MARK: - Sign In with Google
    
    /// Sign in with Google using ID token and access token
    func signInWithGoogle(idToken: String, accessToken: String) async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseService.shared.client.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
            )
            
            let profile = createProfile(from: session.user, provider: "google")
            authState = .signedIn(profile)
            SettingsStore.shared.localOnlyMode = false
            
            // Cache the auth provider for quick sign-in
            SettingsStore.shared.lastUsedAuthProvider = "google"
            SettingsStore.shared.lastSignedInEmail = profile.email
        } catch {
            throw AuthError.googleSignInFailed
        }
    }
    
    // MARK: - Email/Password Authentication
    // REMOVABLE_EMAIL_AUTH: START - Remove this entire section when disabling email auth
    
    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard isValidPassword(password) else {
            throw AuthError.weakPassword
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await SupabaseService.shared.client.auth.signUp(
                email: email,
                password: password,
                data: displayName != nil ? ["display_name": .string(displayName!)] : nil
            )
            
            let user = response.user
            let profile = UserProfile(
                id: user.id,
                email: email,
                displayName: displayName,
                avatarUrl: nil,
                createdAt: Date(),
                provider: "email"
            )
            authState = .signedIn(profile)
            
            // Disable local-only mode since user registered
            SettingsStore.shared.localOnlyMode = false
            
            // Cache the auth provider for quick sign-in
            SettingsStore.shared.lastUsedAuthProvider = "email"
            SettingsStore.shared.lastSignedInEmail = email
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseService.shared.client.auth.signIn(
                email: email,
                password: password
            )
            
            let profile = UserProfile(
                id: session.user.id,
                email: email,
                displayName: session.user.userMetadata["display_name"]?.stringValue,
                avatarUrl: session.user.userMetadata["avatar_url"]?.stringValue,
                createdAt: session.user.createdAt,
                provider: "email"
            )
            authState = .signedIn(profile)
            
            // Disable local-only mode since user signed in
            SettingsStore.shared.localOnlyMode = false
            
            // Cache the auth provider for quick sign-in
            SettingsStore.shared.lastUsedAuthProvider = "email"
            SettingsStore.shared.lastSignedInEmail = email
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Reset password
    func resetPassword(email: String) async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await SupabaseService.shared.client.auth.resetPasswordForEmail(email)
        } catch {
            throw mapAuthError(error)
        }
    }
    
    // REMOVABLE_EMAIL_AUTH: END
    
    // MARK: - Common Authentication Methods
    
    /// Sign out
    func signOut() async throws {
        guard SupabaseService.shared.isConfigured else {
            authState = .signedOut
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await SupabaseService.shared.client.auth.signOut()
            authState = .signedOut
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Update user profile
    func updateProfile(displayName: String? = nil, avatarUrl: String? = nil) async throws {
        guard SupabaseService.shared.isConfigured else {
            throw AuthError.notConfigured
        }
        
        guard case .signedIn(var profile) = authState else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var metadata: [String: AnyJSON] = [:]
        if let displayName = displayName {
            metadata["display_name"] = .string(displayName)
            profile.displayName = displayName
        }
        if let avatarUrl = avatarUrl {
            metadata["avatar_url"] = .string(avatarUrl)
            profile.avatarUrl = avatarUrl
        }
        
        do {
            try await SupabaseService.shared.client.auth.update(user: UserAttributes(data: metadata))
            authState = .signedIn(profile)
        } catch {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Helper: Create Profile from User
    
    private func createProfile(from user: User, provider: String) -> UserProfile {
        UserProfile(
            id: user.id,
            email: user.email ?? "",
            displayName: user.userMetadata["full_name"]?.stringValue ??
                         user.userMetadata["name"]?.stringValue ??
                         user.userMetadata["display_name"]?.stringValue,
            avatarUrl: user.userMetadata["avatar_url"]?.stringValue ??
                       user.userMetadata["picture"]?.stringValue,
            createdAt: user.createdAt,
            provider: provider
        )
    }
    
    // MARK: - Helper: Random Nonce for Apple Sign In
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    // MARK: - Private Methods
    
    private func checkAuthState() async {
        guard SupabaseService.shared.isConfigured else {
            authState = .signedOut
            return
        }
        
        do {
            let session = try await SupabaseService.shared.client.auth.session
            let profile = createProfile(from: session.user, provider: session.user.appMetadata["provider"]?.stringValue ?? "unknown")
            authState = .signedIn(profile)
        } catch {
            authState = .signedOut
        }
    }
    
    private func listenToAuthChanges() {
        authStateTask?.cancel()
        
        guard SupabaseService.shared.isConfigured else { return }
        
        authStateTask = Task {
            for await (event, session) in SupabaseService.shared.client.auth.authStateChanges {
                guard !Task.isCancelled else { break }
                
                switch event {
                case .signedIn:
                    if let user = session?.user {
                        let profile = createProfile(from: user, provider: user.appMetadata["provider"]?.stringValue ?? "unknown")
                        authState = .signedIn(profile)
                    }
                case .signedOut:
                    authState = .signedOut
                case .tokenRefreshed:
                    // Token refreshed, no action needed
                    break
                default:
                    break
                }
            }
        }
    }
    
    // REMOVABLE_EMAIL_AUTH: These validation functions are only needed for email auth
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, 1 number, 1 special character
        guard password.count >= 8 else { return false }
        let hasNumber = password.range(of: #"\d"#, options: .regularExpression) != nil
        let hasSpecial = password.range(of: #"[!@#$%^&*(),.?\":{}|<>]"#, options: .regularExpression) != nil
        return hasNumber && hasSpecial
    }
    // REMOVABLE_EMAIL_AUTH: END validation functions
    
    private func mapAuthError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("invalid login") || errorMessage.contains("invalid email or password") {
            return .invalidCredentials
        } else if errorMessage.contains("already registered") || errorMessage.contains("already exists") {
            return .emailAlreadyExists
        } else if errorMessage.contains("network") || errorMessage.contains("connection") {
            return .networkError
        } else if errorMessage.contains("cancel") {
            return .cancelled
        } else {
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - SettingsStore Extension for Local-Only Mode

extension SettingsStore {
    /// Local-only mode - when enabled, no cloud sync
    var localOnlyMode: Bool {
        get { UserDefaults.standard.bool(forKey: "auth_local_only_mode") }
        set { 
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "auth_local_only_mode")
        }
    }
}


//
//  SocialSignInButtons.swift
//  Bible v1
//
//  Social sign-in buttons for Apple, Google, and Email
//  NOTE: Email button can be removed in the future - see REMOVABLE_EMAIL_AUTH markers
//

import SwiftUI
import AuthenticationServices

// MARK: - Sign In with Apple Button

struct SignInWithAppleButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    let onCompletion: (Result<Void, Error>) -> Void
    var showLastUsedIndicator: Bool = true
    
    @State private var currentNonce: String?
    
    private var isLastUsed: Bool {
        showLastUsedIndicator && settingsStore.lastUsedAuthProvider == "apple"
    }
    
    var body: some View {
        Button {
            // Nonce is handled internally
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.title3)
                Text("Continue with Apple")
                    .fontWeight(.medium)
                
                Spacer()
                
                if isLastUsed {
                    Text("Last used")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(themeManager.accentColor, lineWidth: 1)
                        )
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.black)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isLastUsed ? themeManager.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .overlay {
            SignInWithAppleButtonRepresentable(
                onRequest: { request in
                    let nonce = authService.generateNonce()
                    currentNonce = nonce
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = authService.sha256(nonce)
                },
                onCompletion: { result in
                    Task {
                        do {
                            try await authService.handleAppleSignIn(result: result)
                            onCompletion(.success(()))
                        } catch {
                            onCompletion(.failure(error))
                        }
                    }
                }
            )
            .blendMode(.destinationOver) // Hide the button visually but keep it tappable
            .allowsHitTesting(true)
        }
    }
}

// MARK: - Apple Sign In Representable

struct SignInWithAppleButtonRepresentable: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .continue, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handleTap() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
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

// MARK: - Sign In with Google Button

struct SignInWithGoogleButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var googleService = GoogleSignInService.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    let onCompletion: (Result<Void, Error>) -> Void
    var showLastUsedIndicator: Bool = true
    
    private var isLastUsed: Bool {
        showLastUsedIndicator && settingsStore.lastUsedAuthProvider == "google"
    }
    
    var body: some View {
        Button {
            Task {
                do {
                    try await googleService.signIn()
                    onCompletion(.success(()))
                } catch {
                    onCompletion(.failure(error))
                }
            }
        } label: {
            HStack(spacing: 12) {
                if googleService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    // Google "G" logo approximation
                    Text("G")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .yellow, .green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Continue with Google")
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if isLastUsed {
                    Text("Last used")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(themeManager.accentColor, lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isLastUsed ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isLastUsed ? 2 : 1)
            )
        }
        .disabled(googleService.isLoading)
    }
}

// MARK: - Email Sign In Button
// REMOVABLE_EMAIL_AUTH: Remove this entire struct when disabling email auth

struct EmailSignInButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settingsStore = SettingsStore.shared
    
    let onTap: () -> Void
    var showLastUsedIndicator: Bool = true
    
    private var isLastUsed: Bool {
        showLastUsedIndicator && settingsStore.lastUsedAuthProvider == "email"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
                
                Text("Continue with Email")
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if isLastUsed {
                    Text("Last used")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(themeManager.accentColor, lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isLastUsed ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isLastUsed ? 2 : 1)
            )
        }
    }
}

// MARK: - Combined Social Buttons View

struct SocialSignInButtons: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let onAppleSuccess: () -> Void
    let onAppleError: (Error) -> Void
    let onGoogleSuccess: () -> Void
    let onGoogleError: (Error) -> Void
    let onEmailTap: () -> Void // REMOVABLE_EMAIL_AUTH: Remove this parameter
    
    var body: some View {
        VStack(spacing: 12) {
            // Apple Sign In (Required by App Store if using other social logins)
            SignInWithAppleButton { result in
                switch result {
                case .success:
                    onAppleSuccess()
                case .failure(let error):
                    onAppleError(error)
                }
            }
            
            // Google Sign In
            SignInWithGoogleButton { result in
                switch result {
                case .success:
                    onGoogleSuccess()
                case .failure(let error):
                    onGoogleError(error)
                }
            }
            
            // REMOVABLE_EMAIL_AUTH: START - Remove this section when disabling email auth
            // Divider
            HStack {
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
            }
            .padding(.vertical, 8)
            
            // Email Sign In
            EmailSignInButton(onTap: onEmailTap)
            // REMOVABLE_EMAIL_AUTH: END
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SocialSignInButtons(
            onAppleSuccess: { print("Apple success") },
            onAppleError: { print("Apple error: \($0)") },
            onGoogleSuccess: { print("Google success") },
            onGoogleError: { print("Google error: \($0)") },
            onEmailTap: { print("Email tapped") }
        )
    }
    .padding()
}


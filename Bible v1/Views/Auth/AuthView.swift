//
//  AuthView.swift
//  Bible v1
//
//  Main authentication container view
//

import SwiftUI

/// Authentication mode selection
enum AuthMode: Equatable {
    case login
    case signUp
    case forgotPassword
    case confirmSignUp(email: String)
}

/// Main authentication view presented when local-only mode is disabled
struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var authMode: AuthMode = .login
    @State private var showError = false
    
    /// Callback when authentication completes successfully
    var onAuthenticated: (() -> Void)?
    
    /// Callback when user cancels authentication
    var onCancel: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo and Title
                        headerSection
                        
                        // Auth Content
                        switch authMode {
                        case .login:
                            LoginView(
                                onSignUpTapped: { authMode = .signUp },
                                onForgotPasswordTapped: { authMode = .forgotPassword },
                                onAuthenticated: handleAuthenticated
                            )
                        case .signUp:
                            SignUpView(
                                onLoginTapped: { authMode = .login },
                                onConfirmationNeeded: { email in
                                    authMode = .confirmSignUp(email: email)
                                },
                                onAuthenticated: handleAuthenticated
                            )
                        case .forgotPassword:
                            ForgotPasswordView(
                                onBackToLogin: { authMode = .login }
                            )
                        case .confirmSignUp(let email):
                            ConfirmSignUpView(
                                email: email,
                                onConfirmed: { authMode = .login },
                                onBackToSignUp: { authMode = .signUp }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    authService.errorMessage = nil
                }
            } message: {
                Text(authService.errorMessage ?? "An error occurred")
            }
            .onChange(of: authService.errorMessage) { _, newValue in
                showError = newValue != nil
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon or Logo
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text(authMode == .login ? "Welcome Back" : "Create Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text(authMode == .login
                     ? "Sign in to sync your spiritual journey"
                     : "Start your spiritual journey today")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Actions
    
    private func handleAuthenticated() {
        onAuthenticated?()
        dismiss()
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step: ForgotPasswordStep = .requestCode
    @State private var showSuccess = false
    
    var onBackToLogin: () -> Void
    
    enum ForgotPasswordStep {
        case requestCode
        case enterCode
    }
    
    var body: some View {
        VStack(spacing: 24) {
            switch step {
            case .requestCode:
                requestCodeView
            case .enterCode:
                enterCodeView
            }
        }
    }
    
    private var requestCodeView: some View {
        VStack(spacing: 24) {
            Text("Reset Password")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("Enter your email and we'll send you a code to reset your password.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            AuthTextField(
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            AuthButton(
                title: "Send Reset Code",
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.resetPassword(email: email)
                        step = .enterCode
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
            .disabled(email.isEmpty)
            
            Button("Back to Login") {
                onBackToLogin()
            }
            .foregroundColor(themeManager.accentColor)
        }
    }
    
    private var enterCodeView: some View {
        VStack(spacing: 24) {
            Text("Enter Verification Code")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("We sent a code to \(email)")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            AuthTextField(
                placeholder: "Verification Code",
                text: $code,
                keyboardType: .numberPad
            )
            
            AuthTextField(
                placeholder: "New Password",
                text: $newPassword,
                isSecure: true,
                textContentType: .newPassword
            )
            
            AuthTextField(
                placeholder: "Confirm Password",
                text: $confirmPassword,
                isSecure: true,
                textContentType: .newPassword
            )
            
            if !newPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords don't match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            AuthButton(
                title: "Reset Password",
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.confirmResetPassword(
                            email: email,
                            newPassword: newPassword,
                            code: code
                        )
                        showSuccess = true
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
            .disabled(code.isEmpty || newPassword.isEmpty || newPassword != confirmPassword)
            
            Button("Back") {
                step = .requestCode
            }
            .foregroundColor(themeManager.accentColor)
        }
        .alert("Password Reset", isPresented: $showSuccess) {
            Button("OK") {
                onBackToLogin()
            }
        } message: {
            Text("Your password has been reset. You can now log in with your new password.")
        }
    }
}

// MARK: - Confirm Sign Up View

struct ConfirmSignUpView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let email: String
    var onConfirmed: () -> Void
    var onBackToSignUp: () -> Void
    
    @State private var code = ""
    @State private var showResendSuccess = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Verify Your Email")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("We sent a verification code to\n\(email)")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            AuthTextField(
                placeholder: "Verification Code",
                text: $code,
                keyboardType: .numberPad
            )
            
            AuthButton(
                title: "Verify Email",
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.confirmSignUp(email: email, code: code)
                        onConfirmed()
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
            .disabled(code.isEmpty)
            
            HStack(spacing: 4) {
                Text("Didn't receive code?")
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Button("Resend") {
                    Task {
                        do {
                            try await authService.resendConfirmationCode(email: email)
                            showResendSuccess = true
                        } catch {
                            // Error handled by AuthService
                        }
                    }
                }
                .foregroundColor(themeManager.accentColor)
            }
            .font(.subheadline)
            
            Button("Back to Sign Up") {
                onBackToSignUp()
            }
            .foregroundColor(themeManager.accentColor)
        }
        .alert("Code Sent", isPresented: $showResendSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A new verification code has been sent to your email.")
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}


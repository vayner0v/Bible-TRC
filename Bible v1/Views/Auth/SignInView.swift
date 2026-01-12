//
//  SignInView.swift
//  Bible v1
//
//  User sign in view with Apple, Google, and Email/Password
//  NOTE: Email/password section can be removed - see REMOVABLE_EMAIL_AUTH markers
//

import SwiftUI

struct SignInView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authService = AuthService.shared
    
    @State private var showEmailForm = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // REMOVABLE_EMAIL_AUTH: START - These states are only for email form
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false
    @State private var resetEmailSent = false
    // REMOVABLE_EMAIL_AUTH: END
    
    @Environment(\.dismiss) private var dismiss
    
    var onSuccess: (() -> Void)?
    var onSwitchToSignUp: (() -> Void)?
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection
                    
                    if showEmailForm {
                        // REMOVABLE_EMAIL_AUTH: Remove this entire if branch
                        emailFormSection
                    } else {
                        // Social Sign In Buttons
                        socialButtonsSection
                    }
                    
                    // Sign Up Link
                    signUpLink
                }
                .padding(24)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        // REMOVABLE_EMAIL_AUTH: START - Remove these alerts
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Link") {
                Task {
                    await sendPasswordReset()
                }
            }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
        .alert("Email Sent", isPresented: $resetEmailSent) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check your email for a password reset link.")
        }
        // REMOVABLE_EMAIL_AUTH: END
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(themeManager.accentGradient)
            
            Text("Welcome Back")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("Sign in to access your saved content")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Social Buttons Section
    
    private var socialButtonsSection: some View {
        SocialSignInButtons(
            onAppleSuccess: {
                HapticManager.shared.success()
                onSuccess?()
            },
            onAppleError: { error in
                handleError(error)
            },
            onGoogleSuccess: {
                HapticManager.shared.success()
                onSuccess?()
            },
            onGoogleError: { error in
                handleError(error)
            },
            onEmailTap: {
                // REMOVABLE_EMAIL_AUTH: Remove this closure body
                withAnimation(.spring(response: 0.3)) {
                    showEmailForm = true
                }
            }
        )
    }
    
    // MARK: - Email Form Section
    // REMOVABLE_EMAIL_AUTH: START - Remove this entire section
    
    private var emailFormSection: some View {
        VStack(spacing: 16) {
            // Back button
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showEmailForm = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
                Spacer()
            }
            
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 20)
                    
                    TextField("your@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 20)
                    
                    if showPassword {
                        TextField("Your password", text: $password)
                            .textContentType(.password)
                    } else {
                        SecureField("Your password", text: $password)
                            .textContentType(.password)
                    }
                    
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
            
            // Forgot Password
            HStack {
                Spacer()
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot password?")
                        .font(.subheadline)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            // Sign In Button
            Button {
                Task {
                    await signInWithEmail()
                }
            } label: {
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Sign In")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isEmailFormValid ? themeManager.accentGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(14)
            }
            .disabled(!isEmailFormValid || authService.isLoading)
        }
    }
    
    private var isEmailFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func signInWithEmail() async {
        do {
            try await authService.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            HapticManager.shared.success()
            onSuccess?()
        } catch {
            handleError(error)
        }
    }
    
    private func sendPasswordReset() async {
        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            resetEmailSent = true
        } catch {
            handleError(error)
        }
    }
    
    // REMOVABLE_EMAIL_AUTH: END
    
    // MARK: - Sign Up Link
    
    private var signUpLink: some View {
        Button {
            onSwitchToSignUp?()
        } label: {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(themeManager.secondaryTextColor)
                Text("Sign Up")
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
            }
            .font(.subheadline)
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            if case .cancelled = authError {
                // User cancelled, don't show error
                return
            }
            errorMessage = authError.errorDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
        HapticManager.shared.error()
    }
}

#Preview {
    SignInView()
}

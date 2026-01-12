//
//  SignUpView.swift
//  Bible v1
//
//  User registration view with Apple, Google, and Email/Password
//  NOTE: Email/password section can be removed - see REMOVABLE_EMAIL_AUTH markers
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authService = AuthService.shared
    
    @State private var showEmailForm = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // REMOVABLE_EMAIL_AUTH: START - These states are only for email form
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showPassword = false
    // REMOVABLE_EMAIL_AUTH: END
    
    @Environment(\.dismiss) private var dismiss
    
    var onSuccess: (() -> Void)?
    var onSwitchToSignIn: (() -> Void)?
    
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
                    
                    // Sign In Link
                    signInLink
                }
                .padding(24)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(themeManager.accentGradient)
            
            Text("Create Account")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            Text("Sync your favorites, notes, and progress across devices")
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
            
            // Display Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name (optional)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                HStack(spacing: 12) {
                    Image(systemName: "person")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 20)
                    
                    TextField("Your name", text: $displayName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
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
                        TextField("Create a password", text: $password)
                            .textContentType(.newPassword)
                    } else {
                        SecureField("Create a password", text: $password)
                            .textContentType(.newPassword)
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
                
                Text("8+ characters with a number and special character")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Confirm Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 20)
                    
                    SecureField("Confirm your password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                
                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("Passwords don't match")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            // Sign Up Button
            Button {
                Task {
                    await signUpWithEmail()
                }
            } label: {
                HStack(spacing: 8) {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
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
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }
    
    private func signUpWithEmail() async {
        do {
            try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                displayName: displayName.isEmpty ? nil : displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            HapticManager.shared.success()
            onSuccess?()
        } catch {
            handleError(error)
        }
    }
    
    // REMOVABLE_EMAIL_AUTH: END
    
    // MARK: - Sign In Link
    
    private var signInLink: some View {
        Button {
            onSwitchToSignIn?()
        } label: {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundColor(themeManager.secondaryTextColor)
                Text("Sign In")
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
    SignUpView()
}

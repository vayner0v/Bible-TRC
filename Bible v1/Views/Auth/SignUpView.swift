//
//  SignUpView.swift
//  Bible v1
//
//  Email/password sign-up form with social login options
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var givenName = ""
    @State private var familyName = ""
    @State private var showPassword = false
    @State private var acceptedTerms = false
    
    var onLoginTapped: () -> Void
    var onConfirmationNeeded: (String) -> Void
    var onAuthenticated: () -> Void
    
    // Password validation
    private var passwordRequirements: [PasswordRequirement] {
        [
            PasswordRequirement(text: "At least 8 characters", isMet: password.count >= 8),
            PasswordRequirement(text: "Uppercase letter", isMet: password.contains(where: { $0.isUppercase })),
            PasswordRequirement(text: "Lowercase letter", isMet: password.contains(where: { $0.isLowercase })),
            PasswordRequirement(text: "Number", isMet: password.contains(where: { $0.isNumber })),
            PasswordRequirement(text: "Special character", isMet: password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })),
        ]
    }
    
    private var isPasswordValid: Bool {
        passwordRequirements.allSatisfy { $0.isMet }
    }
    
    private var doPasswordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && isPasswordValid && doPasswordsMatch && acceptedTerms
    }
    
    // Set to true when social providers are configured in AWS Cognito
    private let socialProvidersEnabled = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Social Login Buttons (hidden until providers are configured)
            if socialProvidersEnabled {
                socialLoginSection
                dividerSection
            }
            
            // Sign Up Form
            signUpFormSection
            
            // Login Link
            loginSection
        }
    }
    
    // MARK: - Social Login
    
    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            SocialLoginButton(
                provider: .apple,
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.signInWithApple()
                        if authService.isAuthenticated {
                            onAuthenticated()
                        }
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
            
            SocialLoginButton(
                provider: .google,
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.signInWithGoogle()
                        if authService.isAuthenticated {
                            onAuthenticated()
                        }
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
        }
    }
    
    // MARK: - Divider
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(themeManager.secondaryTextColor.opacity(0.3))
                .frame(height: 1)
            
            Text("or sign up with email")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(themeManager.secondaryTextColor.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Sign Up Form
    
    private var signUpFormSection: some View {
        VStack(spacing: 16) {
            // Name fields (optional)
            HStack(spacing: 12) {
                AuthTextField(
                    placeholder: "First Name",
                    text: $givenName,
                    textContentType: .givenName
                )
                
                AuthTextField(
                    placeholder: "Last Name",
                    text: $familyName,
                    textContentType: .familyName
                )
            }
            
            // Email
            AuthTextField(
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            // Password
            AuthTextField(
                placeholder: "Password",
                text: $password,
                isSecure: !showPassword,
                textContentType: .newPassword,
                trailingIcon: showPassword ? "eye.slash" : "eye",
                onTrailingIconTapped: {
                    showPassword.toggle()
                }
            )
            
            // Password Requirements
            if !password.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(passwordRequirements) { req in
                        HStack(spacing: 6) {
                            Image(systemName: req.isMet ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(req.isMet ? .green : themeManager.secondaryTextColor)
                            
                            Text(req.text)
                                .font(.caption)
                                .foregroundColor(req.isMet ? themeManager.textColor : themeManager.secondaryTextColor)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            
            // Confirm Password
            AuthTextField(
                placeholder: "Confirm Password",
                text: $confirmPassword,
                isSecure: true,
                textContentType: .newPassword
            )
            
            // Password match indicator
            if !confirmPassword.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: doPasswordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(doPasswordsMatch ? .green : .red)
                    
                    Text(doPasswordsMatch ? "Passwords match" : "Passwords don't match")
                        .font(.caption)
                        .foregroundColor(doPasswordsMatch ? .green : .red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            
            // Terms and Conditions
            HStack(alignment: .top, spacing: 12) {
                Button {
                    acceptedTerms.toggle()
                } label: {
                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundColor(acceptedTerms ? themeManager.accentColor : themeManager.secondaryTextColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) {
                        Text("I agree to the ")
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text("Terms of Service")
                            .foregroundColor(themeManager.accentColor)
                    }
                    HStack(spacing: 0) {
                        Text("and ")
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text("Privacy Policy")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Sign Up Button
            AuthButton(
                title: "Create Account",
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.signUp(
                            email: email,
                            password: password,
                            givenName: givenName.isEmpty ? nil : givenName,
                            familyName: familyName.isEmpty ? nil : familyName
                        )
                        
                        // Check if confirmation is needed
                        if case .confirmingSignUp(let email) = authService.authState {
                            onConfirmationNeeded(email)
                        } else if authService.isAuthenticated {
                            onAuthenticated()
                        }
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
            .disabled(!isFormValid)
        }
    }
    
    // MARK: - Login Link
    
    private var loginSection: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .foregroundColor(themeManager.secondaryTextColor)
            
            Button("Sign In") {
                onLoginTapped()
            }
            .fontWeight(.semibold)
            .foregroundColor(themeManager.accentColor)
        }
        .font(.subheadline)
    }
}

// MARK: - Password Requirement

struct PasswordRequirement: Identifiable {
    let id = UUID()
    let text: String
    let isMet: Bool
}

// MARK: - Preview

#Preview {
    SignUpView(
        onLoginTapped: {},
        onConfirmationNeeded: { _ in },
        onAuthenticated: {}
    )
}


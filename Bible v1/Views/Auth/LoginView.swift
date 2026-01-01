//
//  LoginView.swift
//  Bible v1
//
//  Email/password login with social login buttons
//

import SwiftUI

struct LoginView: View {
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var onSignUpTapped: () -> Void
    var onForgotPasswordTapped: () -> Void
    var onAuthenticated: () -> Void
    
    // Set to true when social providers are configured in AWS Cognito
    private let socialProvidersEnabled = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Social Login Buttons (hidden until providers are configured)
            if socialProvidersEnabled {
                socialLoginSection
                dividerSection
            }
            
            // Email/Password Form
            emailPasswordSection
            
            // Sign Up Link
            signUpSection
        }
    }
    
    // MARK: - Social Login
    
    private var socialLoginSection: some View {
        VStack(spacing: 12) {
            // Apple Sign In
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
            
            // Google Sign In
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
            
            Text("or")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(themeManager.secondaryTextColor.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Email/Password
    
    private var emailPasswordSection: some View {
        VStack(spacing: 16) {
            AuthTextField(
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            AuthTextField(
                placeholder: "Password",
                text: $password,
                isSecure: !showPassword,
                textContentType: .password,
                trailingIcon: showPassword ? "eye.slash" : "eye",
                onTrailingIconTapped: {
                    showPassword.toggle()
                }
            )
            
            // Forgot Password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    onForgotPasswordTapped()
                }
                .font(.subheadline)
                .foregroundColor(themeManager.accentColor)
            }
            
            // Sign In Button
            AuthButton(
                title: "Sign In",
                isLoading: authService.isLoading
            ) {
                Task {
                    do {
                        try await authService.signIn(email: email, password: password)
                        if authService.isAuthenticated {
                            onAuthenticated()
                        }
                    } catch {
                        // Error handled by AuthService
                    }
                }
            }
            .disabled(email.isEmpty || password.isEmpty)
        }
    }
    
    // MARK: - Sign Up Link
    
    private var signUpSection: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundColor(themeManager.secondaryTextColor)
            
            Button("Sign Up") {
                onSignUpTapped()
            }
            .fontWeight(.semibold)
            .foregroundColor(themeManager.accentColor)
        }
        .font(.subheadline)
    }
}

// MARK: - Social Login Button

struct SocialLoginButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let provider: AuthProvider
    let isLoading: Bool
    let action: () -> Void
    
    private var title: String {
        switch provider {
        case .apple:
            return "Continue with Apple"
        case .google:
            return "Continue with Google"
        default:
            return "Continue"
        }
    }
    
    private var icon: String {
        switch provider {
        case .apple:
            return "apple.logo"
        case .google:
            return "g.circle.fill"
        default:
            return "person.fill"
        }
    }
    
    private var backgroundColor: Color {
        switch provider {
        case .apple:
            return .primary
        case .google:
            return Color.white
        default:
            return themeManager.accentColor
        }
    }
    
    private var foregroundColor: Color {
        switch provider {
        case .apple:
            return Color(UIColor.systemBackground)
        case .google:
            return .black
        default:
            return .white
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                    
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: provider == .google ? 1 : 0)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var trailingIcon: String?
    var onTrailingIconTapped: (() -> Void)?
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            
            if let icon = trailingIcon {
                Button {
                    onTrailingIconTapped?()
                } label: {
                    Image(systemName: icon)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.secondaryTextColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Auth Button

struct AuthButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    let title: String
    var style: AuthButtonStyle = .primary
    let isLoading: Bool
    let action: () -> Void
    
    enum AuthButtonStyle {
        case primary
        case secondary
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style == .primary ? .white : themeManager.accentColor))
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(style == .primary ? themeManager.accentColor : Color.clear)
            .foregroundColor(style == .primary ? .white : themeManager.accentColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.accentColor, lineWidth: style == .secondary ? 2 : 0)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Preview

#Preview {
    LoginView(
        onSignUpTapped: {},
        onForgotPasswordTapped: {},
        onAuthenticated: {}
    )
}


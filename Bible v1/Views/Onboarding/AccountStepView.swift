//
//  AccountStepView.swift
//  Bible v1
//
//  Onboarding step for account creation with Apple, Google, and Email options
//  NOTE: Email option can be removed - see REMOVABLE_EMAIL_AUTH markers
//

import SwiftUI

struct AccountStepView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authService = AuthService.shared
    
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Header
                    headerSection
                    
                    // Quick Sign In Options
                    quickSignInSection
                    
                    // Benefits
                    benefitsSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
            
            // Bottom buttons
            bottomButtons
        }
        .sheet(isPresented: $showSignUp) {
            NavigationStack {
                SignUpView(
                    onSuccess: {
                        showSignUp = false
                        onContinue()
                    },
                    onSwitchToSignIn: {
                        showSignUp = false
                        showSignIn = true
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showSignUp = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInView(
                    onSuccess: {
                        showSignIn = false
                        onContinue()
                    },
                    onSwitchToSignUp: {
                        showSignIn = false
                        showSignUp = true
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showSignIn = false
                        }
                    }
                }
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
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 40))
                    .foregroundStyle(themeManager.accentGradient)
            }
            
            // Title
            Text("Sync Your Journey")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Create an account to sync your favorites, notes, and spiritual progress across all your devices.")
                .font(.body)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Quick Sign In Section
    
    private var quickSignInSection: some View {
        VStack(spacing: 12) {
            // Apple Sign In (Primary - always show)
            SignInWithAppleButton { result in
                switch result {
                case .success:
                    HapticManager.shared.success()
                    onContinue()
                case .failure(let error):
                    handleError(error)
                }
            }
            
            // Google Sign In
            SignInWithGoogleButton { result in
                switch result {
                case .success:
                    HapticManager.shared.success()
                    onContinue()
                case .failure(let error):
                    handleError(error)
                }
            }
            
            // REMOVABLE_EMAIL_AUTH: START - Remove this section when disabling email auth
            // Or use email/password
            Button {
                showSignUp = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text("Sign up with Email")
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.dividerColor, lineWidth: 1)
                )
            }
            // REMOVABLE_EMAIL_AUTH: END
            
            // Already have an account?
            Button {
                showSignIn = true
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
            .padding(.top, 8)
        }
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WITH AN ACCOUNT YOU CAN:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
            
            benefitRow(icon: "heart.fill", text: "Sync favorites across devices")
            benefitRow(icon: "highlighter", text: "Keep highlights and notes safe")
            benefitRow(icon: "hands.sparkles.fill", text: "Backup prayers and journal")
            benefitRow(icon: "arrow.triangle.2.circlepath", text: "Never lose your progress")
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Continue without account
            Button {
                // Enable local-only mode
                authService.enableLocalOnlyMode()
                onContinue()
            } label: {
                Text("Continue Without Account")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Text("You can create an account later in Settings")
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(themeManager.backgroundColor)
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
    AccountStepView(onContinue: {})
}

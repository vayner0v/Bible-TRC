//
//  ProfileView.swift
//  Bible v1
//
//  User profile view for settings
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authService = AuthService.shared
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSignOut = false
    @State private var showEditName = false
    @State private var editedName = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            // Only show profile content if authenticated
            if authService.authState.isAuthenticated {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader
                        
                        // Account Info Section
                        accountInfoSection
                        
                        // Sync Status Section
                        syncStatusSection
                        
                        // Sign Out Button
                        signOutButton
                    }
                    .padding()
                }
            } else {
                // Signed out state - show loading briefly then dismiss
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Signing out...")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .onAppear {
                    // Dismiss after a brief moment to allow UI to update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Sign Out", isPresented: $showSignOut) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await signOut()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out? Your data will remain on this device.")
        }
        .alert("Edit Name", isPresented: $showEditName) {
            TextField("Your name", text: $editedName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task {
                    await updateName()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(themeManager.accentGradient)
                    .frame(width: 100, height: 100)
                
                if let user = authService.authState.user {
                    Text(initials(from: user.displayName ?? user.email))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Name & Email
            VStack(spacing: 4) {
                if let user = authService.authState.user {
                    HStack(spacing: 8) {
                        Text(user.displayName ?? "Bible Reader")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textColor)
                        
                        Button {
                            editedName = user.displayName ?? ""
                            showEditName = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Account Info Section
    
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCOUNT")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if let user = authService.authState.user {
                    // Email
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textColor)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                    .padding()
                    
                    Divider()
                        .background(themeManager.dividerColor)
                    
                    // Member Since
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Member Since")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textColor)
                            Text(user.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Sync Status Section
    
    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLOUD SYNC")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Sync Status
                HStack {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(.green)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sync Enabled")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                        Text("Your data syncs across all devices")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Synced Items
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synced Data")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                        Text("Favorites, highlights, notes, prayers, journal")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button {
            showSignOut = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                
                Text("Sign Out")
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Helper Methods
    
    private func initials(from name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }
    
    private func signOut() async {
        do {
            try await authService.signOut()
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func updateName() async {
        guard !editedName.isEmpty else { return }
        
        do {
            try await authService.updateProfile(displayName: editedName)
            HapticManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Profile Card for Settings

/// Compact profile card to show in settings when signed in
struct ProfileSettingsCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authService = AuthService.shared
    
    var body: some View {
        NavigationLink {
            ProfileView()
        } label: {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(themeManager.accentGradient)
                        .frame(width: 50, height: 50)
                    
                    if let user = authService.authState.user {
                        Text(initials(from: user.displayName ?? user.email))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Name & Email
                VStack(alignment: .leading, spacing: 4) {
                    if let user = authService.authState.user {
                        Text(user.displayName ?? "Bible Reader")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    private func initials(from name: String) -> String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "?"
    }
}

/// Auth sheet mode for proper navigation
enum AuthSheetMode: Identifiable {
    case signIn
    case signUp
    
    var id: Self { self }
}

/// Card to show when user is in local-only mode or signed out
struct SignInPromptCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var authSheetMode: AuthSheetMode?
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                authSheetMode = .signUp
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title2)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Sync across devices")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding()
            }
            
            Divider()
                .background(themeManager.dividerColor)
            
            Button {
                authSheetMode = .signIn
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeManager.secondaryTextColor.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Already have an account?")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding()
            }
        }
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(14)
        .sheet(item: $authSheetMode) { mode in
            NavigationStack {
                switch mode {
                case .signUp:
                    SignUpView(
                        onSuccess: { authSheetMode = nil },
                        onSwitchToSignIn: { authSheetMode = .signIn }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                authSheetMode = nil
                            }
                        }
                    }
                case .signIn:
                    SignInView(
                        onSuccess: { authSheetMode = nil },
                        onSwitchToSignUp: { authSheetMode = .signUp }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                authSheetMode = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview("Profile") {
    NavigationStack {
        ProfileView()
    }
}

#Preview("Sign In Prompt") {
    SignInPromptCard()
        .padding()
}


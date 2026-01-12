//
//  PrivacySettingsView.swift
//  Bible v1
//
//  Privacy and security settings view
//

import SwiftUI
import LocalAuthentication

struct PrivacySettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    @State private var biometricType: LABiometryType = .none
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // App Lock Section
                    appLockSection
                    
                    // Data Privacy Section
                    dataPrivacySection
                    
                    // Analytics Section
                    analyticsSection
                }
                .padding()
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkBiometricType()
        }
        .alert("Biometric Error", isPresented: $showBiometricError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(biometricErrorMessage)
        }
    }
    
    // MARK: - App Lock Section
    
    private var appLockSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("APP LOCK")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Biometric lock toggle
                if biometricType != .none {
                    SettingsToggleRow(
                        icon: biometricIcon,
                        title: biometricTitle,
                        subtitle: "Require \(biometricTitle.lowercased()) to open app",
                        isOn: $settings.biometricLockEnabled
                    )
                    .onChange(of: settings.biometricLockEnabled) { _, newValue in
                        if newValue {
                            authenticateBiometric()
                        }
                    }
                    
                    Divider()
                        .background(themeManager.dividerColor)
                        .padding(.vertical, 12)
                }
                
                // Lock on background
                SettingsToggleRow(
                    icon: "clock.arrow.circlepath",
                    title: "Lock on Background",
                    subtitle: "Lock app when switching to another app",
                    isOn: $settings.lockOnBackground
                )
                .disabled(!settings.biometricLockEnabled)
                .opacity(settings.biometricLockEnabled ? 1 : 0.5)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Data Privacy Section
    
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DATA PRIVACY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Hide journal previews
                SettingsToggleRow(
                    icon: "eye.slash",
                    title: "Hide Journal Previews",
                    subtitle: "Show placeholder text in widgets and notifications",
                    isOn: $settings.hideJournalPreviews
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Hide prayer content
                SettingsToggleRow(
                    icon: "text.redaction",
                    title: "Private Prayer Mode",
                    subtitle: "Blur prayer content until tapped",
                    isOn: $settings.privatePrayerMode
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Incognito reading
                SettingsToggleRow(
                    icon: "eyeglasses",
                    title: "Private Reading",
                    subtitle: "Don't save reading history",
                    isOn: $settings.privateReadingMode
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Analytics Section
    
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ANALYTICS & IMPROVEMENTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Usage analytics
                SettingsToggleRow(
                    icon: "chart.bar",
                    title: "Usage Analytics",
                    subtitle: "Help improve the app with anonymous usage data",
                    isOn: $settings.analyticsEnabled
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Crash reports
                SettingsToggleRow(
                    icon: "exclamationmark.triangle",
                    title: "Crash Reports",
                    subtitle: "Automatically send crash reports",
                    isOn: $settings.crashReportsEnabled
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
            
            Text("Your data is stored locally on your device. We never sell or share your personal information.")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Helper Properties
    
    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield"
        @unknown default:
            return "lock.shield"
        }
    }
    
    private var biometricTitle: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric Lock"
        @unknown default:
            return "Biometric Lock"
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    private func authenticateBiometric() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            settings.biometricLockEnabled = false
            biometricErrorMessage = error?.localizedDescription ?? "Biometric authentication not available"
            showBiometricError = true
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Enable \(biometricTitle) to secure your app"
        ) { success, error in
            DispatchQueue.main.async {
                if !success {
                    settings.biometricLockEnabled = false
                    if let error = error {
                        biometricErrorMessage = error.localizedDescription
                        showBiometricError = true
                    }
                } else {
                    HapticManager.shared.success()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}


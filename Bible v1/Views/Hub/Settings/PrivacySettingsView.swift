//
//  PrivacySettingsView.swift
//  Bible v1
//
//  Spiritual Hub - Privacy Settings
//

import SwiftUI
import LocalAuthentication

struct PrivacySettingsView: View {
    @ObservedObject private var privacyManager = PrivacyManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showSetPasscode = false
    @State private var showBiometricError = false
    @State private var errorMessage = ""
    @State private var previousLockType: AppLockType = .none
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            List {
            // App Lock Section
            Section {
                // Lock type picker - mutually exclusive options
                Picker("App Lock", selection: $privacyManager.lockType) {
                    ForEach(AppLockType.allCases) { type in
                        // Only show biometric option if device supports it
                        if type == .biometric && !privacyManager.isBiometricAvailable {
                            EmptyView()
                        } else {
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                .onChange(of: privacyManager.lockType) { oldValue, newValue in
                    handleLockTypeChange(from: oldValue, to: newValue)
                }
                
                // Show "Change Passcode" only when passcode is the active lock type
                if privacyManager.lockType == .passcode {
                    Button {
                        showSetPasscode = true
                    } label: {
                        Label("Change Passcode", systemImage: "lock.rotation")
                    }
                }
                
                // Auto-lock timing (only when a lock is active)
                if privacyManager.lockType != .none {
                    Picker("Auto-lock", selection: $privacyManager.autoLockTiming) {
                        ForEach(AutoLockTiming.allCases) { timing in
                            Text(timing.rawValue).tag(timing)
                        }
                    }
                }
            } header: {
                Text("App Lock")
            } footer: {
                if privacyManager.lockType == .none {
                    Text("Choose Face ID/Touch ID or Passcode to protect your spiritual journal")
                } else if privacyManager.lockType == .biometric {
                    Text("Your app is protected with \(privacyManager.biometricName)")
                } else {
                    Text("Your app is protected with a 4-digit passcode")
                }
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            
            // Privacy Options Section
            Section {
                Toggle(isOn: $privacyManager.hidePrivateEntries) {
                    Label("Hide Private Entries", systemImage: "eye.slash")
                }
                .tint(themeManager.accentColor)
                
                Toggle(isOn: $privacyManager.blurOnBackground) {
                    Label("Blur When Backgrounded", systemImage: "rectangle.on.rectangle.angled")
                }
                .tint(themeManager.accentColor)
            } header: {
                Text("Privacy")
            } footer: {
                Text("Private entries will be hidden from the main view")
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            
            // Data Section
            Section {
                Toggle(isOn: Binding(
                    get: { privacyManager.localOnlyMode },
                    set: { newValue in
                        if newValue {
                            // Turning ON local-only mode (disabling cloud sync)
                            Task {
                                await privacyManager.enableLocalOnlyMode()
                            }
                        } else {
                            // Turning OFF local-only mode (enabling cloud sync)
                            // This requires authentication
                            privacyManager.requestDisableLocalOnlyMode()
                        }
                    }
                )) {
                    Label("Local-Only Mode", systemImage: "iphone")
                }
                .tint(themeManager.accentColor)
                
                // Show sync status when cloud sync is enabled
                if !privacyManager.localOnlyMode && AuthService.shared.isAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cloud Sync Enabled")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textColor)
                            if let user = AuthService.shared.currentUser {
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                        Spacer()
                    }
                }
            } header: {
                Text("Data Storage")
            } footer: {
                if privacyManager.localOnlyMode {
                    Text("When enabled, all data stays on your device and is never synced to the cloud")
                } else {
                    Text("Your data is synced securely across your devices")
                }
            }
            .listRowBackground(themeManager.cardBackgroundColor)
            
            // Info Section
            Section {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Data is Protected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textColor)
                        Text("All spiritual journal entries are encrypted and stored securely on your device.")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .listRowBackground(themeManager.cardBackgroundColor)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Privacy & Security")
        .sheet(isPresented: $showSetPasscode, onDismiss: {
            // If user cancelled without setting a passcode, revert to previous lock type
            if privacyManager.lockType == .passcode && !privacyManager.hasPasscodeSet {
                privacyManager.lockType = previousLockType
            }
        }) {
            SetPasscodeSheet()
        }
        .sheet(isPresented: $privacyManager.shouldShowAuthSheet) {
            AuthView(
                onAuthenticated: {
                    privacyManager.onAuthenticationSuccess()
                },
                onCancel: {
                    privacyManager.onAuthenticationCancelled()
                }
            )
        }
        .alert("Biometric Not Available", isPresented: $showBiometricError) {
            Button("OK", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(errorMessage.isEmpty ? "\(privacyManager.biometricName) is not available on this device or is not enabled in Settings." : errorMessage)
        }
        } // Close ZStack
    }
    
    private func handleLockTypeChange(from oldValue: AppLockType, to newValue: AppLockType) {
        previousLockType = oldValue
        
        switch newValue {
        case .none:
            privacyManager.disableLock()
        case .biometric:
            if !privacyManager.isBiometricAvailable {
                // Revert if biometric not available
                DispatchQueue.main.async {
                    privacyManager.lockType = oldValue
                }
                showBiometricError = true
            } else {
                enableBiometric(previousLockType: oldValue)
            }
        case .passcode:
            if !privacyManager.hasPasscodeSet {
                showSetPasscode = true
            }
        }
    }
    
    private func enableBiometric(previousLockType: AppLockType) {
        Task {
            let success = await privacyManager.enableBiometricLock()
            if !success {
                await MainActor.run {
                    // Revert to previous lock type if biometric setup fails/cancelled
                    privacyManager.lockType = previousLockType
                    errorMessage = "\(privacyManager.biometricName) authentication failed or was cancelled."
                    showBiometricError = true
                }
            }
        }
    }
}

// MARK: - Set Passcode Sheet

struct SetPasscodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var privacyManager = PrivacyManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var step: PasscodeStep = .enter
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum PasscodeStep {
        case enter
        case confirm
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
            VStack(spacing: 40) {
                // Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                // Instructions
                VStack(spacing: 8) {
                    Text(step == .enter ? "Enter a 4-digit passcode" : "Confirm your passcode")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                // Passcode dots
                HStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < currentPasscode.count ? themeManager.textColor : Color.clear)
                            .stroke(themeManager.textColor, lineWidth: 2)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        numberButton("\(number)")
                    }
                    
                    Spacer()
                    
                    numberButton("0")
                    
                    Button {
                        deleteDigit()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundColor(themeManager.textColor)
                            .frame(width: 70, height: 70)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.top, 40)
            } // Close ZStack
            .navigationTitle("Set Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var currentPasscode: String {
        step == .enter ? passcode : confirmPasscode
    }
    
    private func numberButton(_ number: String) -> some View {
        Button {
            addDigit(number)
        } label: {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
                .frame(width: 70, height: 70)
                .background(themeManager.cardBackgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private func addDigit(_ digit: String) {
        showError = false
        
        switch step {
        case .enter:
            if passcode.count < 4 {
                passcode.append(digit)
                if passcode.count == 4 {
                    step = .confirm
                }
            }
        case .confirm:
            if confirmPasscode.count < 4 {
                confirmPasscode.append(digit)
                if confirmPasscode.count == 4 {
                    verifyAndSave()
                }
            }
        }
    }
    
    private func deleteDigit() {
        switch step {
        case .enter:
            if !passcode.isEmpty {
                passcode.removeLast()
            }
        case .confirm:
            if !confirmPasscode.isEmpty {
                confirmPasscode.removeLast()
            }
        }
    }
    
    private func verifyAndSave() {
        if passcode == confirmPasscode {
            if privacyManager.setPasscode(passcode) {
                dismiss()
            } else {
                errorMessage = "Failed to save passcode"
                showError = true
                resetPasscodes()
            }
        } else {
            errorMessage = "Passcodes don't match. Try again."
            showError = true
            resetPasscodes()
        }
    }
    
    private func resetPasscodes() {
        passcode = ""
        confirmPasscode = ""
        step = .enter
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}


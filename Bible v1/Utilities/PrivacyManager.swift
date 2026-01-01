//
//  PrivacyManager.swift
//  Bible v1
//
//  Manages privacy and security settings for the app
//

import Foundation
import SwiftUI
import LocalAuthentication
import Combine

/// Types of app lock
enum AppLockType: String, CaseIterable, Codable, Identifiable {
    case none = "None"
    case biometric = "Face ID / Touch ID"
    case passcode = "Passcode"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "lock.open"
        case .biometric: return "faceid"
        case .passcode: return "lock.fill"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No lock required"
        case .biometric: return "Use Face ID or Touch ID to unlock"
        case .passcode: return "Enter a 4-digit passcode"
        }
    }
}

/// Auto-lock timing options
enum AutoLockTiming: String, CaseIterable, Codable, Identifiable {
    case immediately = "Immediately"
    case oneMinute = "After 1 minute"
    case fiveMinutes = "After 5 minutes"
    case fifteenMinutes = "After 15 minutes"
    case never = "Never"
    
    var id: String { rawValue }
    
    var seconds: TimeInterval? {
        switch self {
        case .immediately: return 0
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .fifteenMinutes: return 900
        case .never: return nil
        }
    }
}

/// Manages privacy and security
class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    private let defaults = UserDefaults.standard
    private let keychain = KeychainHelper.shared
    
    private enum Keys {
        static let lockType = "privacy_lock_type"
        static let autoLockTiming = "privacy_auto_lock_timing"
        static let hidePrivateEntries = "privacy_hide_private"
        static let localOnlyMode = "privacy_local_only"
        static let blurOnBackground = "privacy_blur_background"
        static let lastActiveTime = "privacy_last_active"
        static let passcodeHash = "privacy_passcode_hash"
    }
    
    // MARK: - Published Properties
    
    @Published var lockType: AppLockType {
        didSet {
            defaults.set(lockType.rawValue, forKey: Keys.lockType)
        }
    }
    
    @Published var autoLockTiming: AutoLockTiming {
        didSet {
            defaults.set(autoLockTiming.rawValue, forKey: Keys.autoLockTiming)
        }
    }
    
    @Published var hidePrivateEntries: Bool {
        didSet {
            defaults.set(hidePrivateEntries, forKey: Keys.hidePrivateEntries)
        }
    }
    
    /// Local-only mode - when true, data stays on device only
    /// When turned OFF, user must authenticate first
    @Published var localOnlyMode: Bool {
        didSet {
            defaults.set(localOnlyMode, forKey: Keys.localOnlyMode)
        }
    }
    
    /// Flag to show auth sheet when user tries to disable local-only mode
    @Published var shouldShowAuthSheet: Bool = false
    
    /// Pending local-only mode change (awaiting authentication)
    @Published var pendingLocalOnlyModeChange: Bool? = nil
    
    @Published var blurOnBackground: Bool {
        didSet {
            defaults.set(blurOnBackground, forKey: Keys.blurOnBackground)
        }
    }
    
    @Published private(set) var isLocked: Bool = false
    @Published private(set) var biometricType: LABiometryType = .none
    
    // MARK: - Cloud Sync Properties
    
    /// Returns true if user is authenticated and cloud sync is enabled
    var isCloudSyncEnabled: Bool {
        !localOnlyMode && AuthService.shared.isAuthenticated
    }
    
    private var lastActiveTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag to prevent auto-lock during biometric authentication
    private var isAuthenticating: Bool = false
    
    /// Flag indicating we're in an active unlocked session - prevents re-locking
    private var isUnlockedSession: Bool = false
    
    /// Timestamp when app went to true background (not just inactive for Face ID)
    private var backgroundEntryTime: Date?
    
    // MARK: - Initialization
    
    private init() {
        // Load lock type
        if let lockTypeRaw = defaults.string(forKey: Keys.lockType),
           let type = AppLockType(rawValue: lockTypeRaw) {
            lockType = type
        } else {
            lockType = .none
        }
        
        // Load auto lock timing
        if let timingRaw = defaults.string(forKey: Keys.autoLockTiming),
           let timing = AutoLockTiming(rawValue: timingRaw) {
            autoLockTiming = timing
        } else {
            autoLockTiming = .immediately
        }
        
        // Load boolean settings
        hidePrivateEntries = defaults.bool(forKey: Keys.hidePrivateEntries)
        localOnlyMode = defaults.object(forKey: Keys.localOnlyMode) == nil ? true : defaults.bool(forKey: Keys.localOnlyMode)
        blurOnBackground = defaults.bool(forKey: Keys.blurOnBackground)
        
        // Check biometric availability
        checkBiometricType()
        
        // Set initial lock state
        if lockType != .none {
            isLocked = true
        }
        
        // Setup app lifecycle observers
        setupLifecycleObservers()
    }
    
    // MARK: - Biometric
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    var isBiometricAvailable: Bool {
        biometricType != .none
    }
    
    var biometricName: String {
        switch biometricType {
        case .none: return "None"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometric"
        }
    }
    
    // MARK: - Lifecycle
    
    private func setupLifecycleObservers() {
        // Use didEnterBackground instead of willResignActive
        // willResignActive fires for Face ID, Control Center, etc. - not true background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.appDidEnterBackground()
            }
            .store(in: &cancellables)
        
        // Use willEnterForeground to check if we should lock
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.appWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    private func appDidEnterBackground() {
        // Only record background time if we're not authenticating
        // and we're in an unlocked session
        guard !isAuthenticating else { return }
        
        backgroundEntryTime = Date()
        defaults.set(backgroundEntryTime?.timeIntervalSince1970, forKey: Keys.lastActiveTime)
        
        // If auto-lock is immediate, lock now when going to background
        if autoLockTiming == .immediately && isUnlockedSession {
            isUnlockedSession = false
            isLocked = true
        }
    }
    
    private func appWillEnterForeground() {
        guard lockType != .none else { return }
        
        // Don't auto-lock while biometric authentication is in progress
        guard !isAuthenticating else { return }
        
        // If we're already locked or in an active unlocked session, don't change anything
        guard !isLocked && !isUnlockedSession else { return }
        
        // Check if enough time has passed to require re-lock
        guard let backgroundTime = backgroundEntryTime,
              let lockSeconds = autoLockTiming.seconds,
              lockSeconds > 0 else {
            // If autoLockTiming is .never (nil) or .immediately (0, handled in background), skip
            return
        }
        
        let elapsed = Date().timeIntervalSince(backgroundTime)
        if elapsed >= lockSeconds {
            isLocked = true
        }
    }
    
    // MARK: - Unlock Methods
    
    func unlockWithBiometric() async -> Bool {
        guard lockType == .biometric else { return false }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        // Set flag to prevent auto-lock during authentication
        await MainActor.run {
            isAuthenticating = true
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Bible app"
            )
            
            await MainActor.run {
                isAuthenticating = false
                if success {
                    isUnlockedSession = true
                    isLocked = false
                }
            }
            return success
        } catch {
            await MainActor.run {
                isAuthenticating = false
            }
            return false
        }
    }
    
    func unlockWithPasscode(_ passcode: String) -> Bool {
        guard lockType == .passcode else { return false }
        
        if verifyPasscode(passcode) {
            isUnlockedSession = true
            isLocked = false
            return true
        }
        return false
    }
    
    func lock() {
        if lockType != .none {
            isUnlockedSession = false
            isLocked = true
        }
    }
    
    // MARK: - Passcode Management
    
    func setPasscode(_ passcode: String) -> Bool {
        guard passcode.count == 4, passcode.allSatisfy({ $0.isNumber }) else {
            return false
        }
        
        let hash = hashPasscode(passcode)
        keychain.save(hash, forKey: Keys.passcodeHash)
        lockType = .passcode
        return true
    }
    
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedHash = keychain.load(forKey: Keys.passcodeHash) else {
            return false
        }
        return hashPasscode(passcode) == storedHash
    }
    
    func removePasscode() {
        keychain.delete(forKey: Keys.passcodeHash)
        if lockType == .passcode {
            lockType = .none
        }
    }
    
    var hasPasscodeSet: Bool {
        keychain.load(forKey: Keys.passcodeHash) != nil
    }
    
    private func hashPasscode(_ passcode: String) -> String {
        // Simple hash - in production, use proper cryptographic hashing
        let data = passcode.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Enable/Disable Lock
    
    func enableBiometricLock() async -> Bool {
        guard isBiometricAvailable else { return false }
        
        // Set flag to prevent auto-lock during authentication
        await MainActor.run {
            isAuthenticating = true
        }
        
        // Verify biometric first
        let context = LAContext()
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Enable \(biometricName) lock"
            )
            
            await MainActor.run {
                isAuthenticating = false
                if success {
                    // Clear any existing passcode when switching to biometric
                    keychain.delete(forKey: Keys.passcodeHash)
                    lockType = .biometric
                    isUnlockedSession = true
                    isLocked = false
                }
            }
            return success
        } catch {
            await MainActor.run {
                isAuthenticating = false
            }
            return false
        }
    }
    
    func disableLock() {
        lockType = .none
        isUnlockedSession = true
        isLocked = false
        removePasscode()
    }
    
    // MARK: - Privacy Helpers
    
    /// Check if an entry should be shown based on privacy settings
    func shouldShowEntry(isPrivate: Bool) -> Bool {
        if isPrivate && hidePrivateEntries {
            return false
        }
        return true
    }
    
    // MARK: - Local-Only Mode & Cloud Sync
    
    /// Request to disable local-only mode
    /// This will trigger authentication if user is not already authenticated
    func requestDisableLocalOnlyMode() {
        if AuthService.shared.isAuthenticated {
            // Already authenticated, disable immediately
            localOnlyMode = false
        } else {
            // Need to authenticate first
            pendingLocalOnlyModeChange = false
            shouldShowAuthSheet = true
        }
    }
    
    /// Called when authentication completes successfully
    func onAuthenticationSuccess() {
        if let pending = pendingLocalOnlyModeChange {
            localOnlyMode = pending
        }
        pendingLocalOnlyModeChange = nil
        shouldShowAuthSheet = false
    }
    
    /// Called when user cancels authentication
    func onAuthenticationCancelled() {
        pendingLocalOnlyModeChange = nil
        shouldShowAuthSheet = false
        // Revert to local-only mode if it was the pending change
        localOnlyMode = true
    }
    
    /// Enable local-only mode (sign out from cloud)
    func enableLocalOnlyMode() async {
        // Sign out from cloud
        await AuthService.shared.signOut()
        localOnlyMode = true
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        lockType = .none
        autoLockTiming = .immediately
        hidePrivateEntries = false
        localOnlyMode = true
        blurOnBackground = false
        isLocked = false
        removePasscode()
    }
}

// MARK: - Keychain Helper

class KeychainHelper {
    static let shared = KeychainHelper()
    
    private init() {}
    
    func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    @ObservedObject private var privacyManager = PrivacyManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var passcode = ""
    @State private var showError = false
    @State private var hasAttemptedBiometric = false
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.accentColor)
                
                Text("Bible App Locked")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                if privacyManager.lockType == .biometric {
                    biometricUnlockButton
                } else if privacyManager.lockType == .passcode {
                    passcodeEntry
                }
            }
            .padding()
        }
        .onAppear {
            // Auto-trigger biometric on appear
            if privacyManager.lockType == .biometric && !hasAttemptedBiometric {
                hasAttemptedBiometric = true
                attemptBiometricUnlock()
            }
        }
    }
    
    private var biometricUnlockButton: some View {
        Button {
            attemptBiometricUnlock()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: privacyManager.biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.accentColor)
                
                Text("Tap to Unlock")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(24)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private var passcodeEntry: some View {
        VStack(spacing: 24) {
            // Passcode dots
            HStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < passcode.count ? themeManager.accentColor : Color.clear)
                        .overlay(
                            Circle().stroke(themeManager.accentColor, lineWidth: 2)
                        )
                        .frame(width: 16, height: 16)
                }
            }
            
            if showError {
                Text("Incorrect passcode")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Number pad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { number in
                    numberButton("\(number)")
                }
                
                Color.clear.frame(width: 70, height: 70)
                
                numberButton("0")
                
                Button {
                    if !passcode.isEmpty {
                        passcode.removeLast()
                        showError = false
                    }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(themeManager.textColor)
                        .frame(width: 70, height: 70)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
        }
    }
    
    private func numberButton(_ number: String) -> some View {
        Button {
            guard passcode.count < 4 else { return }
            passcode.append(number)
            showError = false
            
            if passcode.count == 4 {
                if privacyManager.unlockWithPasscode(passcode) {
                    // Success - unlocked
                } else {
                    showError = true
                    passcode = ""
                }
            }
        } label: {
            Text(number)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
                .frame(width: 70, height: 70)
                .background(themeManager.cardBackgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    private func attemptBiometricUnlock() {
        Task {
            let success = await privacyManager.unlockWithBiometric()
            if !success {
                await MainActor.run {
                    hasAttemptedBiometric = false
                }
            }
        }
    }
}

// MARK: - Background Blur Modifier

struct BackgroundBlurModifier: ViewModifier {
    @ObservedObject private var privacyManager = PrivacyManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if privacyManager.blurOnBackground && scenePhase != .active {
                    themeManager.backgroundColor
                        .overlay(.ultraThinMaterial)
                        .ignoresSafeArea()
                }
            }
    }
}

extension View {
    func privacyBlur() -> some View {
        modifier(BackgroundBlurModifier())
    }
}

// Import for CC_SHA256
import CommonCrypto


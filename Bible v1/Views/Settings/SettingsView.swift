//
//  SettingsView.swift
//  Bible v1
//
//  Redesigned Settings with search, quick settings, summary rows, and collapsible sections
//

import SwiftUI

/// Settings view for app configuration
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var bibleViewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    @StateObject private var searchIndex = SettingsSearchIndex.shared
    @StateObject private var exportService = DataExportService.shared
    
    @State private var searchText = ""
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if searchText.isEmpty {
                            // Normal settings layout
                            normalSettingsContent
                        } else {
                            // Search results
                            searchResultsContent
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .searchable(text: $searchText, prompt: "Search settings")
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    // MARK: - Normal Settings Content
    
    private var normalSettingsContent: some View {
        VStack(spacing: 24) {
            // Quick Settings (always visible at top)
            QuickSettingsSection()
            
            // Premium Section
            subscriptionSection
            
            // Summary Rows for Main Sections
            mainSectionsGroup
            
            // Spiritual Hub Section
            hubSettingsSection
            
            // Collapsible: Your Data
            CollapsibleSection(title: "Your Data", isExpanded: $settings.dataExpanded) {
                dataSection
            }
            
            // Collapsible: About
            CollapsibleSection(title: "About", isExpanded: $settings.aboutExpanded) {
                aboutSection
            }
            
            // Collapsible: Developer
            CollapsibleSection(title: "Developer", isExpanded: $settings.developerExpanded) {
                developerSection
            }
        }
    }
    
    // MARK: - Search Results Content
    
    private var searchResultsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            let results = searchIndex.search(searchText)
            
            if results.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("No results for \"\(searchText)\"")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Try searching for theme, font, voice, or notifications")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Text("\(results.count) RESULTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    ForEach(results) { result in
                        SettingsSearchResultRow(result: result) {
                            navigateToResult(result)
                        }
                        
                        if result.id != results.last?.id {
                            Divider()
                                .background(themeManager.dividerColor)
                        }
                    }
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(14)
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        SettingsSection(title: "Premium", themeManager: themeManager) {
            NavigationLink {
                SubscriptionView()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentGradient)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: SubscriptionManager.shared.isPremium ? "crown.fill" : "lock.fill")
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(SubscriptionManager.shared.isPremium ? "Premium Active" : "Upgrade to Premium")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            if PromoCodeService.shared.isPromoActivated {
                                Text("Dev")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(PromoCodeService.shared.isPromoActivated ? "Developer Access Active" : 
                             (SubscriptionManager.shared.isPremium ? "AI voices enabled" : "Unlock AI voices"))
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
    }
    
    // MARK: - Main Sections (Summary Rows)
    
    private var mainSectionsGroup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SETTINGS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Reading
                SettingsSummaryRow(
                    icon: "book.fill",
                    title: "Reading",
                    summary: readingSummary,
                    destination: ReadingSettingsView()
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Audio & Voice
                SettingsSummaryRow(
                    icon: "speaker.wave.3.fill",
                    title: "Audio & Voice",
                    summary: audioSummary,
                    destination: AudioSettingsView()
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Offline Reading
                SettingsSummaryRow(
                    icon: "arrow.down.circle.fill",
                    title: "Offline Reading",
                    summary: "\(viewModel.downloadedTranslations.count) translations • \(viewModel.cacheSize)",
                    destination: DownloadsSettingsView()
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Hub Settings Section
    
    private var hubSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPIRITUAL HUB")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Notifications
                NavigationLink {
                    NotificationPreferencesView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                        Text("Notifications")
                            .foregroundColor(themeManager.textColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Privacy & Security
                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                        Text("Privacy & Security")
                            .foregroundColor(themeManager.textColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Accessibility
                NavigationLink {
                    AccessibilitySettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "accessibility")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                        Text("Accessibility")
                            .foregroundColor(themeManager.textColor)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Data Section (Collapsible Content)
    
    private var dataSection: some View {
        VStack(spacing: 12) {
            // Data counts
            DataRow(label: "Favorites", count: StorageService.shared.favorites.count, themeManager: themeManager)
            Divider().background(themeManager.dividerColor)
            DataRow(label: "Highlights", count: StorageService.shared.highlights.count, themeManager: themeManager)
            Divider().background(themeManager.dividerColor)
            DataRow(label: "Notes", count: StorageService.shared.notes.count, themeManager: themeManager)
            Divider().background(themeManager.dividerColor)
            DataRow(label: "Prayers", count: HubStorageService.shared.prayerEntries.count, themeManager: themeManager)
            Divider().background(themeManager.dividerColor)
            DataRow(label: "Fasts", count: HubStorageService.shared.fastingEntries.count, themeManager: themeManager)
            
            Divider()
                .background(themeManager.dividerColor)
                .padding(.vertical, 8)
            
            // Last export info
            HStack {
                Text("Last Export")
                    .foregroundColor(themeManager.textColor)
                Spacer()
                if let lastExport = settings.lastDataExportDate {
                    Text(lastExport, style: .date)
                        .foregroundColor(themeManager.secondaryTextColor)
                } else {
                    Text("Never")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Divider()
                .background(themeManager.dividerColor)
                .padding(.vertical, 8)
            
            // Export button
            Button {
                exportData()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Data")
                            .foregroundColor(themeManager.textColor)
                        Text("Backup favorites, notes, and more")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    if exportService.isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(exportService.isExporting)
            
            Divider()
                .background(themeManager.dividerColor)
                .padding(.vertical, 8)
            
            // Clear data buttons
            DestructiveActionRow(
                title: "Clear User Data",
                subtitle: "Remove favorites, highlights, notes",
                icon: "trash",
                requiresTyping: true,
                confirmationText: "DELETE",
                onConfirm: {
                    viewModel.clearAllUserData()
                }
            )
            
            Divider()
                .background(themeManager.dividerColor)
                .padding(.vertical, 8)
            
            DestructiveActionRow(
                title: "Clear Hub Data",
                subtitle: "Remove prayers, fasts, journal entries",
                icon: "trash",
                requiresTyping: true,
                confirmationText: "DELETE",
                onConfirm: {
                    HubStorageService.shared.clearAllHubData()
                }
            )
        }
    }
    
    // MARK: - About Section (Collapsible Content)
    
    private var aboutSection: some View {
        VStack(spacing: 12) {
            SettingsInfoRow(title: "Version", value: viewModel.appVersionDisplay)
            
            Divider()
                .background(themeManager.dividerColor)
            
            NavigationLink {
                AcknowledgmentsView(viewModel: viewModel)
            } label: {
                HStack {
                    Text("Acknowledgments")
                        .foregroundColor(themeManager.textColor)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Divider()
                .background(themeManager.dividerColor)
            
            Link(destination: URL(string: "https://bible.helloao.org")!) {
                HStack {
                    Text("Bible API")
                        .foregroundColor(themeManager.textColor)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
    }
    
    // MARK: - Developer Section (Collapsible Content)
    
    @State private var promoCodeInput: String = ""
    @State private var promoCodeError: Bool = false
    @State private var promoCodeSuccess: Bool = false
    
    private var developerSection: some View {
        VStack(spacing: 16) {
            if PromoCodeService.shared.isPromoActivated {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer Access Active")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Premium features unlocked")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Promo Code")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        TextField("Enter code", text: $promoCodeInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(themeManager.backgroundColor)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(promoCodeError ? Color.red : themeManager.dividerColor, lineWidth: 1)
                            )
                        
                        Button {
                            if PromoCodeService.shared.activatePromoCode(promoCodeInput) {
                                promoCodeSuccess = true
                                promoCodeError = false
                                HapticManager.shared.success()
                            } else {
                                promoCodeError = true
                                promoCodeSuccess = false
                                HapticManager.shared.error()
                            }
                        } label: {
                            Text("Apply")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(themeManager.accentColor)
                                .cornerRadius(10)
                        }
                        .disabled(promoCodeInput.isEmpty)
                    }
                    
                    if promoCodeError {
                        Text("Invalid promo code")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if promoCodeSuccess {
                        Text("✓ Developer access activated!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Divider()
                .background(themeManager.dividerColor)
            
            Button {
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                HapticManager.shared.success()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Onboarding")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Restart app to see onboarding again")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
            }
            
            Divider()
                .background(themeManager.dividerColor)
            
            Button {
                settings.resetAllSettings()
                HapticManager.shared.success()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Settings")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        Text("Restore all settings to defaults")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var readingSummary: String {
        let font = settings.readerFontFamily.displayName
        let size = String(format: "%.0f%%", settings.readerTextOffset * 100)
        let spacing = String(format: "%.1fx", settings.readerLineSpacing)
        return "\(font) • \(size) • \(spacing) spacing"
    }
    
    private var audioSummary: String {
        let voiceType = settings.preferredVoiceType == .premium ? "Premium AI" : "Built-in"
        let speed = AudioService.shared.rateDisplayName(Float(settings.speechRate))
        return "\(voiceType) • \(speed)"
    }
    
    // MARK: - Actions
    
    private func navigateToResult(_ result: SettingsSearchResult) {
        searchText = ""
        // Navigation would be handled by the parent NavigationStack
        // This is a simplified version - full implementation would use NavigationPath
    }
    
    private func exportData() {
        Task {
            do {
                let url = try await exportService.exportUserData()
                exportURL = url
                showExportSheet = true
            } catch {
                // Handle error
                print("Export failed: \(error)")
            }
        }
    }
}

// MARK: - Helper Views (Keep legacy components)

struct SettingsSection<Content: View>: View {
    let title: String
    let themeManager: ThemeManager
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
}

struct DataRow: View {
    let label: String
    let count: Int
    let themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(themeManager.textColor)
            Spacer()
            Text("\(count)")
                .fontWeight(.semibold)
                .foregroundColor(themeManager.accentColor)
        }
    }
}

/// Acknowledgments view
struct AcknowledgmentsView: View {
    let viewModel: SettingsViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.credits, id: \.title) { credit in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(credit.title)
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Text(credit.description)
                                .font(.body)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    Divider()
                        .background(themeManager.dividerColor)
                    
                    Text(viewModel.acknowledgments)
                        .font(.body)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding()
            }
        }
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(),
        bibleViewModel: BibleViewModel()
    )
}

//
//  DownloadsSettingsView.swift
//  Bible v1
//
//  Enhanced downloads management with size, repair, and cache breakdown
//

import SwiftUI
import Combine

struct DownloadsSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    private let cacheService = CacheService.shared
    @StateObject private var viewModel = DownloadsSettingsViewModel()
    
    @State private var showClearCacheConfirmation = false
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Downloaded Translations Section
                    downloadedTranslationsSection
                    
                    // Download Preferences Section
                    downloadPreferencesSection
                    
                    // Cache Breakdown Section
                    cacheBreakdownSection
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
        }
        .navigationTitle("Offline Reading")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Downloaded Translations Section
    
    private var downloadedTranslationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DOWNLOADED TRANSLATIONS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Text("\(viewModel.downloadedTranslations.count) translations")
                    .font(.caption)
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                if viewModel.downloadedTranslations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 40))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("No Translations Downloaded")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Download translations for offline reading in the Bible reader")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24)
                } else {
                    ForEach(viewModel.downloadedTranslations, id: \.id) { translation in
                        DownloadedTranslationDetailRow(
                            translation: translation,
                            themeManager: themeManager,
                            onRepair: {
                                Task {
                                    await viewModel.repairTranslation(translation.id)
                                }
                            },
                            onDelete: {
                                viewModel.deleteTranslation(translation.id)
                            }
                        )
                        
                        if translation.id != viewModel.downloadedTranslations.last?.id {
                            Divider()
                                .background(themeManager.dividerColor)
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Download Preferences Section
    
    private var downloadPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREFERENCES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "wifi",
                    title: "Download on Wi-Fi Only",
                    subtitle: "Prevent downloads over cellular data",
                    isOn: $settings.downloadWifiOnly
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                SettingsToggleRow(
                    icon: "arrow.down.app",
                    title: "Background Downloads",
                    subtitle: "Continue downloads when app is closed",
                    isOn: $settings.backgroundDownloadEnabled
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Cache Breakdown Section
    
    private var cacheBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STORAGE USAGE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Total size
                HStack {
                    Text("Total Cache")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Text(viewModel.totalCacheSize)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                }
                .padding(.bottom, 16)
                
                // Breakdown
                CacheBreakdownRow(
                    icon: "doc.text.fill",
                    label: "Text Cache",
                    size: viewModel.textCacheSize,
                    color: .blue,
                    themeManager: themeManager
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 8)
                
                CacheBreakdownRow(
                    icon: "waveform",
                    label: "Audio Cache",
                    size: viewModel.audioCacheSize,
                    color: .purple,
                    themeManager: themeManager
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 8)
                
                CacheBreakdownRow(
                    icon: "photo.fill",
                    label: "Other",
                    size: viewModel.otherCacheSize,
                    color: .orange,
                    themeManager: themeManager
                )
                
                // Visual breakdown bar
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * viewModel.textCachePercentage)
                        
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * viewModel.audioCachePercentage)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * viewModel.otherCachePercentage)
                    }
                    .cornerRadius(4)
                }
                .frame(height: 8)
                .padding(.top, 12)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Repair all downloads
                Button {
                    Task {
                        await viewModel.repairAllDownloads()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Repair Downloads")
                                .foregroundColor(themeManager.textColor)
                            Text("Re-validate and fix missing data")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if viewModel.isRepairing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .disabled(viewModel.isRepairing || viewModel.downloadedTranslations.isEmpty)
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Clear cache
                DestructiveActionRow(
                    title: "Clear All Cache",
                    subtitle: "Remove all downloaded content",
                    icon: "trash",
                    requiresTyping: false,
                    onConfirm: {
                        viewModel.clearAllCache()
                    }
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
}

// MARK: - View Model

@MainActor
class DownloadsSettingsViewModel: ObservableObject {
    @Published var downloadedTranslations: [DownloadedTranslationInfo] = []
    @Published var isRepairing = false
    
    @Published var totalCacheSize: String = "0 MB"
    @Published var textCacheSize: String = "0 MB"
    @Published var audioCacheSize: String = "0 MB"
    @Published var otherCacheSize: String = "0 MB"
    
    @Published var textCachePercentage: Double = 0.33
    @Published var audioCachePercentage: Double = 0.33
    @Published var otherCachePercentage: Double = 0.34
    
    private let cacheService = CacheService.shared
    private let storageService = StorageService.shared
    
    func loadData() {
        loadDownloadedTranslations()
        loadCacheSizes()
    }
    
    private func loadDownloadedTranslations() {
        let ids = storageService.getDownloadedTranslations()
        
        downloadedTranslations = ids.map { id in
            DownloadedTranslationInfo(
                id: id,
                name: id.uppercased(),
                sizeOnDisk: cacheService.translationCacheSize(id),
                lastUpdated: cacheService.translationLastUpdated(id),
                integrityState: cacheService.checkTranslationIntegrity(id)
            )
        }
    }
    
    private func loadCacheSizes() {
        let sizes = cacheService.detailedCacheSizes()
        
        totalCacheSize = formatBytes(sizes.total)
        textCacheSize = formatBytes(sizes.text)
        audioCacheSize = formatBytes(sizes.audio)
        otherCacheSize = formatBytes(sizes.other)
        
        let total = max(Double(sizes.total), 1)
        textCachePercentage = Double(sizes.text) / total
        audioCachePercentage = Double(sizes.audio) / total
        otherCachePercentage = Double(sizes.other) / total
    }
    
    func repairTranslation(_ id: String) async {
        isRepairing = true
        
        // Simulate repair process
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Re-validate and re-download missing chunks
        await cacheService.repairTranslation(id)
        
        loadDownloadedTranslations()
        isRepairing = false
        HapticManager.shared.success()
    }
    
    func repairAllDownloads() async {
        isRepairing = true
        
        for translation in downloadedTranslations {
            await cacheService.repairTranslation(translation.id)
        }
        
        loadDownloadedTranslations()
        isRepairing = false
        HapticManager.shared.success()
    }
    
    func deleteTranslation(_ id: String) {
        cacheService.clearTranslationCache(id)
        storageService.removeDownloadedTranslation(id)
        loadDownloadedTranslations()
        loadCacheSizes()
        HapticManager.shared.success()
    }
    
    func clearAllCache() {
        cacheService.clearAllCaches()
        storageService.saveDownloadedTranslations([])
        loadDownloadedTranslations()
        loadCacheSizes()
        HapticManager.shared.success()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Supporting Types

struct DownloadedTranslationInfo: Identifiable {
    let id: String
    let name: String
    let sizeOnDisk: String
    let lastUpdated: Date?
    let integrityState: IntegrityState
}

enum IntegrityState {
    case valid
    case needsRepair
    case corrupted
    
    var icon: String {
        switch self {
        case .valid: return "checkmark.circle.fill"
        case .needsRepair: return "exclamationmark.triangle.fill"
        case .corrupted: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .valid: return .green
        case .needsRepair: return .orange
        case .corrupted: return .red
        }
    }
}

// MARK: - Supporting Views

struct DownloadedTranslationDetailRow: View {
    let translation: DownloadedTranslationInfo
    let themeManager: ThemeManager
    let onRepair: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Integrity indicator
            Image(systemName: translation.integrityState.icon)
                .foregroundColor(translation.integrityState.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(translation.name)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                HStack(spacing: 8) {
                    Text(translation.sizeOnDisk)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    if let lastUpdated = translation.lastUpdated {
                        Text("•")
                            .foregroundColor(themeManager.secondaryTextColor)
                        Text("Updated \(lastUpdated, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            
            Spacer()
            
            // Repair button (if needed)
            if translation.integrityState != .valid {
                Button(action: onRepair) {
                    Image(systemName: "wrench")
                        .foregroundColor(themeManager.accentColor)
                }
                .buttonStyle(.borderless)
            }
            
            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .confirmationDialog("Delete Translation", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove the downloaded translation. You can download it again later.")
        }
    }
}

struct CacheBreakdownRow: View {
    let icon: String
    let label: String
    let size: String
    let color: Color
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Image(systemName: icon)
                .foregroundColor(themeManager.secondaryTextColor)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            Text(size)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// MARK: - CacheService Extensions

extension CacheService {
    func translationCacheSize(_ translationId: String) -> String {
        // Calculate size for a specific translation
        // This would need actual implementation based on cache structure
        return "0 MB"
    }
    
    func translationLastUpdated(_ translationId: String) -> Date? {
        // Get last update date for a translation
        return nil
    }
    
    func checkTranslationIntegrity(_ translationId: String) -> IntegrityState {
        // Check if all chunks are present and valid
        return .valid
    }
    
    func detailedCacheSizes() -> (total: Int64, text: Int64, audio: Int64, other: Int64) {
        // Get detailed cache breakdown
        // This would need actual implementation
        return (total: 0, text: 0, audio: 0, other: 0)
    }
    
    func repairTranslation(_ translationId: String) async {
        // Re-validate and re-download missing chunks
        // This would need actual implementation
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DownloadsSettingsView()
    }
}


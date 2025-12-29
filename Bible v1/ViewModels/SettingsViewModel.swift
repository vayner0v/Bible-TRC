//
//  SettingsViewModel.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import SwiftUI
import Combine

/// View model for app settings
@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var downloadedTranslations: [String] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var downloadingTranslationId: String?
    
    @Published var cacheSize: String = "Calculating..."
    
    @Published var showClearDataAlert = false
    @Published var showClearCacheAlert = false
    
    // MARK: - Services
    
    private let cacheService = CacheService.shared
    private let storageService = StorageService.shared
    let themeManager = ThemeManager.shared
    
    // MARK: - Initialization
    
    init() {
        loadDownloadedTranslations()
        updateCacheSize()
    }
    
    // MARK: - Downloaded Translations
    
    func loadDownloadedTranslations() {
        downloadedTranslations = storageService.getDownloadedTranslations()
    }
    
    func isTranslationDownloaded(_ translationId: String) -> Bool {
        downloadedTranslations.contains(translationId)
    }
    
    func downloadTranslation(_ translation: Translation, books: [Book]) async {
        guard !isDownloading else { return }
        
        isDownloading = true
        downloadingTranslationId = translation.id
        downloadProgress = 0
        
        do {
            try await cacheService.downloadTranslation(
                translation.id,
                books: books
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
            
            storageService.addDownloadedTranslation(translation.id)
            loadDownloadedTranslations()
        } catch {
            print("Download failed: \(error)")
        }
        
        isDownloading = false
        downloadingTranslationId = nil
        downloadProgress = 0
        updateCacheSize()
    }
    
    func deleteDownloadedTranslation(_ translationId: String) {
        cacheService.clearTranslationCache(translationId)
        storageService.removeDownloadedTranslation(translationId)
        loadDownloadedTranslations()
        updateCacheSize()
    }
    
    // MARK: - Cache Management
    
    func updateCacheSize() {
        cacheSize = cacheService.formattedCacheSize()
    }
    
    func clearCache() {
        cacheService.clearAllCaches()
        downloadedTranslations = []
        storageService.saveDownloadedTranslations([])
        updateCacheSize()
    }
    
    // MARK: - User Data
    
    func clearAllUserData() {
        storageService.clearAllUserData()
    }
    
    // MARK: - App Info
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var appVersionDisplay: String {
        "Version \(appVersion) (\(buildNumber))"
    }
    
    // MARK: - Credits
    
    var credits: [(title: String, description: String)] {
        [
            ("Bible Data", "Scripture text provided by the Free Use Bible API (bible.helloao.org)"),
            ("Translations", "Various public domain and freely licensed Bible translations"),
            ("Open Source", "Built with love for everyone seeking to read God's Word"),
        ]
    }
    
    var acknowledgments: String {
        """
        This app uses scripture texts from the Free Use Bible API, \
        which provides access to over 1000 Bible translations in a unified format.
        
        All scripture texts are either in the public domain or freely licensed \
        for non-commercial use.
        
        Special thanks to:
        • AO Lab for the Free Use Bible API
        • The Berean Study Bible team
        • All translation teams who have made God's Word accessible
        
        This app is free, has no ads, and requires no account. \
        It was created to help everyone access and study the Bible.
        """
    }
}


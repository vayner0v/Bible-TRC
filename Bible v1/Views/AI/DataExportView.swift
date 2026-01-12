//
//  DataExportView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Data Export/Import Interface
//

import SwiftUI
import UniformTypeIdentifiers

/// View for exporting and importing AI conversation data
struct DataExportView: View {
    @ObservedObject private var storageService = ChatStorageService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingExporter: Bool = false
    @State private var showingImporter: Bool = false
    @State private var showingClearConfirmation: Bool = false
    @State private var exportData: Data?
    @State private var importResult: ImportResult?
    @State private var showingResult: Bool = false
    
    enum ImportResult {
        case success(Int)
        case failure(String)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Export Section
                Section {
                    exportAllButton
                    exportCurrentButton
                } header: {
                    Text("Export Data")
                } footer: {
                    Text("Export your conversations as a JSON file that can be imported later or on another device.")
                }
                
                // Import Section
                Section {
                    importButton
                } header: {
                    Text("Import Data")
                } footer: {
                    Text("Import conversations from a previously exported JSON file. Duplicate conversations will be skipped.")
                }
                
                // Statistics Section
                Section {
                    statsRow(label: "Conversations", value: "\(storageService.conversationCount)")
                    statsRow(label: "Messages", value: "\(storageService.totalMessageCount)")
                    statsRow(label: "Active", value: "\(storageService.activeConversationCount)")
                    statsRow(label: "Archived", value: "\(storageService.archivedCount)")
                } header: {
                    Text("Current Data")
                }
                
                // Danger Zone
                Section {
                    clearDataButton
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This action cannot be undone. Consider exporting your data first.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .tint(themeManager.accentColor)
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: JSONDocument(data: exportData ?? Data()),
                contentType: .json,
                defaultFilename: "trc_ai_conversations_\(dateString).json"
            ) { result in
                handleExportResult(result)
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert("Clear All Data?", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    storageService.deleteAllConversations()
                    HapticManager.shared.warning()
                }
            } message: {
                Text("This will permanently delete all \(storageService.conversationCount) conversations and \(storageService.totalMessageCount) messages. This action cannot be undone.")
            }
            .alert(importResultTitle, isPresented: $showingResult) {
                Button("OK") { }
            } message: {
                Text(importResultMessage)
            }
        }
    }
    
    // MARK: - Export Buttons
    
    private var exportAllButton: some View {
        Button {
            if let data = storageService.exportAllAsJSON() {
                exportData = data
                showingExporter = true
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Export All Conversations")
                        .foregroundColor(themeManager.textColor)
                    Text("\(storageService.conversationCount) conversations")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            } icon: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .disabled(storageService.conversations.isEmpty)
    }
    
    private var exportCurrentButton: some View {
        Button {
            if let current = storageService.currentConversation {
                let text = storageService.exportConversation(current)
                UIPasteboard.general.string = text
                HapticManager.shared.success()
                importResult = .success(0)
                showingResult = true
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Copy Current Conversation")
                        .foregroundColor(themeManager.textColor)
                    Text("Copy as formatted text")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            } icon: {
                Image(systemName: "doc.on.clipboard")
                    .foregroundColor(themeManager.accentColor)
            }
        }
        .disabled(storageService.currentConversation == nil)
    }
    
    // MARK: - Import Button
    
    private var importButton: some View {
        Button {
            showingImporter = true
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Import Conversations")
                        .foregroundColor(themeManager.textColor)
                    Text("From JSON file")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            } icon: {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(themeManager.accentColor)
            }
        }
    }
    
    // MARK: - Clear Data Button
    
    private var clearDataButton: some View {
        Button(role: .destructive) {
            showingClearConfirmation = true
        } label: {
            Label("Clear All Data", systemImage: "trash")
        }
        .disabled(storageService.conversations.isEmpty)
    }
    
    // MARK: - Stats Row
    
    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(themeManager.textColor)
            Spacer()
            Text(value)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Helpers
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            HapticManager.shared.success()
        case .failure(let error):
            importResult = .failure(error.localizedDescription)
            showingResult = true
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "DataExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                let count = try storageService.importFromJSON(data)
                
                importResult = .success(count)
                showingResult = true
                HapticManager.shared.success()
            } catch {
                importResult = .failure(error.localizedDescription)
                showingResult = true
                HapticManager.shared.error()
            }
            
        case .failure(let error):
            importResult = .failure(error.localizedDescription)
            showingResult = true
        }
    }
    
    private var importResultTitle: String {
        switch importResult {
        case .success(let count):
            return count == 0 ? "Copied!" : "Import Successful"
        case .failure:
            return "Error"
        case .none:
            return ""
        }
    }
    
    private var importResultMessage: String {
        switch importResult {
        case .success(let count):
            return count == 0 
                ? "Conversation copied to clipboard."
                : "Successfully imported \(count) conversation\(count == 1 ? "" : "s")."
        case .failure(let error):
            return error
        case .none:
            return ""
        }
    }
}

// MARK: - JSON Document for File Export

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

#Preview {
    DataExportView()
}



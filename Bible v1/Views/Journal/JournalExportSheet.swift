//
//  JournalExportSheet.swift
//  Bible v1
//
//  Spiritual Journal - Export Options Sheet
//

import SwiftUI
import PDFKit

/// Sheet for exporting journal entries
struct JournalExportSheet: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ExportFormat = .text
    @State private var selectedDateRange: DateRangeOption = .all
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var includePhotos = false
    @State private var includeMoods = true
    @State private var includeTags = true
    @State private var includeLinkedVerses = true
    
    @State private var isExporting = false
    @State private var showingShareSheet = false
    @State private var exportedContent: String = ""
    @State private var exportedURL: URL?
    
    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text"
        case markdown = "Markdown"
        case pdf = "PDF"
        
        var icon: String {
            switch self {
            case .text: return "doc.text"
            case .markdown: return "doc.richtext"
            case .pdf: return "doc.fill"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .text: return "txt"
            case .markdown: return "md"
            case .pdf: return "pdf"
            }
        }
    }
    
    enum DateRangeOption: String, CaseIterable {
        case all = "All Time"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case thisYear = "This Year"
        case custom = "Custom Range"
        
        var icon: String {
            switch self {
            case .all: return "infinity"
            case .thisMonth: return "calendar"
            case .lastMonth: return "calendar.badge.clock"
            case .thisYear: return "calendar.badge.plus"
            case .custom: return "calendar.badge.exclamationmark"
            }
        }
    }
    
    private var filteredEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .all:
            return viewModel.entries
        case .thisMonth:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return viewModel.entries
            }
            return viewModel.entries.filter { $0.dateCreated >= startOfMonth }
        case .lastMonth:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth) else {
                return viewModel.entries
            }
            return viewModel.entries.filter { $0.dateCreated >= startOfLastMonth && $0.dateCreated < startOfMonth }
        case .thisYear:
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else {
                return viewModel.entries
            }
            return viewModel.entries.filter { $0.dateCreated >= startOfYear }
        case .custom:
            let startOfDay = calendar.startOfDay(for: customStartDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate)) else {
                return viewModel.entries.filter { $0.dateCreated >= startOfDay }
            }
            return viewModel.entries.filter { $0.dateCreated >= startOfDay && $0.dateCreated < endOfDay }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preview card
                        previewCard
                        
                        // Format selection
                        formatSelection
                        
                        // Date range selection
                        dateRangeSelection
                        
                        // Include options
                        includeOptionsSection
                        
                        // Export button
                        exportButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Export Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                } else {
                    ShareSheet(items: [exportedContent])
                }
            }
            .overlay {
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Exporting...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // MARK: - Preview Card
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.viewfinder")
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
                
                Text("Export Preview")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(filteredEntries.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                    Text("Entries")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("\(totalWordCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                    Text("Words")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text(selectedFormat.rawValue)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                    Text("Format")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            
            if let dateRange = dateRangeText {
                Text(dateRange)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(16)
    }
    
    // MARK: - Format Selection
    
    private var formatSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 12) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: format.icon)
                                .font(.title2)
                            Text(format.rawValue)
                                .font(.caption)
                        }
                        .foregroundColor(selectedFormat == format ? .white : themeManager.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedFormat == format ? themeManager.accentColor : themeManager.cardBackgroundColor)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Date Range Selection
    
    private var dateRangeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date Range")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: 8) {
                ForEach(DateRangeOption.allCases, id: \.self) { option in
                    Button {
                        selectedDateRange = option
                    } label: {
                        HStack {
                            Image(systemName: option.icon)
                                .frame(width: 24)
                            
                            Text(option.rawValue)
                            
                            Spacer()
                            
                            if selectedDateRange == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Custom date pickers
            if selectedDateRange == .custom {
                VStack(spacing: 12) {
                    DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        .foregroundColor(themeManager.textColor)
                    
                    DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                        .foregroundColor(themeManager.textColor)
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Include Options
    
    private var includeOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Include")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            VStack(spacing: 0) {
                toggleRow(title: "Moods", icon: "face.smiling", isOn: $includeMoods)
                Divider().padding(.leading, 44)
                toggleRow(title: "Tags", icon: "tag", isOn: $includeTags)
                Divider().padding(.leading, 44)
                toggleRow(title: "Linked Verses", icon: "book", isOn: $includeLinkedVerses)
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }
    
    private func toggleRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(themeManager.textColor)
            }
        }
        .tint(themeManager.accentColor)
        .padding()
    }
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Button {
            performExport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Export \(filteredEntries.count) Entries")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(filteredEntries.isEmpty ? Color.gray : themeManager.accentColor)
            )
        }
        .disabled(filteredEntries.isEmpty)
    }
    
    // MARK: - Helpers
    
    private var totalWordCount: Int {
        filteredEntries.reduce(0) { $0 + $1.wordCount }
    }
    
    private var dateRangeText: String? {
        guard !filteredEntries.isEmpty else { return nil }
        
        let sortedEntries = filteredEntries.sorted { $0.dateCreated < $1.dateCreated }
        guard let first = sortedEntries.first, let last = sortedEntries.last else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return "\(formatter.string(from: first.dateCreated)) – \(formatter.string(from: last.dateCreated))"
    }
    
    // MARK: - Export Logic
    
    private func performExport() {
        isExporting = true
        
        Task {
            switch selectedFormat {
            case .text:
                exportedContent = generateTextExport()
                exportedURL = nil
            case .markdown:
                exportedContent = generateMarkdownExport()
                exportedURL = saveToFile(content: exportedContent, extension: "md")
            case .pdf:
                exportedURL = generatePDFExport()
            }
            
            await MainActor.run {
                isExporting = false
                showingShareSheet = true
            }
        }
    }
    
    private func generateTextExport() -> String {
        var export = "My Spiritual Journal\n"
        export += "Exported: \(Date().formatted())\n"
        export += String(repeating: "=", count: 50) + "\n\n"
        
        let sortedEntries = filteredEntries.sorted { $0.dateCreated > $1.dateCreated }
        
        for entry in sortedEntries {
            export += "Date: \(entry.formattedDate) at \(entry.timeOfDay)\n"
            
            if !entry.title.isEmpty {
                export += "Title: \(entry.title)\n"
            }
            
            if includeMoods, let mood = entry.mood {
                export += "Mood: \(mood.displayName) \(mood.emoji)\n"
            }
            
            if includeTags, !entry.tags.isEmpty {
                export += "Tags: \(entry.tags.map { $0.name }.joined(separator: ", "))\n"
            }
            
            export += "\n\(entry.content)\n"
            
            if includeLinkedVerses, !entry.linkedVerses.isEmpty {
                export += "\nLinked Verses:\n"
                for verse in entry.linkedVerses {
                    export += "  • \(verse.fullReference)\n"
                    export += "    \"\(verse.text)\"\n"
                }
            }
            
            export += "\n" + String(repeating: "-", count: 50) + "\n\n"
        }
        
        export += "\nTotal Entries: \(filteredEntries.count)\n"
        export += "Total Words: \(totalWordCount)\n"
        
        return export
    }
    
    private func generateMarkdownExport() -> String {
        var export = "# My Spiritual Journal\n\n"
        export += "*Exported: \(Date().formatted())*\n\n"
        export += "---\n\n"
        
        let sortedEntries = filteredEntries.sorted { $0.dateCreated > $1.dateCreated }
        
        for entry in sortedEntries {
            export += "## \(entry.title.isEmpty ? entry.formattedDate : entry.title)\n\n"
            export += "**\(entry.formattedDate)** at \(entry.timeOfDay)\n\n"
            
            if includeMoods, let mood = entry.mood {
                export += "> Mood: \(mood.emoji) \(mood.displayName)\n\n"
            }
            
            if includeTags, !entry.tags.isEmpty {
                let tagList = entry.tags.map { "`\($0.name)`" }.joined(separator: " ")
                export += "Tags: \(tagList)\n\n"
            }
            
            export += "\(entry.content)\n\n"
            
            if includeLinkedVerses, !entry.linkedVerses.isEmpty {
                export += "### Linked Verses\n\n"
                for verse in entry.linkedVerses {
                    export += "> **\(verse.shortReference)**\n"
                    export += "> *\"\(verse.text)\"*\n\n"
                }
            }
            
            export += "---\n\n"
        }
        
        export += "## Summary\n\n"
        export += "- **Total Entries:** \(filteredEntries.count)\n"
        export += "- **Total Words:** \(totalWordCount)\n"
        
        return export
    }
    
    private func generatePDFExport() -> URL? {
        // Create PDF using UIKit
        let pdfMetaData = [
            kCGPDFContextCreator: "Bible v1 - Spiritual Journal",
            kCGPDFContextAuthor: "My Journal",
            kCGPDFContextTitle: "Journal Export"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 612.0
        let pageHeight = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 50
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            
            let sortedEntries = filteredEntries.sorted { $0.dateCreated > $1.dateCreated }
            var currentY: CGFloat = margin
            
            context.beginPage()
            
            // Title
            let title = "My Spiritual Journal"
            title.draw(at: CGPoint(x: margin, y: currentY), withAttributes: titleAttributes)
            currentY += 40
            
            let subtitle = "Exported: \(Date().formatted())"
            subtitle.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attributes)
            currentY += 40
            
            for entry in sortedEntries {
                // Check if we need a new page
                if currentY > pageHeight - 100 {
                    context.beginPage()
                    currentY = margin
                }
                
                // Entry header
                let header = "\(entry.formattedDate) - \(entry.title.isEmpty ? "Entry" : entry.title)"
                let headerAttr: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 14)
                ]
                header.draw(at: CGPoint(x: margin, y: currentY), withAttributes: headerAttr)
                currentY += 24
                
                // Content
                let contentRect = CGRect(x: margin, y: currentY, width: pageWidth - margin * 2, height: pageHeight - currentY - margin)
                let contentText = entry.content as NSString
                let drawnRect = contentText.boundingRect(with: contentRect.size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
                
                contentText.draw(in: CGRect(x: margin, y: currentY, width: pageWidth - margin * 2, height: drawnRect.height), withAttributes: attributes)
                currentY += drawnRect.height + 30
            }
        }
        
        return saveData(data, extension: "pdf")
    }
    
    private func saveToFile(content: String, extension ext: String) -> URL? {
        let fileName = "journal_export_\(Date().timeIntervalSince1970).\(ext)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save file: \(error)")
            return nil
        }
    }
    
    private func saveData(_ data: Data, extension ext: String) -> URL? {
        let fileName = "journal_export_\(Date().timeIntervalSince1970).\(ext)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save file: \(error)")
            return nil
        }
    }
}

#Preview {
    JournalExportSheet(viewModel: JournalViewModel())
}


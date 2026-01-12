//
//  CitationCardView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Citation Card Component
//

import SwiftUI

/// Displays a citation card with verse text and actions
struct CitationCardView: View {
    let citation: AICitation
    let mode: AIMode
    let onTap: () -> Void
    let onOpenVerse: () -> Void
    let onCopyVerse: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.caption)
                        .foregroundColor(mode.accentColor)
                    
                    Text(citation.reference)
                        .font(.subheadline.bold())
                        .foregroundColor(themeManager.textColor)
                    
                    // Verification badge
                    VerificationBadgeLabelView(status: citation.verificationStatus)
                }
                
                Spacer()
                
                Text(citation.translationId.uppercased())
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(themeManager.backgroundColor)
                    .cornerRadius(4)
            }
            
            // Verse text
            if let text = citation.text, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(isExpanded ? nil : 3)
                    .animation(.easeInOut, value: isExpanded)
                
                if text.count > 150 {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.caption)
                            .foregroundColor(mode.accentColor)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading verse...")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Actions
            HStack(spacing: 16) {
                Button {
                    onOpenVerse()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle")
                        Text("Open")
                    }
                    .font(.caption)
                    .foregroundColor(mode.accentColor)
                }
                
                Button {
                    onCopyVerse()
                    HapticManager.shared.success()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(mode.accentColor.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
}

/// Compact citation chip for inline display
struct CitationChipView: View {
    let citation: AICitation
    let mode: AIMode
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.caption2)
                Text(citation.reference)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(mode.accentColor.opacity(0.1))
            .foregroundColor(mode.accentColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

/// Grid of citation chips
struct CitationsGridView: View {
    let citations: [AICitation]
    let mode: AIMode
    let onCitationTap: (AICitation) -> Void
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(citations) { citation in
                CitationChipView(citation: citation, mode: mode) {
                    onCitationTap(citation)
                }
            }
        }
    }
}

// Note: FlowLayout is defined in PrayerLibraryView.swift and reused here

// MARK: - Citation Preview Sheet

struct CitationPreviewSheet: View {
    let citation: AICitation
    let mode: AIMode
    let onOpenVerse: () -> Void
    let onCopyVerse: () -> Void
    let onSaveToJournal: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Reference header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(citation.reference)
                            .font(.title2.bold())
                            .foregroundColor(themeManager.textColor)
                        
                        Text(citation.translationId.uppercased())
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(4)
                    }
                    
                    Divider()
                    
                    // Verse text
                    if let text = citation.text {
                        Text(text)
                            .font(.title3)
                            .foregroundColor(themeManager.textColor)
                            .lineSpacing(8)
                    } else {
                        Text("Verse text not available")
                            .font(.body)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .italic()
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            onOpenVerse()
                            dismiss()
                        } label: {
                            Label("Open in Bible Reader", systemImage: "book.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(mode.accentColor)
                                .cornerRadius(12)
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                onCopyVerse()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                onSaveToJournal()
                                dismiss()
                            } label: {
                                Label("Journal", systemImage: "square.and.pencil")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(themeManager.cardBackgroundColor)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Verse Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#Preview("Citation Card") {
    CitationCardView(
        citation: AICitation(
            reference: "John 3:16",
            translationId: "engKJV",
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."
        ),
        mode: .study,
        onTap: {},
        onOpenVerse: {},
        onCopyVerse: {}
    )
    .padding()
}

#Preview("Citation Chip") {
    CitationChipView(
        citation: AICitation(reference: "John 3:16", translationId: "engKJV"),
        mode: .devotional,
        onTap: {}
    )
}


//
//  PrayerJournalView.swift
//  Bible v1
//
//  Prayer Journal - List and manage prayer entries
//

import SwiftUI

struct PrayerJournalView: View {
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: PrayerFilter = .all
    @State private var showAddPrayer = false
    @State private var selectedPrayer: PrayerEntry?
    @State private var showAnsweredSheet = false
    @State private var prayerToMarkAnswered: PrayerEntry?
    
    enum PrayerFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case answered = "Answered"
    }
    
    private var filteredPrayers: [PrayerEntry] {
        switch selectedFilter {
        case .all:
            return viewModel.prayerEntries
        case .active:
            return viewModel.unansweredPrayers
        case .answered:
            return viewModel.answeredPrayers
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(PrayerFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    if filteredPrayers.isEmpty {
                        emptyState
                    } else {
                        prayerList
                    }
                }
            }
            .navigationTitle("Prayer Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddPrayer = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddPrayer) {
                PrayerEntryEditorView(viewModel: viewModel, prayer: nil)
            }
            .sheet(item: $selectedPrayer) { prayer in
                PrayerEntryEditorView(viewModel: viewModel, prayer: prayer)
            }
            .sheet(item: $prayerToMarkAnswered) { prayer in
                MarkAnsweredSheet(prayer: prayer, viewModel: viewModel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "hands.sparkles")
                .font(.system(size: 60))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text(selectedFilter == .all ? "No Prayers Yet" : "No \(selectedFilter.rawValue) Prayers")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            Text("Start your prayer journal by adding your first prayer request.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showAddPrayer = true
            } label: {
                Label("Add Prayer", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(themeManager.accentColor)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
    }
    
    private var prayerList: some View {
        List {
            ForEach(filteredPrayers) { prayer in
                PrayerEntryRow(prayer: prayer)
                    .listRowBackground(themeManager.cardBackgroundColor)
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedPrayer = prayer
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deletePrayer(prayer)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        if !prayer.isAnswered {
                            Button {
                                prayerToMarkAnswered = prayer
                            } label: {
                                Label("Answered", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Prayer Entry Row

struct PrayerEntryRow: View {
    let prayer: PrayerEntry
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Category icon
                Image(systemName: prayer.category.icon)
                    .font(.caption)
                    .foregroundColor(categoryColor)
                    .padding(6)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(prayer.title)
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(prayer.category.rawValue)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if prayer.isAnswered {
                    Label("Answered", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            
            // Content preview
            Text(prayer.content)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(2)
            
            // Linked verse if present
            if let verseRef = prayer.linkedVerseReference {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.caption2)
                    Text(verseRef)
                        .font(.caption)
                }
                .foregroundColor(themeManager.accentColor)
            }
            
            // Footer
            HStack {
                Text(prayer.dateCreated, style: .date)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                if prayer.daysSinceCreated > 0 {
                    Text("•")
                        .foregroundColor(themeManager.secondaryTextColor)
                    Text("\(prayer.daysSinceCreated) day\(prayer.daysSinceCreated == 1 ? "" : "s") ago")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if prayer.isAnswered, let answeredDate = prayer.answeredDate {
                    Text("Answered \(answeredDate, style: .date)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
    
    private var categoryColor: Color {
        switch prayer.category {
        case .gratitude: return .pink
        case .repentance: return .teal
        case .guidance: return .blue
        case .anxiety: return .teal
        case .family: return .orange
        case .work: return .brown
        case .health: return .green
        case .relationships: return .red
        case .other: return .gray
        }
    }
}

// MARK: - Mark Answered Sheet

struct MarkAnsweredSheet: View {
    let prayer: PrayerEntry
    @ObservedObject var viewModel: HubViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var note: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Celebration icon
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .padding(.top, 20)
                    
                    Text("Prayer Answered!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("God is faithful! Would you like to add a note about how this prayer was answered?")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Prayer title
                    Text("\"\(prayer.title)\"")
                        .font(.headline)
                        .foregroundColor(themeManager.accentColor)
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                    
                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How was it answered? (optional)")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextEditor(text: $note)
                            .frame(height: 100)
                            .padding(8)
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(10)
                            .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Confirm button
                    Button {
                        viewModel.markPrayerAnswered(prayer, note: note.isEmpty ? nil : note)
                        dismiss()
                    } label: {
                        Text("Mark as Answered")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Answered Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PrayerJournalView(viewModel: HubViewModel())
}




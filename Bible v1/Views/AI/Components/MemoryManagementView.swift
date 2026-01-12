//
//  MemoryManagementView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Memory Management UI
//

import SwiftUI

/// View for managing AI memories
struct MemoryManagementView: View {
    @ObservedObject private var memoryService = AIMemoryService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchQuery: String = ""
    @State private var selectedType: MemoryType? = nil
    @State private var showingDeleteAllConfirmation: Bool = false
    @State private var memoryToDelete: AIMemory? = nil
    @State private var showingAddMemory: Bool = false
    
    var body: some View {
        NavigationStack {
            Group {
                if memoryService.activeMemories.isEmpty {
                    emptyStateView
                } else {
                    memoriesListView
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("AI Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddMemory = true
                        } label: {
                            Label("Add Memory", systemImage: "plus")
                        }
                        
                        if !memoryService.activeMemories.isEmpty {
                            Divider()
                            
                            Button(role: .destructive) {
                                showingDeleteAllConfirmation = true
                            } label: {
                                Label("Delete All", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search memories...")
            .alert("Delete All Memories?", isPresented: $showingDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    memoryService.deleteAllMemories()
                    HapticManager.shared.success()
                }
            } message: {
                Text("This will permanently delete all \(memoryService.activeMemories.count) memories. This cannot be undone.")
            }
            .alert("Delete Memory?", isPresented: .init(
                get: { memoryToDelete != nil },
                set: { if !$0 { memoryToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    memoryToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let memory = memoryToDelete {
                        memoryService.deleteMemory(memory.id)
                        memoryToDelete = nil
                    }
                }
            } message: {
                Text("This memory will be permanently deleted.")
            }
            .sheet(isPresented: $showingAddMemory) {
                AddMemorySheet()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 50))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("No Memories Yet")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("TRC AI can remember your prayer requests, favorite verses, and what's helped you before.")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingAddMemory = true
            } label: {
                Label("Add a Memory", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(themeManager.accentColor)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var memoriesListView: some View {
        List {
            // Type filter
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        MemoryFilterChip(
                            title: "All",
                            isSelected: selectedType == nil,
                            action: { selectedType = nil }
                        )
                        
                        ForEach(MemoryType.allCases) { type in
                            let count = memoryService.memories(ofType: type).count
                            if count > 0 {
                                MemoryFilterChip(
                                    title: "\(type.displayName) (\(count))",
                                    isSelected: selectedType == type,
                                    color: type.color,
                                    action: { selectedType = type }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            // Memories
            ForEach(filteredMemories) { memory in
                MemoryRowView(
                    memory: memory,
                    onDelete: { memoryToDelete = memory },
                    onToggleActive: {
                        if memory.isActive {
                            memoryService.deactivateMemory(memory.id)
                        } else {
                            memoryService.reactivateMemory(memory.id)
                        }
                    }
                )
                .listRowBackground(themeManager.cardBackgroundColor)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(themeManager.backgroundColor)
        .tint(themeManager.accentColor)
    }
    
    // MARK: - Computed Properties
    
    private var filteredMemories: [AIMemory] {
        var memories = memoryService.activeMemories
        
        // Filter by type
        if let type = selectedType {
            memories = memories.filter { $0.type == type }
        }
        
        // Filter by search query
        if !searchQuery.isEmpty {
            memories = memoryService.searchMemories(query: searchQuery)
        }
        
        return memories
    }
}

// MARK: - Memory Filter Chip

struct MemoryFilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : themeManager.cardBackgroundColor)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Memory Row View

struct MemoryRowView: View {
    let memory: AIMemory
    let onDelete: () -> Void
    let onToggleActive: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Type icon
                Image(systemName: memory.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(memory.type.color)
                    .frame(width: 28, height: 28)
                    .background(memory.type.color.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(memory.type.displayName)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(isExpanded ? memory.content : memory.previewContent)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                }
                
                Spacer()
            }
            
            // Related verses
            if !memory.relatedVerses.isEmpty {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.caption2)
                    Text(memory.relatedVerses.joined(separator: ", "))
                        .font(.caption)
                }
                .foregroundColor(themeManager.accentColor)
            }
            
            // Footer
            HStack {
                Text(memory.ageDescription)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                if memory.content.count > 100 {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.caption2)
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onToggleActive) {
                Label(
                    memory.isActive ? "Disable" : "Enable",
                    systemImage: memory.isActive ? "pause.circle" : "play.circle"
                )
            }
            .tint(memory.isActive ? .orange : .green)
        }
    }
}

// MARK: - Add Memory Sheet

struct AddMemorySheet: View {
    @ObservedObject private var memoryService = AIMemoryService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: MemoryType = .prayerRequest
    @State private var content: String = ""
    @State private var relatedVerses: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $selectedType) {
                        ForEach(MemoryType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }
                
                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                } header: {
                    Text("Content")
                } footer: {
                    Text(selectedType.description)
                }
                
                Section {
                    TextField("e.g., John 3:16, Psalm 23", text: $relatedVerses)
                } header: {
                    Text("Related Verses (optional)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.backgroundColor)
            .tint(themeManager.accentColor)
            .navigationTitle("Add Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMemory()
                    }
                    .foregroundColor(themeManager.accentColor)
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveMemory() {
        let verses = relatedVerses
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        memoryService.addMemory(
            type: selectedType,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            relatedVerses: verses
        )
        
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    MemoryManagementView()
}


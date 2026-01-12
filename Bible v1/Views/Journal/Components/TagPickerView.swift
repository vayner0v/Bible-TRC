//
//  TagPickerView.swift
//  Bible v1
//
//  Spiritual Journal - Tag Selection Components
//

import SwiftUI

/// Full-screen tag picker sheet
struct TagPickerSheet: View {
    @Binding var selectedTags: [JournalTag]
    let allTags: [JournalTag]
    let onAddCustomTag: (String, String, String) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddTag = false
    @State private var searchQuery = ""
    
    private var filteredTags: [JournalTag] {
        if searchQuery.isEmpty {
            return allTags
        }
        return allTags.filter { $0.name.lowercased().contains(searchQuery.lowercased()) }
    }
    
    private var defaultTags: [JournalTag] {
        filteredTags.filter { $0.isDefault }
    }
    
    private var customTags: [JournalTag] {
        filteredTags.filter { !$0.isDefault }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("Search tags", text: $searchQuery)
                            .foregroundColor(themeManager.textColor)
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                    .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Selected tags
                            if !selectedTags.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Selected")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(selectedTags) { tag in
                                            TagChip(
                                                tag: tag,
                                                isSelected: true,
                                                showRemove: true,
                                                themeManager: themeManager
                                            ) {
                                                withAnimation {
                                                    selectedTags.removeAll { $0.id == tag.id }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Default tags
                            if !defaultTags.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Categories")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(defaultTags) { tag in
                                            let isSelected = selectedTags.contains { $0.id == tag.id }
                                            TagChip(
                                                tag: tag,
                                                isSelected: isSelected,
                                                showRemove: false,
                                                themeManager: themeManager
                                            ) {
                                                withAnimation {
                                                    if isSelected {
                                                        selectedTags.removeAll { $0.id == tag.id }
                                                    } else {
                                                        selectedTags.append(tag)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Custom tags
                            if !customTags.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Custom Tags")
                                        .font(.headline)
                                        .foregroundColor(themeManager.textColor)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(customTags) { tag in
                                            let isSelected = selectedTags.contains { $0.id == tag.id }
                                            TagChip(
                                                tag: tag,
                                                isSelected: isSelected,
                                                showRemove: false,
                                                themeManager: themeManager
                                            ) {
                                                withAnimation {
                                                    if isSelected {
                                                        selectedTags.removeAll { $0.id == tag.id }
                                                    } else {
                                                        selectedTags.append(tag)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Add custom tag button
                            Button {
                                showingAddTag = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Custom Tag")
                                }
                                .font(.subheadline)
                                .foregroundColor(themeManager.accentColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddTag) {
                AddCustomTagSheet(onAdd: onAddCustomTag)
            }
        }
    }
}

/// Tag chip component
struct TagChip: View {
    let tag: JournalTag
    let isSelected: Bool
    let showRemove: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.caption)
                
                Text(tag.name)
                    .font(.subheadline)
                
                if showRemove {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : tag.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? tag.color : tag.lightColor)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Sheet for adding custom tag
struct AddCustomTagSheet: View {
    let onAdd: (String, String, String) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedColor: TagColor = .blue
    @State private var selectedIcon = "tag.fill"
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        VStack(spacing: 8) {
                            Text("Preview")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            HStack(spacing: 6) {
                                Image(systemName: selectedIcon)
                                    .font(.subheadline)
                                Text(name.isEmpty ? "Tag Name" : name)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedColor.color)
                            .cornerRadius(20)
                        }
                        .padding(.top)
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            TextField("Enter tag name", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(12)
                        }
                        
                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(TagColor.allCases) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                            .shadow(
                                                color: selectedColor == color ? color.color.opacity(0.4) : .clear,
                                                radius: 4
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Icon picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Icon")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(TagIcons.available, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundColor(
                                                selectedIcon == icon ? .white : themeManager.textColor
                                            )
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(
                                                        selectedIcon == icon ?
                                                        selectedColor.color :
                                                        themeManager.cardBackgroundColor
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, selectedColor.rawValue, selectedIcon)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview("Tag Picker Sheet") {
    TagPickerSheet(
        selectedTags: .constant([JournalTag.defaultTags[0]]),
        allTags: JournalTag.defaultTags,
        onAddCustomTag: { _, _, _ in }
    )
}

#Preview("Add Custom Tag") {
    AddCustomTagSheet(onAdd: { _, _, _ in })
}







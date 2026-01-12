//
//  WidgetFontRegistry.swift
//  Bible v1
//
//  Extended font registry for widget customization with 30+ fonts
//

import Foundation
import SwiftUI

// MARK: - Widget Font

/// Extended font definition for widget customization
struct WidgetFont: Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let category: WidgetFontCategory
    let previewText: String
    let isSystemFont: Bool
    let fontDesign: Font.Design?
    let isPremium: Bool
    
    init(
        id: String,
        name: String,
        displayName: String,
        category: WidgetFontCategory,
        previewText: String = "The quick brown fox",
        isSystemFont: Bool = false,
        fontDesign: Font.Design? = nil,
        isPremium: Bool = false
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.category = category
        self.previewText = previewText
        self.isSystemFont = isSystemFont
        self.fontDesign = fontDesign
        self.isPremium = isPremium
    }
    
    /// Create SwiftUI Font
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if isSystemFont {
            return .system(size: size, weight: weight, design: fontDesign ?? .default)
        } else {
            return .custom(name, size: size)
        }
    }
    
    /// Create UIFont for more control
    func uiFont(size: CGFloat) -> UIFont {
        if isSystemFont {
            return UIFont.systemFont(ofSize: size)
        } else {
            return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        }
    }
}

// MARK: - Font Category

enum WidgetFontCategory: String, CaseIterable, Identifiable {
    case sansSerif = "Sans-Serif"
    case serif = "Serif"
    case script = "Script"
    case display = "Display"
    case monospace = "Monospace"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sansSerif: return "textformat"
        case .serif: return "text.book.closed"
        case .script: return "pencil.and.scribble"
        case .display: return "textformat.abc.dottedunderline"
        case .monospace: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var description: String {
        switch self {
        case .sansSerif: return "Clean, modern fonts"
        case .serif: return "Classic, traditional fonts"
        case .script: return "Elegant handwritten style"
        case .display: return "Bold, decorative fonts"
        case .monospace: return "Fixed-width coding fonts"
        }
    }
}

// MARK: - Font Registry

/// Central registry of all available widget fonts
final class WidgetFontRegistry {
    static let shared = WidgetFontRegistry()
    
    private(set) var fonts: [WidgetFont] = []
    private(set) var recentlyUsed: [String] = []
    private(set) var favorites: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let recentlyUsedKey = "widget_fonts_recent"
    private let favoritesKey = "widget_fonts_favorites"
    
    private init() {
        loadUserPreferences()
        buildFontLibrary()
    }
    
    // MARK: - Public Methods
    
    /// Get font by ID
    func font(withId id: String) -> WidgetFont? {
        fonts.first { $0.id == id }
    }
    
    /// Get fonts by category
    func fonts(for category: WidgetFontCategory) -> [WidgetFont] {
        fonts.filter { $0.category == category }
    }
    
    /// Get recently used fonts
    var recentFonts: [WidgetFont] {
        recentlyUsed.compactMap { id in
            fonts.first { $0.id == id }
        }
    }
    
    /// Get favorite fonts
    var favoriteFonts: [WidgetFont] {
        favorites.compactMap { id in
            fonts.first { $0.id == id }
        }
    }
    
    /// Search fonts
    func search(query: String) -> [WidgetFont] {
        let lowercased = query.lowercased()
        return fonts.filter { font in
            font.displayName.lowercased().contains(lowercased) ||
            font.name.lowercased().contains(lowercased) ||
            font.category.rawValue.lowercased().contains(lowercased)
        }
    }
    
    /// Mark font as recently used
    func markAsUsed(_ fontId: String) {
        recentlyUsed.removeAll { $0 == fontId }
        recentlyUsed.insert(fontId, at: 0)
        if recentlyUsed.count > 10 {
            recentlyUsed = Array(recentlyUsed.prefix(10))
        }
        saveUserPreferences()
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ fontId: String) {
        if favorites.contains(fontId) {
            favorites.removeAll { $0 == fontId }
        } else {
            favorites.append(fontId)
        }
        saveUserPreferences()
    }
    
    /// Check if font is favorited
    func isFavorite(_ fontId: String) -> Bool {
        favorites.contains(fontId)
    }
    
    /// Get default font
    var defaultFont: WidgetFont {
        fonts.first { $0.id == "system" } ?? fonts[0]
    }
    
    // MARK: - Private Methods
    
    private func loadUserPreferences() {
        recentlyUsed = userDefaults.stringArray(forKey: recentlyUsedKey) ?? []
        favorites = userDefaults.stringArray(forKey: favoritesKey) ?? []
    }
    
    private func saveUserPreferences() {
        userDefaults.set(recentlyUsed, forKey: recentlyUsedKey)
        userDefaults.set(favorites, forKey: favoritesKey)
    }
    
    private func buildFontLibrary() {
        fonts = [
            // MARK: Sans-Serif Fonts
            WidgetFont(
                id: "system",
                name: "System",
                displayName: "SF Pro",
                category: .sansSerif,
                previewText: "Modern and clean",
                isSystemFont: true,
                fontDesign: .default
            ),
            WidgetFont(
                id: "system_rounded",
                name: "System Rounded",
                displayName: "SF Rounded",
                category: .sansSerif,
                previewText: "Friendly and approachable",
                isSystemFont: true,
                fontDesign: .rounded
            ),
            WidgetFont(
                id: "avenir",
                name: "Avenir",
                displayName: "Avenir",
                category: .sansSerif,
                previewText: "Elegant geometric"
            ),
            WidgetFont(
                id: "avenir_next",
                name: "Avenir Next",
                displayName: "Avenir Next",
                category: .sansSerif,
                previewText: "Modern refinement"
            ),
            WidgetFont(
                id: "helvetica_neue",
                name: "Helvetica Neue",
                displayName: "Helvetica Neue",
                category: .sansSerif,
                previewText: "Swiss precision"
            ),
            WidgetFont(
                id: "gill_sans",
                name: "Gill Sans",
                displayName: "Gill Sans",
                category: .sansSerif,
                previewText: "British humanist"
            ),
            WidgetFont(
                id: "futura",
                name: "Futura",
                displayName: "Futura",
                category: .sansSerif,
                previewText: "Bold geometric"
            ),
            WidgetFont(
                id: "optima",
                name: "Optima",
                displayName: "Optima",
                category: .sansSerif,
                previewText: "Humanist elegance"
            ),
            WidgetFont(
                id: "verdana",
                name: "Verdana",
                displayName: "Verdana",
                category: .sansSerif,
                previewText: "Screen optimized"
            ),
            WidgetFont(
                id: "trebuchet_ms",
                name: "Trebuchet MS",
                displayName: "Trebuchet MS",
                category: .sansSerif,
                previewText: "Friendly sans"
            ),
            
            // MARK: Serif Fonts
            WidgetFont(
                id: "system_serif",
                name: "System Serif",
                displayName: "New York",
                category: .serif,
                previewText: "Apple's modern serif",
                isSystemFont: true,
                fontDesign: .serif
            ),
            WidgetFont(
                id: "georgia",
                name: "Georgia",
                displayName: "Georgia",
                category: .serif,
                previewText: "Classic readability"
            ),
            WidgetFont(
                id: "palatino",
                name: "Palatino",
                displayName: "Palatino",
                category: .serif,
                previewText: "Renaissance elegance"
            ),
            WidgetFont(
                id: "times_new_roman",
                name: "Times New Roman",
                displayName: "Times New Roman",
                category: .serif,
                previewText: "Traditional authority"
            ),
            WidgetFont(
                id: "baskerville",
                name: "Baskerville",
                displayName: "Baskerville",
                category: .serif,
                previewText: "Transitional classic"
            ),
            WidgetFont(
                id: "garamond",
                name: "Apple Garamond",
                displayName: "Garamond",
                category: .serif,
                previewText: "Old-style elegance"
            ),
            WidgetFont(
                id: "bodoni",
                name: "Bodoni 72",
                displayName: "Bodoni",
                category: .serif,
                previewText: "High contrast beauty"
            ),
            WidgetFont(
                id: "didot",
                name: "Didot",
                displayName: "Didot",
                category: .serif,
                previewText: "Fashion editorial"
            ),
            WidgetFont(
                id: "hoefler",
                name: "Hoefler Text",
                displayName: "Hoefler Text",
                category: .serif,
                previewText: "American classic"
            ),
            WidgetFont(
                id: "charter",
                name: "Charter",
                displayName: "Charter",
                category: .serif,
                previewText: "Exceptional clarity"
            ),
            WidgetFont(
                id: "cochin",
                name: "Cochin",
                displayName: "Cochin",
                category: .serif,
                previewText: "French charm"
            ),
            
            // MARK: Script Fonts
            WidgetFont(
                id: "snell_roundhand",
                name: "Snell Roundhand",
                displayName: "Snell Roundhand",
                category: .script,
                previewText: "Elegant calligraphy",
                isPremium: true
            ),
            WidgetFont(
                id: "bradley_hand",
                name: "Bradley Hand",
                displayName: "Bradley Hand",
                category: .script,
                previewText: "Casual handwritten"
            ),
            WidgetFont(
                id: "zapfino",
                name: "Zapfino",
                displayName: "Zapfino",
                category: .script,
                previewText: "Flowing artistry",
                isPremium: true
            ),
            WidgetFont(
                id: "noteworthy",
                name: "Noteworthy",
                displayName: "Noteworthy",
                category: .script,
                previewText: "Friendly notes"
            ),
            WidgetFont(
                id: "marker_felt",
                name: "Marker Felt",
                displayName: "Marker Felt",
                category: .script,
                previewText: "Casual marker"
            ),
            WidgetFont(
                id: "chalkboard_se",
                name: "Chalkboard SE",
                displayName: "Chalkboard",
                category: .script,
                previewText: "Playful chalk"
            ),
            
            // MARK: Display Fonts
            WidgetFont(
                id: "impact",
                name: "Impact",
                displayName: "Impact",
                category: .display,
                previewText: "Bold headlines"
            ),
            WidgetFont(
                id: "copperplate",
                name: "Copperplate",
                displayName: "Copperplate",
                category: .display,
                previewText: "Engraved elegance"
            ),
            WidgetFont(
                id: "papyrus",
                name: "Papyrus",
                displayName: "Papyrus",
                category: .display,
                previewText: "Ancient style"
            ),
            WidgetFont(
                id: "american_typewriter",
                name: "American Typewriter",
                displayName: "American Typewriter",
                category: .display,
                previewText: "Vintage charm"
            ),
            WidgetFont(
                id: "rockwell",
                name: "Rockwell",
                displayName: "Rockwell",
                category: .display,
                previewText: "Slab serif power"
            ),
            
            // MARK: Monospace Fonts
            WidgetFont(
                id: "system_mono",
                name: "System Monospace",
                displayName: "SF Mono",
                category: .monospace,
                previewText: "Code clarity",
                isSystemFont: true,
                fontDesign: .monospaced
            ),
            WidgetFont(
                id: "menlo",
                name: "Menlo",
                displayName: "Menlo",
                category: .monospace,
                previewText: "Developer favorite"
            ),
            WidgetFont(
                id: "courier_new",
                name: "Courier New",
                displayName: "Courier New",
                category: .monospace,
                previewText: "Typewriter classic"
            ),
            WidgetFont(
                id: "monaco",
                name: "Monaco",
                displayName: "Monaco",
                category: .monospace,
                previewText: "Terminal style"
            )
        ]
    }
}

// MARK: - Font Picker View

/// Font picker component for widget designer
struct WidgetFontPicker: View {
    @Binding var selectedFontId: String
    let onSelect: (WidgetFont) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: WidgetFontCategory?
    
    @ObservedObject private var themeManager = ThemeManager.shared
    private let registry = WidgetFontRegistry.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
            
            // Category filter
            categoryFilter
            
            // Font list
            fontList
        }
        .background(themeManager.backgroundColor)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search fonts...", text: $searchText)
                .foregroundColor(themeManager.textColor)
        }
        .padding(12)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                CategoryChip(
                    title: "All",
                    icon: "textformat",
                    isSelected: selectedCategory == nil,
                    onTap: {
                        selectedCategory = nil
                        HapticManager.shared.lightImpact()
                    }
                )
                
                ForEach(WidgetFontCategory.allCases) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        onTap: {
                            selectedCategory = category
                            HapticManager.shared.lightImpact()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var fontList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Recently used section
                if !searchText.isEmpty == false && registry.recentFonts.count > 0 {
                    fontSection(title: "Recently Used", fonts: registry.recentFonts)
                }
                
                // Favorites section
                if !searchText.isEmpty == false && registry.favoriteFonts.count > 0 {
                    fontSection(title: "Favorites", fonts: registry.favoriteFonts)
                }
                
                // Main font list
                ForEach(filteredFonts) { font in
                    FontRow(
                        font: font,
                        isSelected: selectedFontId == font.id,
                        isFavorite: registry.isFavorite(font.id),
                        onSelect: {
                            selectedFontId = font.id
                            registry.markAsUsed(font.id)
                            onSelect(font)
                            HapticManager.shared.lightImpact()
                        },
                        onToggleFavorite: {
                            registry.toggleFavorite(font.id)
                            HapticManager.shared.lightImpact()
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func fontSection(title: String, fonts: [WidgetFont]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            ForEach(fonts) { font in
                FontRow(
                    font: font,
                    isSelected: selectedFontId == font.id,
                    isFavorite: registry.isFavorite(font.id),
                    onSelect: {
                        selectedFontId = font.id
                        registry.markAsUsed(font.id)
                        onSelect(font)
                    },
                    onToggleFavorite: {
                        registry.toggleFavorite(font.id)
                    }
                )
            }
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }
    
    private var filteredFonts: [WidgetFont] {
        var result = registry.fonts
        
        // Apply category filter
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = registry.search(query: searchText)
        }
        
        return result
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
            )
        }
    }
}

struct FontRow: View {
    let font: WidgetFont
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Font preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.displayName)
                        .font(font.font(size: 16, weight: .medium))
                        .foregroundColor(themeManager.textColor)
                    
                    Text(font.previewText)
                        .font(font.font(size: 12))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Category badge
                Text(font.category.rawValue)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(4)
                
                // Premium badge
                if font.isPremium {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                // Favorite button
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundColor(isFavorite ? .red : themeManager.secondaryTextColor)
                }
                .buttonStyle(.plain)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? themeManager.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WidgetFontPicker(
            selectedFontId: .constant("georgia"),
            onSelect: { _ in }
        )
        .navigationTitle("Choose Font")
    }
}





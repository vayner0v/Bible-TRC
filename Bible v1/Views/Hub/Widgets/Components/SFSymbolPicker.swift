//
//  SFSymbolPicker.swift
//  Bible v1
//
//  SF Symbols picker with search and categories
//

import SwiftUI

/// SF Symbol picker with search and category browsing
struct SFSymbolPicker: View {
    let onSelect: (String) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: SymbolCategory = .all
    @State private var recentSymbols: [String] = []
    
    private let columns = [
        GridItem(.adaptive(minimum: 50, maximum: 60), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Category filter
                categoryFilter
                
                // Symbols grid
                symbolsGrid
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Icons")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .onAppear {
                loadRecentSymbols()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search symbols...", text: $searchText)
                .foregroundColor(themeManager.textColor)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(12)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SymbolCategory.allCases) { category in
                    SymbolCategoryPill(
                        title: category.displayName,
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
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Symbols Grid
    
    private var symbolsGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Recent symbols
                if !recentSymbols.isEmpty && searchText.isEmpty && selectedCategory == .all {
                    symbolSection(title: "Recent", symbols: recentSymbols)
                }
                
                // Bible/Christian themed
                if selectedCategory == .all || selectedCategory == .religion {
                    symbolSection(title: "Faith & Religion", symbols: religiousSymbols)
                }
                
                // Main symbols grid
                symbolSection(title: selectedCategory.displayName, symbols: filteredSymbols)
            }
            .padding(16)
        }
    }
    
    private func symbolSection(title: String, symbols: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(symbols, id: \.self) { symbol in
                    SymbolButton(
                        symbolName: symbol,
                        onSelect: {
                            saveToRecent(symbol)
                            onSelect(symbol)
                            dismiss()
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Symbols Data
    
    private var filteredSymbols: [String] {
        var symbols = symbolsForCategory(selectedCategory)
        
        if !searchText.isEmpty {
            symbols = allSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        return symbols
    }
    
    private func symbolsForCategory(_ category: SymbolCategory) -> [String] {
        switch category {
        case .all:
            return allSymbols
        case .religion:
            return religiousSymbols
        case .nature:
            return natureSymbols
        case .communication:
            return communicationSymbols
        case .weather:
            return weatherSymbols
        case .objects:
            return objectSymbols
        case .shapes:
            return shapeSymbols
        case .arrows:
            return arrowSymbols
        case .devices:
            return deviceSymbols
        }
    }
    
    private var religiousSymbols: [String] {
        [
            "book.fill", "book.closed.fill", "books.vertical.fill",
            "cross.fill", "cross.case.fill",
            "heart.fill", "heart.circle.fill", "heart.text.square.fill",
            "star.fill", "star.circle.fill", "sparkles",
            "hands.sparkles", "hands.sparkles.fill",
            "sun.max.fill", "moon.fill", "moon.stars.fill",
            "leaf.fill", "flame.fill",
            "person.fill", "person.2.fill", "person.3.fill",
            "figure.stand", "figure.wave",
            "bell.fill", "bell.badge.fill",
            "quote.opening", "quote.closing",
            "bookmark.fill", "bookmark.circle.fill",
            "crown.fill", "crown",
            "globe", "globe.americas.fill",
            "gift.fill", "giftcard.fill"
        ]
    }
    
    private var natureSymbols: [String] {
        [
            "leaf.fill", "leaf.circle.fill", "leaf.arrow.triangle.circlepath",
            "tree.fill", "tree.circle.fill",
            "mountain.2.fill", "mountain.2.circle.fill",
            "water.waves", "drop.fill", "drop.circle.fill",
            "flame.fill", "flame.circle.fill",
            "sun.max.fill", "sun.min.fill", "sunrise.fill", "sunset.fill",
            "moon.fill", "moon.circle.fill", "moon.stars.fill",
            "cloud.fill", "cloud.sun.fill", "cloud.moon.fill",
            "wind", "tornado", "snowflake",
            "sparkle", "sparkles", "wand.and.stars",
            "fish.fill", "hare.fill", "tortoise.fill", "bird.fill", "ladybug.fill",
            "pawprint.fill", "ant.fill", "butterfly.fill"
        ]
    }
    
    private var communicationSymbols: [String] {
        [
            "message.fill", "bubble.left.fill", "bubble.right.fill",
            "quote.bubble.fill", "text.bubble.fill",
            "phone.fill", "phone.circle.fill",
            "envelope.fill", "envelope.circle.fill",
            "paperplane.fill", "paperplane.circle.fill",
            "megaphone.fill", "speaker.wave.3.fill",
            "bell.fill", "bell.circle.fill",
            "person.fill", "person.circle.fill",
            "person.2.fill", "person.3.fill"
        ]
    }
    
    private var weatherSymbols: [String] {
        [
            "sun.max.fill", "sun.min.fill", "sun.horizon.fill",
            "sunrise.fill", "sunset.fill",
            "moon.fill", "moon.circle.fill", "moon.stars.fill",
            "cloud.fill", "cloud.drizzle.fill", "cloud.rain.fill",
            "cloud.heavyrain.fill", "cloud.bolt.fill", "cloud.snow.fill",
            "cloud.sun.fill", "cloud.moon.fill",
            "wind", "tornado", "hurricane",
            "thermometer.sun.fill", "thermometer.snowflake",
            "umbrella.fill", "snowflake", "drop.fill"
        ]
    }
    
    private var objectSymbols: [String] {
        [
            "house.fill", "building.fill", "building.2.fill",
            "lightbulb.fill", "lamp.desk.fill",
            "book.fill", "book.closed.fill", "books.vertical.fill",
            "newspaper.fill", "doc.fill", "doc.text.fill",
            "folder.fill", "archivebox.fill",
            "tray.fill", "tray.full.fill",
            "cup.and.saucer.fill", "fork.knife",
            "gift.fill", "bag.fill", "cart.fill",
            "creditcard.fill", "wallet.pass.fill",
            "key.fill", "lock.fill", "lock.open.fill"
        ]
    }
    
    private var shapeSymbols: [String] {
        [
            "circle.fill", "square.fill", "triangle.fill",
            "diamond.fill", "pentagon.fill", "hexagon.fill",
            "octagon.fill", "seal.fill",
            "rectangle.fill", "capsule.fill",
            "star.fill", "star.circle.fill",
            "heart.fill", "heart.circle.fill",
            "cross.fill", "plus", "minus",
            "checkmark", "checkmark.circle.fill",
            "xmark", "xmark.circle.fill"
        ]
    }
    
    private var arrowSymbols: [String] {
        [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.up.circle.fill", "arrow.down.circle.fill",
            "arrow.left.circle.fill", "arrow.right.circle.fill",
            "arrow.up.arrow.down", "arrow.left.arrow.right",
            "arrow.clockwise", "arrow.counterclockwise",
            "arrow.triangle.2.circlepath",
            "chevron.up", "chevron.down", "chevron.left", "chevron.right",
            "chevron.up.circle.fill", "chevron.down.circle.fill"
        ]
    }
    
    private var deviceSymbols: [String] {
        [
            "iphone", "ipad", "laptopcomputer", "desktopcomputer",
            "applewatch", "airpods", "airpodspro",
            "tv.fill", "display", "keyboard.fill",
            "printer.fill", "scanner.fill",
            "camera.fill", "video.fill",
            "mic.fill", "speaker.fill", "headphones"
        ]
    }
    
    private var allSymbols: [String] {
        religiousSymbols + natureSymbols + communicationSymbols +
        weatherSymbols + objectSymbols + shapeSymbols + arrowSymbols + deviceSymbols
    }
    
    // MARK: - Recent Symbols
    
    private func loadRecentSymbols() {
        recentSymbols = UserDefaults.standard.stringArray(forKey: "recent_sf_symbols") ?? []
    }
    
    private func saveToRecent(_ symbol: String) {
        var recent = recentSymbols
        recent.removeAll { $0 == symbol }
        recent.insert(symbol, at: 0)
        recent = Array(recent.prefix(12))
        recentSymbols = recent
        UserDefaults.standard.set(recent, forKey: "recent_sf_symbols")
    }
}

// MARK: - Symbol Category

enum SymbolCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case religion = "Faith"
    case nature = "Nature"
    case communication = "Communication"
    case weather = "Weather"
    case objects = "Objects"
    case shapes = "Shapes"
    case arrows = "Arrows"
    case devices = "Devices"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

// MARK: - Supporting Views

struct SymbolCategoryPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.accentColor : themeManager.backgroundColor)
                )
        }
    }
}

struct SymbolButton: View {
    let symbolName: String
    let onSelect: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            Image(systemName: symbolName)
                .font(.system(size: 22))
                .foregroundColor(themeManager.textColor)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.cardBackgroundColor)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = pressing
            }
        }) {
            onSelect()
        }
    }
}

// MARK: - Preview

#Preview {
    SFSymbolPicker { symbol in
        print("Selected: \(symbol)")
    }
}


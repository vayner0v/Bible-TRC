//
//  TemplateGalleryView.swift
//  Bible v1
//
//  Curated template gallery for widget designs
//

import SwiftUI

/// Gallery of curated widget templates
struct TemplateGalleryView: View {
    let widgetType: BibleWidgetType
    @Binding var selectedSize: WidgetSize
    let onSelectTemplate: (WidgetTemplate) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: TemplateCategory? = nil
    @State private var searchText = ""
    @State private var hasAppeared = false
    
    private let library = WidgetTemplateLibrary.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Size selector
                    sizeSelector
                    
                    // Search bar
                    searchBar
                    
                    // Category tabs
                    categoryTabs
                    
                    // Featured section (if no category selected)
                    if selectedCategory == nil && searchText.isEmpty {
                        featuredSection
                    }
                    
                    // Recent templates
                    if !library.recentTemplates.isEmpty && selectedCategory == nil && searchText.isEmpty {
                        recentSection
                    }
                    
                    // Templates grid
                    templatesGrid
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .padding(.bottom, 40)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Size Selector
    
    private var sizeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Widget Size")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 10) {
                ForEach(widgetType.supportedSizes) { size in
                    SizePill(
                        size: size,
                        isSelected: selectedSize == size,
                        onTap: {
                            selectedSize = size
                            HapticManager.shared.lightImpact()
                        }
                    )
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search templates...", text: $searchText)
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
        .cornerRadius(12)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All button
                TemplateCategoryTab(
                    category: nil,
                    isSelected: selectedCategory == nil,
                    onTap: {
                        selectedCategory = nil
                        HapticManager.shared.lightImpact()
                    }
                )
                
                ForEach(TemplateCategory.allCases) { category in
                    TemplateCategoryTab(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            selectedCategory = category
                            HapticManager.shared.lightImpact()
                        }
                    )
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Featured Section
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Featured")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(library.featuredTemplates.prefix(5)) { template in
                        FeaturedTemplateCard(
                            template: template,
                            onTap: {
                                library.markAsUsed(template.id)
                                onSelectTemplate(template)
                                HapticManager.shared.mediumImpact()
                            }
                        )
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Recent Section
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Recently Used")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(library.recentTemplates) { template in
                        SmallTemplateCard(
                            template: template,
                            onTap: {
                                library.markAsUsed(template.id)
                                onSelectTemplate(template)
                            }
                        )
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Templates Grid
    
    private var templatesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(gridTitle)
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            if filteredTemplates.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(filteredTemplates.enumerated()), id: \.element.id) { index, template in
                        TemplateGridCard(
                            template: template,
                            isFavorite: library.isFavorite(template.id),
                            onTap: {
                                library.markAsUsed(template.id)
                                onSelectTemplate(template)
                                HapticManager.shared.mediumImpact()
                            },
                            onToggleFavorite: {
                                library.toggleFavorite(template.id)
                                HapticManager.shared.lightImpact()
                            }
                        )
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: hasAppeared)
                    }
                }
            }
        }
    }
    
    private var gridTitle: String {
        if !searchText.isEmpty {
            return "Search Results"
        } else if let category = selectedCategory {
            return category.rawValue
        } else {
            return "All Templates"
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 48))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("No templates found")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Text("Try a different search or category")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Filtered Templates
    
    private var filteredTemplates: [WidgetTemplate] {
        var templates = library.templates
        
        // Filter by category
        if let category = selectedCategory {
            templates = library.templates(for: category)
        }
        
        // Filter by search
        if !searchText.isEmpty {
            templates = library.search(query: searchText)
        }
        
        // Filter by widget type compatibility
        templates = templates.filter { $0.supportedWidgetTypes.contains(widgetType) }
        
        return templates
    }
}

// MARK: - Supporting Views

struct SizePill: View {
    let size: WidgetSize
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                sizeIcon
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
                
                Text(size.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
            )
        }
    }
    
    @ViewBuilder
    private var sizeIcon: some View {
        switch size {
        case .small:
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 12, height: 12)
        case .medium:
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 20, height: 10)
        case .large:
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 16, height: 16)
        }
    }
}

struct TemplateCategoryTab: View {
    let category: TemplateCategory?
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category?.icon ?? "square.grid.2x2")
                    .font(.caption)
                
                Text(category?.rawValue ?? "All")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : themeManager.textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
            )
        }
    }
}

struct FeaturedTemplateCard: View {
    let template: WidgetTemplate
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: template.previewColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 100)
                    .overlay(
                        VStack {
                            Image(systemName: "textformat")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(template.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                    )
                    .scaleEffect(isHovered ? 1.02 : 1)
                    .shadow(color: template.previewColors.first?.opacity(0.3) ?? .clear, radius: isHovered ? 12 : 8, y: isHovered ? 6 : 4)
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(TilePressStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}

struct SmallTemplateCard: View {
    let template: WidgetTemplate
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: template.previewColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 50)
                
                Text(template.name)
                    .font(.caption2)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
            }
        }
        .buttonStyle(TilePressStyle())
    }
}

struct TemplateGridCard: View {
    let template: WidgetTemplate
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Preview
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: template.previewColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: "textformat")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                        )
                    
                    // Favorite button
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(isFavorite ? .red : .white.opacity(0.8))
                            .padding(8)
                            .background(Circle().fill(themeManager.cardBackgroundColor.opacity(0.6)))
                    }
                    .padding(8)
                    
                    // Premium badge
                    if template.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(6)
                            .background(Circle().fill(Color.white))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(template.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        if !template.tags.isEmpty {
                            Text("•")
                                .foregroundColor(themeManager.secondaryTextColor)
                            Text(template.tags.first ?? "")
                                .font(.caption2)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.hubShadowColor, radius: 6, y: 3)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Preview

#Preview {
    TemplateGalleryView(
        widgetType: .verseOfDay,
        selectedSize: .constant(.medium),
        onSelectTemplate: { _ in }
    )
}


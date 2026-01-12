//
//  ElementPickerSheet.swift
//  Bible v1
//
//  Sheet for selecting elements to add to widget layers
//

import SwiftUI

/// Sheet for selecting elements to add to widget
struct ElementPickerSheet: View {
    let onAddElement: (LayerElement) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: ElementCategory = .text
    @State private var showingIconPicker = false
    @State private var showingPhotoPicker = false
    
    private enum ElementCategory: String, CaseIterable {
        case text = "Text"
        case data = "Data"
        case icon = "Icon"
        case shape = "Shape"
        case image = "Image"
        
        var icon: String {
            switch self {
            case .text: return "textformat"
            case .data: return "link"
            case .icon: return "star.fill"
            case .shape: return "square.on.circle"
            case .image: return "photo"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs
                categoryTabs
                
                // Content
                ScrollView {
                    switch selectedCategory {
                    case .text:
                        textElements
                    case .data:
                        dataElements
                    case .icon:
                        iconElements
                    case .shape:
                        shapeElements
                    case .image:
                        imageElements
                    }
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Add Element")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                SFSymbolPicker { symbolName in
                    let element = LayerElement.icon(IconElementConfig(symbolName: symbolName))
                    onAddElement(element)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                WidgetPhotoPicker { photo in
                    let element = LayerElement.image(ImageElementConfig(imageId: photo.id))
                    onAddElement(element)
                }
            }
        }
    }
    
    // MARK: - Category Tabs
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ElementCategory.allCases, id: \.self) { category in
                    ElementCategoryTab(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                            HapticManager.shared.lightImpact()
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Text Elements
    
    private var textElements: some View {
        VStack(spacing: 12) {
            ElementOption(
                icon: "textformat",
                title: "Static Text",
                description: "Add custom text",
                onTap: {
                    let element = LayerElement.text(TextElementConfig(text: "Your Text"))
                    onAddElement(element)
                }
            )
            
            ElementOption(
                icon: "quote.opening",
                title: "Quote",
                description: "Large decorative quote marks",
                onTap: {
                    let element = LayerElement.text(TextElementConfig(
                        text: "\u{201C}",
                        fontId: "georgia",
                        fontSize: 48,
                        textColor: CodableColor(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.3)
                    ))
                    onAddElement(element)
                }
            )
            
            ElementOption(
                icon: "calendar",
                title: "Date Display",
                description: "Current date",
                onTap: {
                    let element = LayerElement.dataBinding(DataBindingConfig(
                        dataType: .currentDate,
                        textStyle: TextElementConfig(fontSize: 12, fontWeight: .medium)
                    ))
                    onAddElement(element)
                }
            )
        }
        .padding(16)
    }
    
    // MARK: - Data Elements
    
    private var dataElements: some View {
        VStack(spacing: 16) {
            // Scripture
            VStack(alignment: .leading, spacing: 8) {
                ElementSectionHeader(title: "Scripture", icon: "book.fill")
                
                ForEach([
                    (WidgetDataType.verseText, "Verse Text", "The actual scripture content"),
                    (WidgetDataType.verseReference, "Reference", "Book, chapter & verse"),
                    (WidgetDataType.verseBook, "Book Name", "Book of the Bible")
                ], id: \.0) { type, title, description in
                    DataElementOption(
                        dataType: type,
                        title: title,
                        description: description,
                        onTap: {
                            let element = LayerElement.dataBinding(DataBindingConfig(dataType: type))
                            onAddElement(element)
                        }
                    )
                }
            }
            
            // Reading Progress
            VStack(alignment: .leading, spacing: 8) {
                ElementSectionHeader(title: "Reading", icon: "bookmark.fill")
                
                ForEach([
                    (WidgetDataType.readingProgress, "Progress", "Reading plan completion %"),
                    (WidgetDataType.readingStreak, "Streak", "Current reading streak"),
                    (WidgetDataType.planName, "Plan Name", "Current plan title")
                ], id: \.0) { type, title, description in
                    DataElementOption(
                        dataType: type,
                        title: title,
                        description: description,
                        onTap: {
                            let element = LayerElement.dataBinding(DataBindingConfig(dataType: type))
                            onAddElement(element)
                        }
                    )
                }
            }
            
            // Habits
            VStack(alignment: .leading, spacing: 8) {
                ElementSectionHeader(title: "Habits", icon: "checkmark.circle.fill")
                
                ForEach([
                    (WidgetDataType.habitProgress, "Progress", "Daily habit completion"),
                    (WidgetDataType.completedHabits, "Completed", "Number completed today"),
                    (WidgetDataType.habitStreak, "Streak", "Consecutive days")
                ], id: \.0) { type, title, description in
                    DataElementOption(
                        dataType: type,
                        title: title,
                        description: description,
                        onTap: {
                            let element = LayerElement.dataBinding(DataBindingConfig(dataType: type))
                            onAddElement(element)
                        }
                    )
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Icon Elements
    
    private var iconElements: some View {
        VStack(spacing: 12) {
            ElementOption(
                icon: "star.fill",
                title: "Browse Icons",
                description: "Choose from thousands of SF Symbols",
                onTap: {
                    showingIconPicker = true
                }
            )
            
            // Quick icons
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Icons")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach([
                        "book.fill", "cross.fill", "heart.fill", "sparkles",
                        "sun.max.fill", "moon.fill", "leaf.fill", "hands.sparkles",
                        "bookmark.fill", "quote.opening"
                    ], id: \.self) { symbol in
                        QuickIconButton(symbolName: symbol) {
                            let element = LayerElement.icon(IconElementConfig(symbolName: symbol))
                            onAddElement(element)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
    }
    
    // MARK: - Shape Elements
    
    private var shapeElements: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ShapeType.allCases, id: \.self) { shapeType in
                    ShapeOption(
                        type: shapeType,
                        onTap: {
                            let element = LayerElement.shape(ShapeElementConfig(type: shapeType))
                            onAddElement(element)
                        }
                    )
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Image Elements
    
    private var imageElements: some View {
        VStack(spacing: 12) {
            ElementOption(
                icon: "photo.fill",
                title: "Choose Photo",
                description: "Add an image from your library",
                onTap: {
                    showingPhotoPicker = true
                }
            )
            
            Text("Images can be used as layer elements with custom sizing and effects.")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(16)
    }
}

// MARK: - Supporting Views

struct ElementCategoryTab: View {
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
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
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

struct ElementOption: View {
    let icon: String
    let title: String
    let description: String
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

struct DataElementOption: View {
    let dataType: WidgetDataType
    let title: String
    let description: String
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ElementSectionHeader: View {
    let title: String
    let icon: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(themeManager.accentColor)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
        }
        .padding(.top, 8)
    }
}

struct QuickIconButton: View {
    let symbolName: String
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: symbolName)
                .font(.system(size: 22))
                .foregroundColor(themeManager.textColor)
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.cardBackgroundColor)
                )
        }
        .buttonStyle(TilePressStyle())
    }
}

struct ShapeOption: View {
    let type: ShapeType
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                shapePreview
                    .foregroundColor(themeManager.accentColor.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(type.displayName)
                    .font(.caption)
                    .foregroundColor(themeManager.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(TilePressStyle())
    }
    
    @ViewBuilder
    private var shapePreview: some View {
        switch type {
        case .rectangle:
            Rectangle()
                .fill(themeManager.accentColor)
        case .circle:
            Circle()
                .fill(themeManager.accentColor)
        case .ellipse:
            Ellipse()
                .fill(themeManager.accentColor)
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.accentColor)
        case .capsule:
            Capsule()
                .fill(themeManager.accentColor)
        case .line:
            Rectangle()
                .fill(themeManager.accentColor)
                .frame(height: 3)
        case .triangle:
            Triangle()
                .fill(themeManager.accentColor)
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: 36))
        }
    }
}

// Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Preview

#Preview {
    ElementPickerSheet { element in
        print("Added: \(element)")
    }
}


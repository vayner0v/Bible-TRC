//
//  WidgetCustomDesigner.swift
//  Bible v1
//
//  Full custom widget editor with all customization options
//

import SwiftUI
import PhotosUI

/// Custom widget designer with full customization options
struct WidgetCustomDesigner: View {
    @State var config: WidgetConfig
    let onSave: (WidgetConfig) -> Void
    let onCancel: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTab: DesignerTab = .style
    @State private var showingColorPicker = false
    @State private var colorPickerTarget: ColorPickerTarget?
    @State private var tempColor: Color = .white
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    
    @Environment(\.dismiss) private var dismiss
    
    enum DesignerTab: String, CaseIterable {
        case style = "Style"
        case typography = "Typography"
        case content = "Content"
        case layout = "Layout"
        
        var icon: String {
            switch self {
            case .style: return "paintpalette.fill"
            case .typography: return "textformat"
            case .content: return "doc.text.fill"
            case .layout: return "square.grid.2x2"
            }
        }
    }
    
    enum ColorPickerTarget {
        case background
        case titleColor
        case bodyColor
        case gradientStart
        case gradientEnd
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Live preview at top
                previewSection
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Tab selector
                tabSelector
                    .padding(.top, 16)
                
                // Tab content
                ScrollView {
                    tabContent
                        .padding(16)
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Customize Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        HapticManager.shared.mediumImpact()
                        onSave(config)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerSheet(
                    color: $tempColor,
                    onSelect: { color in
                        applyColor(color)
                        showingColorPicker = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.secondaryTextColor)
            
            WidgetPreviewCard(config: config)
                .frame(maxWidth: config.size.previewSize.width)
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DesignerTab.allCases, id: \.rawValue) { tab in
                Button(action: {
                    HapticManager.shared.lightImpact()
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedTab == tab ? themeManager.accentColor : themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ?
                        themeManager.accentColor.opacity(0.12) :
                            Color.clear
                    )
                }
            }
        }
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .style:
            styleTab
        case .typography:
            typographyTab
        case .content:
            contentTab
        case .layout:
            layoutTab
        }
    }
    
    // MARK: - Style Tab
    
    private var styleTab: some View {
        VStack(spacing: 20) {
            // Background style
            DesignerSection(title: "Background") {
                VStack(spacing: 12) {
                    // Style type picker
                    Picker("Type", selection: Binding(
                        get: { backgroundStyleType },
                        set: { setBackgroundType($0) }
                    )) {
                        Text("Solid").tag(0)
                        Text("Gradient").tag(1)
                        Text("Pattern").tag(2)
                    }
                    .pickerStyle(.segmented)
                    
                    // Color options based on type
                    backgroundColorOptions
                }
            }
            
            // Shadow toggle
            DesignerSection(title: "Effects") {
                Toggle(isOn: $config.showShadow) {
                    Label("Show Shadow", systemImage: "shadow")
                        .foregroundColor(themeManager.textColor)
                }
                .tint(themeManager.accentColor)
            }
            
            // Corner style
            DesignerSection(title: "Corner Style") {
                HStack(spacing: 8) {
                    ForEach(WidgetCornerStyle.allCases, id: \.rawValue) { style in
                        CornerStyleButton(
                            style: style,
                            isSelected: config.cornerStyle == style,
                            onTap: {
                                HapticManager.shared.lightImpact()
                                config.cornerStyle = style
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var backgroundStyleType: Int {
        switch config.background {
        case .solid: return 0
        case .gradient: return 1
        case .pattern: return 2
        case .image: return 2
        }
    }
    
    private func setBackgroundType(_ type: Int) {
        switch type {
        case 0:
            config.background = .solid(color: CodableColor(color: .white))
        case 1:
            config.background = .gradient(
                colors: [
                    CodableColor(color: .blue.opacity(0.7)),
                    CodableColor(color: .purple.opacity(0.7))
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            config.background = .pattern(
                patternName: "crosses",
                baseColor: CodableColor(color: .gray.opacity(0.3))
            )
        default:
            break
        }
    }
    
    @ViewBuilder
    private var backgroundColorOptions: some View {
        switch config.background {
        case .solid(let color):
            ColorPickerRow(
                title: "Color",
                color: color.color,
                onTap: {
                    colorPickerTarget = .background
                    tempColor = color.color
                    showingColorPicker = true
                }
            )
            
        case .gradient(let colors, _, _):
            VStack(spacing: 8) {
                ColorPickerRow(
                    title: "Start Color",
                    color: colors.first?.color ?? .blue,
                    onTap: {
                        colorPickerTarget = .gradientStart
                        tempColor = colors.first?.color ?? .blue
                        showingColorPicker = true
                    }
                )
                
                ColorPickerRow(
                    title: "End Color",
                    color: colors.last?.color ?? .purple,
                    onTap: {
                        colorPickerTarget = .gradientEnd
                        tempColor = colors.last?.color ?? .purple
                        showingColorPicker = true
                    }
                )
                
                // Gradient direction picker
                gradientDirectionPicker
            }
            
        case .pattern(_, let baseColor):
            VStack(spacing: 8) {
                patternPicker
                
                ColorPickerRow(
                    title: "Base Color",
                    color: baseColor.color,
                    onTap: {
                        colorPickerTarget = .background
                        tempColor = baseColor.color
                        showingColorPicker = true
                    }
                )
            }
            
        case .image:
            Text("Image background")
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    private var gradientDirectionPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach([
                    (GradientPoint.topLeading, GradientPoint.bottomTrailing, "↘"),
                    (GradientPoint.top, GradientPoint.bottom, "↓"),
                    (GradientPoint.topTrailing, GradientPoint.bottomLeading, "↙"),
                    (GradientPoint.leading, GradientPoint.trailing, "→"),
                    (GradientPoint.center, GradientPoint.trailing, "⊙"),
                    (GradientPoint.trailing, GradientPoint.leading, "←")
                ], id: \.2) { start, end, symbol in
                    GradientDirectionButton(
                        symbol: symbol,
                        isSelected: gradientDirection == (start, end),
                        onTap: {
                            setGradientDirection(start: start, end: end)
                        }
                    )
                }
            }
        }
    }
    
    private var gradientDirection: (GradientPoint, GradientPoint)? {
        if case .gradient(_, let start, let end) = config.background {
            return (start, end)
        }
        return nil
    }
    
    private func setGradientDirection(start: GradientPoint, end: GradientPoint) {
        if case .gradient(let colors, _, _) = config.background {
            config.background = .gradient(colors: colors, startPoint: start, endPoint: end)
        }
    }
    
    private var patternPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pattern")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            HStack(spacing: 8) {
                ForEach(["crosses", "dots", "lines", "waves"], id: \.self) { pattern in
                    PatternButton(
                        pattern: pattern,
                        isSelected: currentPattern == pattern,
                        onTap: {
                            setPattern(pattern)
                        }
                    )
                }
            }
        }
    }
    
    private var currentPattern: String {
        if case .pattern(let name, _) = config.background {
            return name
        }
        return "crosses"
    }
    
    private func setPattern(_ name: String) {
        if case .pattern(_, let color) = config.background {
            config.background = .pattern(patternName: name, baseColor: color)
        }
    }
    
    // MARK: - Typography Tab
    
    private var typographyTab: some View {
        VStack(spacing: 20) {
            // Title font
            DesignerSection(title: "Title Style") {
                fontStyleEditor(
                    style: $config.titleStyle,
                    colorTarget: .titleColor
                )
            }
            
            // Body font
            DesignerSection(title: "Body Style") {
                fontStyleEditor(
                    style: $config.bodyStyle,
                    colorTarget: .bodyColor
                )
            }
        }
    }
    
    private func fontStyleEditor(style: Binding<WidgetFontStyle>, colorTarget: ColorPickerTarget) -> some View {
        VStack(spacing: 12) {
            // Font family
            Picker("Font", selection: style.family) {
                ForEach(WidgetFontFamily.allCases, id: \.rawValue) { family in
                    Text(family.displayName).tag(family)
                }
            }
            .pickerStyle(.menu)
            
            // Size and weight row
            HStack(spacing: 12) {
                // Size picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Size")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Picker("", selection: style.size) {
                        ForEach(WidgetFontSize.allCases, id: \.rawValue) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Weight picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Picker("", selection: style.weight) {
                        ForEach(WidgetFontWeight.allCases, id: \.rawValue) { weight in
                            Text(weight.displayName).tag(weight)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            // Color picker
            ColorPickerRow(
                title: "Color",
                color: style.wrappedValue.color.color,
                onTap: {
                    colorPickerTarget = colorTarget
                    tempColor = style.wrappedValue.color.color
                    showingColorPicker = true
                }
            )
        }
    }
    
    // MARK: - Content Tab
    
    private var contentTab: some View {
        VStack(spacing: 20) {
            // Widget name
            DesignerSection(title: "Widget Name") {
                TextField("Enter name", text: $config.name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Content-specific options based on widget type
            contentOptionsForType
        }
    }
    
    @ViewBuilder
    private var contentOptionsForType: some View {
        switch config.widgetType {
        case .verseOfDay, .scriptureQuote:
            DesignerSection(title: "Scripture Settings") {
                VStack(spacing: 12) {
                    TextField("Verse reference (e.g., John 3:16)", text: Binding(
                        get: { config.contentConfig.selectedVerseReference ?? "" },
                        set: { config.contentConfig.selectedVerseReference = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    Picker("Translation", selection: Binding(
                        get: { config.contentConfig.translationId ?? "KJV" },
                        set: { config.contentConfig.translationId = $0 }
                    )) {
                        Text("KJV").tag("KJV")
                        Text("NIV").tag("NIV")
                        Text("ESV").tag("ESV")
                        Text("NASB").tag("NASB")
                    }
                    .pickerStyle(.menu)
                }
            }
            
        case .readingProgress:
            DesignerSection(title: "Display Options") {
                VStack(spacing: 12) {
                    Toggle("Show Percentage", isOn: $config.contentConfig.showPercentage)
                        .tint(themeManager.accentColor)
                    
                    Toggle("Show Streak", isOn: $config.contentConfig.showStreak)
                        .tint(themeManager.accentColor)
                }
            }
            
        case .prayerReminder:
            DesignerSection(title: "Prayer Options") {
                Toggle("Show Prayer Count", isOn: $config.contentConfig.showPrayerCount)
                    .tint(themeManager.accentColor)
            }
            
        case .habitTracker:
            DesignerSection(title: "Habit Display") {
                Toggle("Show Completion Ring", isOn: $config.contentConfig.showCompletionRing)
                    .tint(themeManager.accentColor)
            }
            
        case .countdown:
            DesignerSection(title: "Countdown Settings") {
                VStack(spacing: 12) {
                    TextField("Event Title", text: Binding(
                        get: { config.contentConfig.countdownTitle ?? "" },
                        set: { config.contentConfig.countdownTitle = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    DatePicker(
                        "Target Date",
                        selection: Binding(
                            get: { config.contentConfig.countdownDate ?? Date().addingTimeInterval(86400 * 7) },
                            set: { config.contentConfig.countdownDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                }
            }
            
        case .moodGratitude:
            DesignerSection(title: "Display Options") {
                VStack(spacing: 12) {
                    Toggle("Show Mood History", isOn: $config.contentConfig.showMoodHistory)
                        .tint(themeManager.accentColor)
                    
                    Toggle("Show Gratitude Prompt", isOn: $config.contentConfig.showGratitudePrompt)
                        .tint(themeManager.accentColor)
                }
            }
            
        case .favorites:
            DesignerSection(title: "Favorites Display") {
                VStack(spacing: 12) {
                    Stepper(
                        "Max verses: \(config.contentConfig.maxFavoritesToShow)",
                        value: $config.contentConfig.maxFavoritesToShow,
                        in: 1...5
                    )
                    
                    Toggle("Show Bookmarks", isOn: $config.contentConfig.showBookmarks)
                        .tint(themeManager.accentColor)
                }
            }
        }
    }
    
    // MARK: - Layout Tab
    
    private var layoutTab: some View {
        VStack(spacing: 20) {
            // Widget size
            DesignerSection(title: "Size") {
                HStack(spacing: 8) {
                    ForEach(config.widgetType.supportedSizes) { size in
                        SizeButton(
                            size: size,
                            isSelected: config.size == size,
                            onTap: {
                                HapticManager.shared.lightImpact()
                                config.size = size
                            }
                        )
                    }
                }
            }
            
            // Text alignment
            DesignerSection(title: "Text Alignment") {
                HStack(spacing: 8) {
                    ForEach(WidgetTextAlignment.allCases, id: \.rawValue) { alignment in
                        AlignmentButton(
                            alignment: alignment,
                            isSelected: config.textAlignment == alignment,
                            onTap: {
                                HapticManager.shared.lightImpact()
                                config.textAlignment = alignment
                            }
                        )
                    }
                }
            }
            
            // Padding
            DesignerSection(title: "Padding") {
                Picker("Padding", selection: $config.padding) {
                    ForEach(WidgetPadding.allCases, id: \.rawValue) { padding in
                        Text(padding.displayName).tag(padding)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    // MARK: - Color Application
    
    private func applyColor(_ color: Color) {
        let codableColor = CodableColor(color: color)
        
        switch colorPickerTarget {
        case .background:
            if case .solid = config.background {
                config.background = .solid(color: codableColor)
            } else if case .pattern(let name, _) = config.background {
                config.background = .pattern(patternName: name, baseColor: codableColor)
            }
            
        case .titleColor:
            config.titleStyle.color = codableColor
            
        case .bodyColor:
            config.bodyStyle.color = codableColor
            
        case .gradientStart:
            if case .gradient(var colors, let start, let end) = config.background {
                if colors.isEmpty {
                    colors = [codableColor, CodableColor(color: .purple)]
                } else {
                    colors[0] = codableColor
                }
                config.background = .gradient(colors: colors, startPoint: start, endPoint: end)
            }
            
        case .gradientEnd:
            if case .gradient(var colors, let start, let end) = config.background {
                if colors.count < 2 {
                    colors = [CodableColor(color: .blue), codableColor]
                } else {
                    colors[colors.count - 1] = codableColor
                }
                config.background = .gradient(colors: colors, startPoint: start, endPoint: end)
            }
            
        case .none:
            break
        }
    }
}

// MARK: - Supporting Views

struct DesignerSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.cardBackgroundColor)
                )
        }
    }
}

struct ColorPickerRow: View {
    let title: String
    let color: Color
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
}

struct ColorPickerSheet: View {
    @Binding var color: Color
    let onSelect: (Color) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let presetColors: [Color] = [
        .white, .black, .gray,
        .red, .orange, .yellow,
        .green, .mint, .teal,
        .cyan, .blue, .indigo,
        .purple, .pink, .brown
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                // Preset colors
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                    ForEach(presetColors, id: \.description) { presetColor in
                        Button(action: {
                            color = presetColor
                        }) {
                            Circle()
                                .fill(presetColor)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(color == presetColor ? themeManager.accentColor : Color.gray.opacity(0.3), lineWidth: color == presetColor ? 3 : 1)
                                )
                        }
                    }
                }
                
                // System color picker
                ColorPicker("Custom Color", selection: $color)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.cardBackgroundColor)
                    )
                
                Spacer()
            }
            .padding()
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSelect(color)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

struct CornerStyleButton: View {
    let style: WidgetCornerStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: style.radius * 0.3)
                    .fill(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3))
                    .frame(width: 32, height: 32)
                
                Text(style.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct GradientDirectionButton: View {
    let symbol: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            Text(symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? themeManager.accentColor.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct PatternButton: View {
    let pattern: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var icon: String {
        switch pattern {
        case "crosses": return "cross"
        case "dots": return "circle.grid.3x3"
        case "lines": return "line.3.horizontal"
        case "waves": return "water.waves"
        default: return "square.grid.2x2"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? themeManager.accentColor.opacity(0.2) : themeManager.cardBackgroundColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
                    )
                
                Text(pattern.capitalized)
                    .font(.caption2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
        }
    }
}

struct SizeButton: View {
    let size: WidgetSize
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                sizeVisualization
                
                Text(size.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    @ViewBuilder
    private var sizeVisualization: some View {
        switch size {
        case .small:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 20, height: 20)
        case .medium:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 40, height: 20)
        case .large:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 40, height: 40)
        }
    }
}

struct AlignmentButton: View {
    let alignment: WidgetTextAlignment
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var icon: String {
        switch alignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? themeManager.accentColor.opacity(0.12) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
        }
    }
}

#Preview {
    WidgetCustomDesigner(
        config: WidgetConfig(widgetType: .verseOfDay),
        onSave: { _ in },
        onCancel: { }
    )
}


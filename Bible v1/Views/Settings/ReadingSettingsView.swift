//
//  ReadingSettingsView.swift
//  Bible v1
//
//  Full-page reading settings with presets and enhanced controls
//

import SwiftUI

struct ReadingSettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var presetStore = ReadingPresetStore.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var previewVerseIndex = 0
    @State private var showCreatePreset = false
    @State private var selectedPremiumFamily: ThemeFamily?
    @State private var showThemeStudioSheet = false
    @State private var showPaywall = false
    @State private var showThemeStudioPurchase = false
    
    private let previewVerses = [
        ("John 3:16", "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."),
        ("Psalm 23:1", "The Lord is my shepherd; I shall not want."),
        ("Proverbs 3:5-6", "Trust in the Lord with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths."),
        ("Philippians 4:13", "I can do all things through Christ which strengtheneth me."),
        ("Romans 8:28", "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.")
    ]
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Theme Section (NEW)
                    themeSection
                    
                    // Presets Section
                    presetsSection
                    
                    // Text Size Section
                    textSizeSection
                    
                    // Font Selection Section
                    fontSelectionSection
                    
                    // Layout Options Section
                    layoutOptionsSection
                    
                    // Preview Section
                    previewSection
                }
                .padding()
            }
        }
        .navigationTitle("Reading")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreatePreset) {
            CreatePresetSheet()
        }
        .sheet(item: $selectedPremiumFamily) { family in
            ThemeModePickerSheet(themeFamily: family) { theme in
                settings.selectedTheme = theme
            }
        }
        .sheet(isPresented: $showThemeStudioSheet) {
            ThemeStudioView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showThemeStudioPurchase) {
            ThemeStudioPurchaseSheet()
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THEME")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                // Free themes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Themes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(AppTheme.freeThemes) { theme in
                            ReadingThemeCard(
                                theme: theme,
                                isSelected: settings.selectedTheme == theme,
                                themeManager: themeManager
                            ) {
                                settings.selectedTheme = theme
                                HapticManager.shared.selection()
                            }
                        }
                    }
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Premium themes
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Premium Themes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        if subscriptionManager.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(AppTheme.premiumFamilies, id: \.self) { family in
                            ReadingPremiumThemeCard(
                                family: family,
                                isLocked: !subscriptionManager.isPremium,
                                isSelected: settings.selectedTheme.family == family,
                                themeManager: themeManager
                            ) {
                                if subscriptionManager.isPremium {
                                    selectedPremiumFamily = family
                                } else {
                                    showPaywall = true
                                }
                            }
                        }
                    }
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Custom theme
                CustomThemeButtonView(
                    isPurchased: subscriptionManager.canUseThemeStudio,
                    isSelected: settings.selectedTheme == .custom,
                    themeManager: themeManager,
                    onTap: {
                        if subscriptionManager.canUseThemeStudio {
                            showThemeStudioSheet = true
                        } else {
                            showThemeStudioPurchase = true
                        }
                    },
                    onApply: {
                        settings.selectedTheme = .custom
                        HapticManager.shared.success()
                    }
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Presets Section
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PRESETS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presetStore.allPresets) { preset in
                        PresetCard(
                            preset: preset,
                            isSelected: settings.activePresetId == preset.id,
                            themeManager: themeManager
                        ) {
                            settings.applyPreset(preset)
                            HapticManager.shared.success()
                        }
                    }
                    
                    // Create custom preset button
                    Button {
                        showCreatePreset = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Custom")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(width: 80, height: 90)
                        .background(themeManager.cardBackgroundColor)
                        .foregroundColor(themeManager.accentColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(themeManager.dividerColor, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Text Size Section
    
    private var textSizeSection: some View {
        ResettableSection(
            title: "Text Size",
            resetTitle: "Reset Size",
            onReset: {
                settings.readerTextOffset = 1.0
            }
        ) {
            VStack(spacing: 16) {
                // Helper text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reader Text Size")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Applies only to scripture reading. Combines with App Text Size and iOS settings.")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                // Slider with tick marks
                SettingsSliderRow(
                    title: "",
                    value: $settings.readerTextOffset,
                    range: 0.70...2.0,
                    step: 0.05,
                    tickMarks: [0.70, 1.0, 1.25, 1.5, 1.75, 2.0],
                    formatValue: { String(format: "%.0f%%", $0 * 100) }
                ) { _ in
                    settings.clearActivePreset()
                }
                
                // Computed size display
                HStack {
                    Text("Effective size:")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Text(String(format: "%.0fpt", settings.effectiveReaderFontSize))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
    
    // MARK: - Font Selection Section
    
    private var fontSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FONT")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Grouped by category
                ForEach(ReadingFont.FontCategory.allCases, id: \.self) { category in
                    let fonts = ReadingFont.allCases.filter { $0.category == category }
                    
                    if !fonts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .padding(.top, 12)
                            
                            ForEach(fonts) { font in
                                FontSelectionRow(
                                    font: font,
                                    isSelected: settings.readerFontFamily == font,
                                    themeManager: themeManager
                                ) {
                                    settings.readerFontFamily = font
                                    settings.clearActivePreset()
                                    HapticManager.shared.selection()
                                }
                                
                                if font != fonts.last {
                                    Divider()
                                        .background(themeManager.dividerColor)
                                }
                            }
                        }
                        
                        if category != ReadingFont.FontCategory.allCases.last {
                            Divider()
                                .background(themeManager.dividerColor)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Layout Options Section
    
    private var layoutOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LAYOUT")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Show verse numbers
                SettingsToggleRow(
                    icon: "number",
                    title: "Show Verse Numbers",
                    isOn: $settings.showVerseNumbers
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Paragraph mode
                SettingsToggleRow(
                    icon: "text.justify",
                    title: "Paragraph Mode",
                    subtitle: "Display as paragraphs instead of verses",
                    isOn: $settings.paragraphMode
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Line spacing
                SettingsSliderRow(
                    title: "Line Spacing",
                    value: $settings.readerLineSpacing,
                    range: 1.0...2.5,
                    step: 0.1,
                    tickMarks: [1.0, 1.4, 1.8, 2.2],
                    formatValue: { String(format: "%.1fx", $0) }
                ) { _ in
                    settings.clearActivePreset()
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                // Text alignment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Alignment")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 12) {
                        AlignmentButton(
                            alignment: .leading,
                            icon: "text.alignleft",
                            isSelected: settings.readerTextAlignment == .leading,
                            themeManager: themeManager
                        ) {
                            settings.readerTextAlignment = .leading
                        }
                        
                        AlignmentButton(
                            alignment: .center,
                            icon: "text.aligncenter",
                            isSelected: settings.readerTextAlignment == .center,
                            themeManager: themeManager
                        ) {
                            settings.readerTextAlignment = .center
                        }
                        
                        AlignmentButton(
                            alignment: .trailing,
                            icon: "text.alignright",
                            isSelected: settings.readerTextAlignment == .trailing,
                            themeManager: themeManager
                        ) {
                            settings.readerTextAlignment = .trailing
                        }
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PREVIEW")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Button {
                    withAnimation {
                        previewVerseIndex = (previewVerseIndex + 1) % previewVerses.count
                    }
                } label: {
                    Label("Change", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(previewVerses[previewVerseIndex].0)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                
                HStack(alignment: .top, spacing: 4) {
                    if settings.showVerseNumbers {
                        Text("1")
                            .font(settings.verseNumberFont)
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    Text(previewVerses[previewVerseIndex].1)
                        .font(settings.verseFont)
                        .lineSpacing(CGFloat(settings.readerLineSpacing * 4))
                        .foregroundColor(themeManager.textColor)
                        .multilineTextAlignment(settings.readerTextAlignment == .center ? .center : (settings.readerTextAlignment == .trailing ? .trailing : .leading))
                }
            }
            .frame(maxWidth: .infinity, alignment: settings.readerTextAlignment == .center ? .center : (settings.readerTextAlignment == .trailing ? .trailing : .leading))
            .padding()
            .background(themeManager.backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(themeManager.dividerColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preset Card

struct PresetCard: View {
    let preset: ReadingPreset
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.title2)
                
                Text(preset.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if preset.isCustom {
                    Text("Custom")
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(width: 80, height: 90)
            .background(isSelected ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(preset.name) preset")
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Font Selection Row

struct FontSelectionRow: View {
    let font: ReadingFont
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(font.displayName)
                        .font(font.font(size: 16))
                        .foregroundColor(themeManager.textColor)
                    
                    Text("The quick brown fox jumps")
                        .font(font.font(size: 12))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Alignment Button

struct AlignmentButton: View {
    let alignment: TextAlignment
    let icon: String
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? themeManager.accentColor.opacity(0.15) : Color.clear)
                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isSelected ? 2 : 1)
                )
        }
    }
}

// MARK: - Create Preset Sheet

struct CreatePresetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var presetStore = ReadingPresetStore.shared
    
    @State private var presetName = ""
    @State private var selectedIcon = "book.fill"
    
    private let icons = [
        "book.fill", "text.book.closed.fill", "book.closed.fill",
        "moon.fill", "sun.max.fill", "sparkles",
        "eyeglasses", "heart.fill", "star.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preset Name")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("My Reading Style", text: $presetName)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(10)
                    }
                    
                    // Icon selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
                                        .foregroundColor(selectedIcon == icon ? themeManager.accentColor : themeManager.secondaryTextColor)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(selectedIcon == icon ? themeManager.accentColor : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Current settings preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Will save these settings:")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SettingPreviewRow(label: "Font", value: settings.readerFontFamily.displayName)
                            SettingPreviewRow(label: "Size", value: String(format: "%.0f%%", settings.readerTextOffset * 100))
                            SettingPreviewRow(label: "Spacing", value: String(format: "%.1fx", settings.readerLineSpacing))
                            SettingPreviewRow(label: "Theme", value: settings.selectedTheme.displayName)
                        }
                        .padding()
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    // Save button
                    Button {
                        _ = presetStore.createPreset(
                            name: presetName.isEmpty ? "My Preset" : presetName,
                            icon: selectedIcon,
                            from: settings
                        )
                        HapticManager.shared.success()
                        dismiss()
                    } label: {
                        Text("Save Preset")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.accentColor)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingPreviewRow: View {
    let label: String
    let value: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
        }
    }
}

// MARK: - Reading Theme Card

struct ReadingThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.title3)
                
                Text(theme.shortName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? themeManager.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}

// MARK: - Reading Premium Theme Card

struct ReadingPremiumThemeCard: View {
    let family: ThemeFamily
    let isLocked: Bool
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    private var gradientColors: [Color] {
        switch family {
        case .velvet:
            return [Color(hex: "C9A24B"), Color(hex: "8A5D00")]
        case .frostedGlass:
            return [Color(hex: "0A84FF"), Color(hex: "0069FF")]
        case .aurora:
            return [Color(hex: "14B8A6"), Color(hex: "A855F7")]
        default:
            return [themeManager.accentColor, themeManager.accentColor.opacity(0.7)]
        }
    }
    
    @ViewBuilder
    private var backgroundGradient: some View {
        if isSelected {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.15)
        } else {
            Color.clear
        }
    }
    
    private var borderGradient: LinearGradient {
        if isSelected {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [themeManager.dividerColor], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: family.icon)
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: isSelected ? gradientColors : [themeManager.secondaryTextColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .offset(x: 12, y: -10)
                    }
                }
                
                Text(family.displayName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundGradient)
            .foregroundColor(isSelected ? gradientColors[0] : themeManager.secondaryTextColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderGradient, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(family.displayName) theme")
        .accessibilityValue(isLocked ? "Locked, requires premium" : (isSelected ? "Selected" : ""))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReadingSettingsView()
    }
}


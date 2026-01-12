//
//  ThemeStudioView.swift
//  Bible v1
//
//  Custom theme creation interface - Theme Studio
//

import SwiftUI

/// Theme Studio - Custom theme creation interface
struct ThemeStudioView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    @State private var config: CustomThemeConfiguration
    @State private var showColorPicker = false
    
    init() {
        _config = State(initialValue: SettingsStore.shared.customThemeConfig)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background based on current config
                config.generatedColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Live Preview
                        livePreviewSection
                        
                        // Accent Color Section
                        accentColorSection
                        
                        // Neutral Temperature Section
                        temperatureSection
                        
                        // Corner Radius Section
                        cornerRadiusSection
                        
                        // Contrast & Effects Section
                        contrastEffectsSection
                        
                        // Dark/Light Mode Toggle
                        darkModeSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Theme Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(config.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(config.accentColor)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyTheme()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(config.accentColor)
                }
            }
        }
    }
    
    // MARK: - Live Preview Section
    
    private var livePreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(config.generatedColors.textMuted)
            
            ThemeStudioPreviewCard(config: config)
        }
    }
    
    // MARK: - Accent Color Section
    
    private var accentColorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCENT COLOR")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(config.generatedColors.textMuted)
            
            VStack(spacing: 16) {
                // Color presets
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(AccentColorPreset.presets) { preset in
                        ColorPresetButton(
                            preset: preset,
                            isSelected: config.accentColorHex.uppercased() == preset.hex.uppercased(),
                            config: config
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                config.accentColorHex = preset.hex
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                
                // Custom color picker button
                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Circle()
                            .fill(config.accentColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("Custom Color")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("#\(config.accentColorHex.uppercased())")
                            .font(.caption)
                            .foregroundColor(config.generatedColors.textMuted)
                            .monospacedDigit()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(config.generatedColors.textMuted)
                    }
                    .padding()
                    .background(config.generatedColors.surface)
                    .foregroundColor(config.generatedColors.text)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(config.generatedColors.surface.opacity(0.5))
            .cornerRadius(14)
        }
        .sheet(isPresented: $showColorPicker) {
            CustomColorPickerSheet(
                selectedHex: $config.accentColorHex,
                config: config
            )
        }
    }
    
    // MARK: - Temperature Section
    
    private var temperatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEUTRAL TEMPERATURE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(config.generatedColors.textMuted)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "snowflake")
                        .foregroundColor(.blue)
                    
                    Slider(value: $config.neutralTemperature, in: 0...1, step: 0.05)
                        .tint(config.accentColor)
                        .onChange(of: config.neutralTemperature) { _, _ in
                            HapticManager.shared.selection()
                        }
                    
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Cool")
                        .font(.caption)
                        .foregroundColor(config.generatedColors.textMuted)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", config.neutralTemperature * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(config.accentColor)
                    
                    Spacer()
                    
                    Text("Warm")
                        .font(.caption)
                        .foregroundColor(config.generatedColors.textMuted)
                }
            }
            .padding()
            .background(config.generatedColors.surface.opacity(0.5))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Corner Radius Section
    
    private var cornerRadiusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CORNER RADIUS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(config.generatedColors.textMuted)
            
            HStack(spacing: 8) {
                ForEach(ThemeCornerRadius.allCases) { radius in
                    CornerRadiusButton(
                        radius: radius,
                        isSelected: config.cornerRadius == radius,
                        config: config
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            config.cornerRadius = radius
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding()
            .background(config.generatedColors.surface.opacity(0.5))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Contrast & Effects Section
    
    private var contrastEffectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTRAST & EFFECTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(config.generatedColors.textMuted)
            
            VStack(spacing: 0) {
                // Contrast level
                HStack {
                    Label("Contrast", systemImage: "circle.lefthalf.filled")
                        .foregroundColor(config.generatedColors.text)
                    
                    Spacer()
                    
                    CustomSegmentedPicker(
                        options: ContrastLevel.allCases,
                        selection: $config.contrastLevel,
                        config: config
                    )
                    .frame(width: 160)
                }
                .padding()
                
                Divider()
                    .background(config.generatedColors.border)
                
                // Glass intensity
                HStack {
                    Label("Glass Effect", systemImage: "rectangle.on.rectangle")
                        .foregroundColor(config.generatedColors.text)
                    
                    Spacer()
                    
                    CustomSegmentedPicker(
                        options: GlassIntensity.allCases,
                        selection: $config.glassIntensity,
                        config: config
                    )
                    .frame(width: 180)
                }
                .padding()
            }
            .background(config.generatedColors.surface.opacity(0.5))
            .cornerRadius(14)
        }
    }
    
    // MARK: - Dark Mode Section
    
    private var darkModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BASE MODE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(config.generatedColors.textMuted)
            
            HStack(spacing: 12) {
                DarkModeToggleButton(
                    title: "Light",
                    icon: "sun.max.fill",
                    isSelected: !config.isDarkMode,
                    config: config
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        config.isDarkMode = false
                    }
                    HapticManager.shared.selection()
                }
                
                DarkModeToggleButton(
                    title: "Dark",
                    icon: "moon.fill",
                    isSelected: config.isDarkMode,
                    config: config
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        config.isDarkMode = true
                    }
                    HapticManager.shared.selection()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func applyTheme() {
        settings.customThemeConfig = config
        settings.selectedTheme = .custom
        HapticManager.shared.success()
        dismiss()
    }
}

// MARK: - Theme Studio Preview Card

struct ThemeStudioPreviewCard: View {
    let config: CustomThemeConfiguration
    
    private var colors: CustomThemeColors {
        config.generatedColors
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: config.cornerRadiusValue)
                .fill(colors.background)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Header simulation
                HStack {
                    Circle()
                        .fill(colors.accent)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colors.text)
                            .frame(width: 100, height: 10)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colors.textMuted)
                            .frame(width: 60, height: 6)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "ellipsis")
                        .foregroundColor(colors.textMuted)
                }
                
                // Card simulation
                RoundedRectangle(cornerRadius: config.cornerRadiusValue * 0.7)
                    .fill(colors.surface)
                    .frame(height: 60)
                    .overlay(
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colors.accent.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "book.fill")
                                        .font(.caption)
                                        .foregroundColor(colors.accent)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colors.text)
                                    .frame(width: 120, height: 8)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colors.textMuted)
                                    .frame(width: 80, height: 6)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: config.cornerRadiusValue * 0.7)
                            .strokeBorder(colors.border, lineWidth: 1)
                    )
                
                // Button simulation
                HStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: config.cornerRadiusValue * 0.5)
                        .fill(colors.primary)
                        .frame(width: 100, height: 36)
                        .overlay(
                            Text("Button")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.onPrimary)
                        )
                }
            }
            .padding()
        }
        .frame(height: 180)
        .overlay(
            RoundedRectangle(cornerRadius: config.cornerRadiusValue)
                .strokeBorder(colors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
    }
}

// MARK: - Color Preset Button

struct ColorPresetButton: View {
    let preset: AccentColorPreset
    let isSelected: Bool
    let config: CustomThemeConfiguration
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(preset.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        isSelected ? Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white) : nil
                    )
                    .shadow(color: preset.color.opacity(0.4), radius: isSelected ? 8 : 0)
                
                Text(preset.name)
                    .font(.caption2)
                    .foregroundColor(config.generatedColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

// MARK: - Corner Radius Button

struct CornerRadiusButton: View {
    let radius: ThemeCornerRadius
    let isSelected: Bool
    let config: CustomThemeConfiguration
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: radius.cgFloat * 0.5)
                    .fill(isSelected ? config.accentColor : config.generatedColors.surfaceElevated)
                    .frame(width: 40, height: 28)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius.cgFloat * 0.5)
                            .strokeBorder(isSelected ? config.accentColor : config.generatedColors.border, lineWidth: 1)
                    )
                
                Text(radius.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? config.accentColor : config.generatedColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? config.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

// MARK: - Dark Mode Toggle Button

struct DarkModeToggleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let config: CustomThemeConfiguration
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? config.accentColor.opacity(0.15) : config.generatedColors.surface.opacity(0.5))
            .foregroundColor(isSelected ? config.accentColor : config.generatedColors.textMuted)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? config.accentColor : config.generatedColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Custom Color Picker Sheet

struct CustomColorPickerSheet: View {
    @Binding var selectedHex: String
    let config: CustomThemeConfiguration
    
    @Environment(\.dismiss) private var dismiss
    @State private var hexInput: String = ""
    @State private var selectedColor: Color = .blue
    
    var body: some View {
        NavigationStack {
            ZStack {
                config.generatedColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Color picker
                    ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .scaleEffect(1.5)
                        .frame(height: 100)
                    
                    // Preview
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 80, height: 80)
                        .shadow(color: selectedColor.opacity(0.5), radius: 15)
                    
                    // Hex input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hex Code")
                            .font(.subheadline)
                            .foregroundColor(config.generatedColors.textMuted)
                        
                        HStack {
                            Text("#")
                                .foregroundColor(config.generatedColors.textMuted)
                            
                            TextField("0A84FF", text: $hexInput)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .monospacedDigit()
                                .foregroundColor(config.generatedColors.text)
                                .onChange(of: hexInput) { _, newValue in
                                    let filtered = newValue.filter { $0.isHexDigit }.prefix(6)
                                    hexInput = String(filtered).uppercased()
                                    if hexInput.count == 6 {
                                        selectedColor = Color(hex: hexInput)
                                    }
                                }
                        }
                        .padding()
                        .background(config.generatedColors.surface)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Apply button
                    Button {
                        if hexInput.count == 6 {
                            selectedHex = hexInput
                        }
                        dismiss()
                    } label: {
                        Text("Apply Color")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(selectedColor)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(config.isDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(config.accentColor)
                }
            }
        }
        .onAppear {
            hexInput = selectedHex.uppercased()
            selectedColor = Color(hex: selectedHex)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Custom Segmented Picker

struct CustomSegmentedPicker<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    let options: [T]
    @Binding var selection: T
    let config: CustomThemeConfiguration
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selection = option
                    }
                    HapticManager.shared.selection()
                } label: {
                    Text(option.rawValue)
                        .font(.caption)
                        .fontWeight(selection == option ? .semibold : .regular)
                        .foregroundColor(selection == option ? config.generatedColors.onPrimary : config.generatedColors.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selection == option ?
                                config.accentColor :
                                Color.clear
                        )
                }
            }
        }
        .background(config.generatedColors.surfaceElevated)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(config.generatedColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ThemeStudioView()
}


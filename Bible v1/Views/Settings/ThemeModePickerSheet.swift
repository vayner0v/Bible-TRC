//
//  ThemeModePickerSheet.swift
//  Bible v1
//
//  Modal sheet for selecting Light/Dark mode when user picks a premium theme
//

import SwiftUI

/// Sheet presented when user selects a premium theme family
/// Allows choosing between Light and Dark variants
struct ThemeModePickerSheet: View {
    let themeFamily: ThemeFamily
    let onSelect: (AppTheme) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    
    @State private var selectedMode: ThemeMode = .dark
    
    /// Theme mode options
    enum ThemeMode: String, CaseIterable, Identifiable {
        case light = "Light"
        case dark = "Dark"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
    
    /// Get the theme for selected mode
    private var selectedTheme: AppTheme? {
        switch themeFamily {
        case .velvet:
            return selectedMode == .light ? .velvetLight : .velvetDark
        case .frostedGlass:
            return selectedMode == .light ? .frostedGlassLight : .frostedGlassDark
        case .aurora:
            return selectedMode == .light ? .auroraLight : .auroraDark
        default:
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Use colors matching the theme family being previewed
                sheetBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Subtitle
                    Text("Choose your preferred mode")
                        .font(.subheadline)
                        .foregroundColor(sheetSecondaryTextColor)
                        .padding(.top, 4)
                    
                    // Mode selection cards
                    HStack(spacing: 16) {
                        ForEach(ThemeMode.allCases) { mode in
                            ThemeModeCard(
                                mode: mode,
                                themeFamily: themeFamily,
                                isSelected: selectedMode == mode,
                                themeManager: themeManager
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedMode = mode
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preview section
                    ThemePreviewCard(
                        theme: selectedTheme,
                        themeFamily: themeFamily
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 0)
                }
                
                // Apply button pinned to bottom
                VStack {
                    Spacer()
                    
                    Button {
                        if let theme = selectedTheme {
                            onSelect(theme)
                            HapticManager.shared.success()
                            dismiss()
                        }
                    } label: {
                        Text("Apply Theme")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: gradientColorsForFamily,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(themeFamily.displayName)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(gradientColorsForFamily[0])
                }
            }
        }
        .presentationDetents([.height(580)])
        .presentationDragIndicator(.visible)
    }
    
    /// Gradient colors for the theme family
    private var gradientColorsForFamily: [Color] {
        switch themeFamily {
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
    
    /// Background color based on the theme family (uses light variant as neutral)
    private var sheetBackgroundColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.background
        case .frostedGlass:
            return AppColors.FrostedGlassLight.background
        case .aurora:
            return AppColors.AuroraLight.background
        default:
            return themeManager.backgroundColor
        }
    }
    
    /// Card background color for the sheet
    private var sheetCardColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.surface
        case .frostedGlass:
            return Color.white.opacity(0.9)
        case .aurora:
            return AppColors.AuroraLight.surface
        default:
            return themeManager.cardBackgroundColor
        }
    }
    
    /// Text color for the sheet
    private var sheetTextColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.text
        case .frostedGlass:
            return AppColors.FrostedGlassLight.text
        case .aurora:
            return AppColors.AuroraLight.text
        default:
            return themeManager.textColor
        }
    }
    
    /// Secondary text color for the sheet
    private var sheetSecondaryTextColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.textMuted
        case .frostedGlass:
            return AppColors.FrostedGlassLight.textMuted
        case .aurora:
            return AppColors.AuroraLight.textMuted
        default:
            return themeManager.secondaryTextColor
        }
    }
    
    /// Divider color for the sheet
    private var sheetDividerColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.border
        case .frostedGlass:
            return AppColors.FrostedGlassLight.border
        case .aurora:
            return AppColors.AuroraLight.border
        default:
            return themeManager.dividerColor
        }
    }
}

// MARK: - Theme Mode Card

struct ThemeModeCard: View {
    let mode: ThemeModePickerSheet.ThemeMode
    let themeFamily: ThemeFamily
    let isSelected: Bool
    let themeManager: ThemeManager
    let action: () -> Void
    
    private var previewColors: (background: Color, surface: Color, accent: Color) {
        switch (themeFamily, mode) {
        case (.velvet, .light):
            return (AppColors.VelvetLight.background, AppColors.VelvetLight.surface, AppColors.VelvetLight.accent)
        case (.velvet, .dark):
            return (AppColors.VelvetDark.background, AppColors.VelvetDark.surface, AppColors.VelvetDark.accent)
        case (.frostedGlass, .light):
            return (AppColors.FrostedGlassLight.background, Color.white.opacity(0.8), AppColors.FrostedGlassLight.accent)
        case (.frostedGlass, .dark):
            return (AppColors.FrostedGlassDark.background, Color.white.opacity(0.1), AppColors.FrostedGlassDark.accent)
        case (.aurora, .light):
            return (AppColors.AuroraLight.background, AppColors.AuroraLight.surface, AppColors.AuroraLight.accentTeal)
        case (.aurora, .dark):
            return (AppColors.AuroraDark.background, AppColors.AuroraDark.surface, AppColors.AuroraDark.accentTeal)
        default:
            return (themeManager.backgroundColor, themeManager.cardBackgroundColor, themeManager.accentColor)
        }
    }
    
    /// Card colors based on theme family (using light as base)
    private var cardColors: (background: Color, text: Color, textMuted: Color, border: Color) {
        switch themeFamily {
        case .velvet:
            return (AppColors.VelvetLight.surface, AppColors.VelvetLight.text, AppColors.VelvetLight.textMuted, AppColors.VelvetLight.border)
        case .frostedGlass:
            return (Color.white.opacity(0.9), AppColors.FrostedGlassLight.text, AppColors.FrostedGlassLight.textMuted, AppColors.FrostedGlassLight.border)
        case .aurora:
            return (AppColors.AuroraLight.surface, AppColors.AuroraLight.text, AppColors.AuroraLight.textMuted, AppColors.AuroraLight.border)
        default:
            return (themeManager.cardBackgroundColor, themeManager.textColor, themeManager.secondaryTextColor, themeManager.dividerColor)
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Mini preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(previewColors.background)
                        .frame(height: 80)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(previewColors.surface)
                        .frame(width: 60, height: 40)
                    
                    Circle()
                        .fill(previewColors.accent)
                        .frame(width: 16, height: 16)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isSelected ? previewColors.accent : Color.clear,
                            lineWidth: 2
                        )
                )
                
                // Label
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                        .font(.caption)
                    
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(isSelected ? previewColors.accent : cardColors.textMuted)
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? previewColors.accent : cardColors.border)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? previewColors.accent.opacity(0.5) : cardColors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let theme: AppTheme?
    let themeFamily: ThemeFamily
    
    private var colors: (bg: Color, surface: Color, text: Color, accent: Color) {
        guard let theme else {
            return (Color.gray.opacity(0.1), Color.white, Color.black, Color.blue)
        }
        
        switch theme {
        case .velvetLight:
            return (AppColors.VelvetLight.background, AppColors.VelvetLight.surface, AppColors.VelvetLight.text, AppColors.VelvetLight.accent)
        case .velvetDark:
            return (AppColors.VelvetDark.background, AppColors.VelvetDark.surface, AppColors.VelvetDark.text, AppColors.VelvetDark.accent)
        case .frostedGlassLight:
            return (AppColors.FrostedGlassLight.background, Color.white.opacity(0.8), AppColors.FrostedGlassLight.text, AppColors.FrostedGlassLight.accent)
        case .frostedGlassDark:
            return (AppColors.FrostedGlassDark.background, Color.white.opacity(0.1), AppColors.FrostedGlassDark.text, AppColors.FrostedGlassDark.accent)
        case .auroraLight:
            return (AppColors.AuroraLight.background, AppColors.AuroraLight.surface, AppColors.AuroraLight.text, AppColors.AuroraLight.accentTeal)
        case .auroraDark:
            return (AppColors.AuroraDark.background, AppColors.AuroraDark.surface, AppColors.AuroraDark.text, AppColors.AuroraDark.accentTeal)
        default:
            return (Color.gray.opacity(0.1), Color.white, Color.black, Color.blue)
        }
    }
    
    /// Label text color based on theme family
    private var labelTextColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.textMuted
        case .frostedGlass:
            return AppColors.FrostedGlassLight.textMuted
        case .aurora:
            return AppColors.AuroraLight.textMuted
        default:
            return Color.gray
        }
    }
    
    /// Border color based on theme family
    private var borderColor: Color {
        switch themeFamily {
        case .velvet:
            return AppColors.VelvetLight.border
        case .frostedGlass:
            return AppColors.FrostedGlassLight.border
        case .aurora:
            return AppColors.AuroraLight.border
        default:
            return Color.gray.opacity(0.2)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(labelTextColor)
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.bg)
                
                // Content preview
                VStack(alignment: .leading, spacing: 12) {
                    // Header bar simulation
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colors.accent)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors.text)
                                .frame(width: 80, height: 10)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors.text.opacity(0.5))
                                .frame(width: 50, height: 6)
                        }
                        
                        Spacer()
                    }
                    
                    // Card simulation
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colors.surface)
                        .frame(height: 50)
                        .overlay(
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(colors.accent.opacity(0.3))
                                    .frame(width: 30, height: 30)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colors.text)
                                        .frame(width: 100, height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colors.text.opacity(0.4))
                                        .frame(width: 70, height: 6)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                        )
                    
                    // Button simulation
                    HStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.accent)
                            .frame(width: 80, height: 30)
                    }
                }
                .padding()
            }
            .frame(height: 160)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ThemeModePickerSheet(themeFamily: .velvet) { theme in
        print("Selected: \(theme.displayName)")
    }
}


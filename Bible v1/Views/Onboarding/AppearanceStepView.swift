//
//  AppearanceStepView.swift
//  Bible v1
//
//  Onboarding Appearance Selection
//

import SwiftUI

struct AppearanceStepView: View {
    let onContinue: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var settings = SettingsStore.shared
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.top, 40)
                
                Text("Personalize Your Experience")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
                
                Text("Choose how you want your Bible to look")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : -20)
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Theme Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theme")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                ThemeOptionCard(
                                    theme: theme,
                                    isSelected: themeManager.selectedTheme == theme,
                                    themeManager: themeManager
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        themeManager.selectedTheme = theme
                                    }
                                    HapticManager.shared.lightImpact()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // Font Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reading Font")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ReadingFont.allCases) { font in
                                    FontOptionCard(
                                        font: font,
                                        isSelected: themeManager.readingFont == font,
                                        themeManager: themeManager
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            themeManager.readingFont = font
                                        }
                                        HapticManager.shared.lightImpact()
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Font Size - uses SettingsStore.readerTextOffset for sync
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Text Size")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%%", settings.readerTextOffset * 100))
                                .font(.headline)
                                .foregroundColor(themeManager.accentColor)
                        }
                        
                        HStack(spacing: 16) {
                            Image(systemName: "textformat.size.smaller")
                                .foregroundColor(themeManager.secondaryTextColor)
                            
                            Slider(
                                value: $settings.readerTextOffset,
                                in: 0.70...2.0,
                                step: 0.05
                            )
                            .tint(themeManager.accentColor)
                            
                            Image(systemName: "textformat.size.larger")
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.")
                            .font(settings.verseFont)
                            .lineSpacing(CGFloat(settings.readerLineSpacing * 4))
                            .foregroundColor(themeManager.textColor)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                        
                        Text("— John 3:16")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 120)
                }
            }
            .opacity(showContent ? 1 : 0)
            
            // Continue button
            VStack {
                OnboardingPrimaryButton(title: "Continue", action: onContinue)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .background(
                LinearGradient(
                    colors: [themeManager.backgroundColor.opacity(0), themeManager.backgroundColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Theme Option Card

struct ThemeOptionCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Legacy init for compatibility
    init(theme: AppTheme, isSelected: Bool, themeManager: ThemeManager, onTap: @escaping () -> Void) {
        self.theme = theme
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.previewBackgroundColor)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 3)
                        )
                    
                    Image(systemName: theme.icon)
                        .font(.title2)
                        .foregroundColor(theme.previewForegroundColor)
                }
                
                Text(theme.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Font Option Card

struct FontOptionCard: View {
    let font: ReadingFont
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Legacy init for compatibility
    init(font: ReadingFont, isSelected: Bool, themeManager: ThemeManager, onTap: @escaping () -> Void) {
        self.font = font
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text("Aa")
                    .font(font.font(size: 24))
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
                
                Text(font.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : themeManager.secondaryTextColor)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : themeManager.dividerColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AppTheme Extension for Preview Colors

extension AppTheme {
    var previewBackgroundColor: Color {
        switch self {
        case .light: return Color(.systemBackground)
        case .dark: return Color(.black)
        case .system: return Color(.systemGray5)
        case .sepia: return Color(red: 0.96, green: 0.94, blue: 0.89)
        }
    }
    
    var previewForegroundColor: Color {
        switch self {
        case .light: return .black
        case .dark: return .white
        case .system: return .primary
        case .sepia: return Color(red: 0.4, green: 0.3, blue: 0.2)
        }
    }
}

#Preview {
    AppearanceStepView(onContinue: {})
}


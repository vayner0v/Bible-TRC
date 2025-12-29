//
//  WidgetPresetGallery.swift
//  Bible v1
//
//  Gallery of pre-designed widget themes
//

import SwiftUI

/// Gallery view for selecting widget presets
struct WidgetPresetGallery: View {
    let widgetType: BibleWidgetType
    @Binding var selectedSize: WidgetSize
    let onSelectPreset: (WidgetPreset) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedPreset: WidgetPreset?
    @State private var hasAppeared = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with widget type info
                    headerSection
                    
                    // Size picker
                    sizePicker
                    
                    // Presets grid
                    presetsGrid
                    
                    // Create Custom button
                    createCustomButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Choose a Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedPreset != nil {
                        Button("Use This") {
                            if let preset = selectedPreset {
                                onSelectPreset(preset)
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(widgetType.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .blur(radius: 6)
                
                Circle()
                    .fill(widgetType.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: widgetType.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(widgetType.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(widgetType.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text(widgetType.description)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
    }
    
    // MARK: - Size Picker
    
    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Widget Size")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            HStack(spacing: 8) {
                ForEach(widgetType.supportedSizes) { size in
                    SizePickerButton(
                        size: size,
                        isSelected: selectedSize == size,
                        onTap: {
                            HapticManager.shared.lightImpact()
                            withAnimation(.spring(response: 0.3)) {
                                selectedSize = size
                            }
                        }
                    )
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
    }
    
    // MARK: - Presets Grid
    
    private var presetsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Style Presets")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(WidgetPreset.allPresets.enumerated()), id: \.element.id) { index, preset in
                    PresetCard(
                        preset: preset,
                        widgetType: widgetType,
                        size: selectedSize,
                        isSelected: selectedPreset?.id == preset.id,
                        animationDelay: Double(index) * 0.05,
                        onTap: {
                            HapticManager.shared.lightImpact()
                            withAnimation(.spring(response: 0.3)) {
                                selectedPreset = preset
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Create Custom Button
    
    private var createCustomButton: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            // Create a default config and go to custom designer
            let defaultPreset = WidgetPreset.classicLight
            onSelectPreset(defaultPreset)
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Create Custom Widget")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Design your own with full customization")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1.5)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                    )
            )
        }
        .buttonStyle(TilePressStyle())
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
    }
}

// MARK: - Supporting Views

struct SizePickerButton: View {
    let size: WidgetSize
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Size visualization
                sizeVisualization
                
                Text(size.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                
                Text(size.gridDescription)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.12) : themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var sizeVisualization: some View {
        switch size {
        case .small:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 24, height: 24)
        case .medium:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 48, height: 24)
        case .large:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.3 : 0.15))
                .frame(width: 48, height: 48)
        }
    }
}

struct PresetCard: View {
    let preset: WidgetPreset
    let widgetType: BibleWidgetType
    let size: WidgetSize
    let isSelected: Bool
    let animationDelay: Double
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hasAppeared = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Preset preview
                presetPreview
                
                VStack(spacing: 2) {
                    Text(preset.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(preset.description)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? themeManager.accentColor.opacity(0.3) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(TilePressStyle())
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay)) {
                hasAppeared = true
            }
        }
    }
    
    private var presetPreview: some View {
        RoundedRectangle(cornerRadius: preset.config.cornerStyle.radius * 0.4)
            .fill(preset.thumbnailLinearGradient)
            .frame(height: 80)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: widgetType.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(preset.config.titleStyle.color.color)
                    
                    Text(widgetType.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(preset.config.bodyStyle.color.color)
                }
            )
    }
}

#Preview {
    WidgetPresetGallery(
        widgetType: .verseOfDay,
        selectedSize: .constant(.medium),
        onSelectPreset: { _ in }
    )
}


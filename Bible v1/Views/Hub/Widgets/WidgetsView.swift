//
//  WidgetsView.swift
//  Bible v1
//
//  Main Widgets configuration page in Hub
//

import SwiftUI

/// Main view for configuring iOS Home Screen widgets
struct WidgetsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var widgetService = WidgetDataService.shared
    
    @State private var selectedWidgetType: BibleWidgetType?
    @State private var selectedSize: WidgetSize = .medium
    @State private var showingPresetGallery = false
    @State private var showingCustomDesigner = false
    @State private var editingConfig: WidgetConfig?
    @State private var hasAppeared = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection
                    
                    // Widget types grid
                    widgetTypesSection
                    
                    // My Widgets section (if any saved)
                    if !widgetService.widgetConfigs.isEmpty {
                        myWidgetsSection
                    }
                    
                    // Instructions section
                    instructionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Widgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showingPresetGallery) {
                if let type = selectedWidgetType {
                    WidgetPresetGallery(
                        widgetType: type,
                        selectedSize: $selectedSize,
                        onSelectPreset: { preset in
                            let config = widgetService.createFromPreset(preset, type: type, size: selectedSize)
                            widgetService.addConfig(config)
                            showingPresetGallery = false
                            editingConfig = config
                            showingCustomDesigner = true
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCustomDesigner) {
                if let config = editingConfig {
                    WidgetCustomDesigner(
                        config: config,
                        onSave: { updatedConfig in
                            widgetService.updateConfig(updatedConfig)
                            showingCustomDesigner = false
                            editingConfig = nil
                        },
                        onCancel: {
                            showingCustomDesigner = false
                            editingConfig = nil
                        }
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Circle()
                    .fill(themeManager.accentColor.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(themeManager.accentColor)
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .opacity(hasAppeared ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("Home Screen Widgets")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Add beautiful Bible widgets to your home screen. Choose from presets or design your own.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Widget Types Section
    
    private var widgetTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Widget")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(BibleWidgetType.allCases) { type in
                    WidgetTypeCard(
                        type: type,
                        isSelected: selectedWidgetType == type,
                        onTap: {
                            HapticManager.shared.lightImpact()
                            selectedWidgetType = type
                            showingPresetGallery = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - My Widgets Section
    
    private var myWidgetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Widgets")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Text("\(widgetService.widgetConfigs.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(themeManager.accentColor.opacity(0.15))
                    .cornerRadius(8)
            }
            
            ForEach(widgetService.widgetConfigs) { config in
                SavedWidgetRow(
                    config: config,
                    onEdit: {
                        editingConfig = config
                        showingCustomDesigner = true
                    },
                    onDelete: {
                        withAnimation(.spring(response: 0.3)) {
                            widgetService.deleteConfig(config)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Add Widgets")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(number: 1, text: "Long-press on your home screen")
                InstructionStep(number: 2, text: "Tap the + button in the corner")
                InstructionStep(number: 3, text: "Search for \"Bible\" and select a widget")
                InstructionStep(number: 4, text: "Choose your preferred size and add it")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
    }
}

// MARK: - Supporting Views

struct WidgetTypeCard: View {
    let type: BibleWidgetType
    let isSelected: Bool
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .blur(radius: 6)
                    
                    Circle()
                        .fill(type.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(type.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Size badges
                HStack(spacing: 4) {
                    ForEach(type.supportedSizes) { size in
                        Text(size.gridDescription)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(type.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(type.color.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.hubElevatedSurface)
                    .shadow(
                        color: themeManager.hubShadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? type.color : type.color.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

struct SavedWidgetRow: View {
    let config: WidgetConfig
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Widget preview thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(config.widgetType.color.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: config.widgetType.icon)
                        .foregroundColor(config.widgetType.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(config.widgetType.displayName)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("•")
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(config.size.displayName)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.body)
                    .foregroundColor(themeManager.accentColor)
                    .padding(8)
                    .background(themeManager.accentColor.opacity(0.12))
                    .cornerRadius(8)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
        )
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(themeManager.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
        }
    }
}

#Preview {
    WidgetsView()
}


//
//  WidgetStudioView.swift
//  Bible v1
//
//  Main Widget Studio hub - Widgy-style widget designer
//

import SwiftUI

/// Main hub for the Widget Studio - creates and manages custom widgets
struct WidgetStudioView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var projectService = WidgetProjectService.shared
    
    @State private var showingTemplateGallery = false
    @State private var showingNewProjectSheet = false
    @State private var selectedWidgetType: BibleWidgetType = .verseOfDay
    @State private var selectedSize: WidgetSize = .medium
    @State private var editingProject: WidgetProject?
    @State private var showingEditor = false
    @State private var hasAppeared = false
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero Section
                    heroSection
                    
                    // Quick Create Section
                    quickCreateSection
                    
                    // My Widgets Section
                    myWidgetsSection
                    
                    // Templates Showcase
                    templatesShowcase
                    
                    // How to Add Section
                    instructionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Widget Studio")
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
            .sheet(isPresented: $showingTemplateGallery) {
                TemplateGalleryView(
                    widgetType: selectedWidgetType,
                    selectedSize: $selectedSize,
                    onSelectTemplate: { template in
                        let project = template.createProject(
                            widgetType: selectedWidgetType,
                            size: selectedSize
                        )
                        editingProject = project
                        showingTemplateGallery = false
                        showingEditor = true
                    }
                )
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(
                    onCreateProject: { type, size, templateId in
                        var project = WidgetProject(
                            widgetType: type,
                            size: size
                        )
                        // Add default layers based on widget type
                        project = addDefaultLayers(to: project)
                        editingProject = project
                        showingNewProjectSheet = false
                        showingEditor = true
                    }
                )
            }
            .fullScreenCover(isPresented: $showingEditor) {
                if let project = editingProject {
                    WidgetCanvasView(
                        project: project,
                        onSave: { savedProject in
                            saveProject(savedProject)
                            showingEditor = false
                            editingProject = nil
                        },
                        onCancel: {
                            showingEditor = false
                            editingProject = nil
                        }
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                hasAppeared = true
            }
            // Migrate legacy configs on first appearance
            projectService.migrateFromLegacyConfigs()
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                // Glow layers
                ForEach(0..<3) { i in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80 + CGFloat(i * 20), height: 80 + CGFloat(i * 20))
                        .blur(radius: CGFloat(10 + i * 5))
                        .opacity(0.3 - Double(i) * 0.1)
                }
                
                // Main icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .opacity(hasAppeared ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("Design Your Widgets")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Text("Create beautiful, custom widgets with layers, photos, gradients, and more")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Quick Create Section
    
    private var quickCreateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Create")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // From Template button
                QuickCreateButton(
                    icon: "rectangle.stack.fill",
                    title: "From Template",
                    subtitle: "Start with a design",
                    gradient: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
                    action: {
                        HapticManager.shared.mediumImpact()
                        showingTemplateGallery = true
                    }
                )
                
                // From Scratch button
                QuickCreateButton(
                    icon: "plus.square.dashed",
                    title: "From Scratch",
                    subtitle: "Build your own",
                    gradient: [Color.purple, Color.pink],
                    action: {
                        HapticManager.shared.mediumImpact()
                        showingNewProjectSheet = true
                    }
                )
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
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
                
                if !projectService.projects.isEmpty {
                    Text("\(projectService.projects.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(themeManager.accentColor.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            
            if projectService.projects.isEmpty {
                // Empty state
                EmptyWidgetsCard {
                    showingTemplateGallery = true
                }
            } else {
                // Widget grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(projectService.projects) { project in
                        SavedWidgetProjectCard(
                            project: project,
                            onTap: {
                                editingProject = project
                                showingEditor = true
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.3)) {
                                    projectService.deleteProject(project)
                                }
                            }
                        )
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Templates Showcase
    
    private var templatesShowcase: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Templates")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Button(action: {
                    showingTemplateGallery = true
                }) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WidgetTemplateLibrary.shared.featuredTemplates.prefix(5)) { template in
                        TemplatePreviewCard(
                            template: template,
                            onTap: {
                                selectedWidgetType = .verseOfDay
                                let project = template.createProject(
                                    widgetType: selectedWidgetType,
                                    size: selectedSize
                                )
                                editingProject = project
                                showingEditor = true
                            }
                        )
                    }
                }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Add Widgets")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                StudioInstructionStep(number: 1, text: "Long-press on your home screen")
                StudioInstructionStep(number: 2, text: "Tap the + button in the corner")
                StudioInstructionStep(number: 3, text: "Search for \"Bible\" and select")
                StudioInstructionStep(number: 4, text: "Choose size and add to home screen")
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Helper Methods
    
    private func addDefaultLayers(to project: WidgetProject) -> WidgetProject {
        var newProject = project
        
        // Add default layers based on widget type
        switch project.widgetType {
        case .verseOfDay, .scriptureQuote:
            newProject.addLayer(WidgetLayer(
                name: "Verse Text",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseText,
                    textStyle: TextElementConfig(
                        fontId: "georgia",
                        fontSize: 16,
                        textColor: CodableColor(color: .primary)
                    )
                )),
                frame: LayerFrame(x: 8, y: 20, width: 84, height: 55, rotation: 0)
            ))
            newProject.addLayer(WidgetLayer(
                name: "Reference",
                element: .dataBinding(DataBindingConfig(
                    dataType: .verseReference,
                    textStyle: TextElementConfig(
                        fontId: "system",
                        fontSize: 12,
                        fontWeight: .semibold,
                        textColor: CodableColor(color: .secondary)
                    )
                )),
                frame: LayerFrame(x: 8, y: 80, width: 84, height: 10, rotation: 0)
            ))
            
        default:
            // Add a default text layer
            newProject.addLayer(WidgetLayer(
                name: "Title",
                element: .text(TextElementConfig(
                    text: project.widgetType.displayName,
                    fontId: "system",
                    fontSize: 16,
                    fontWeight: .semibold
                )),
                frame: LayerFrame(x: 8, y: 10, width: 84, height: 15, rotation: 0)
            ))
        }
        
        return newProject
    }
    
    private func saveProject(_ project: WidgetProject) {
        // Save project with full layer data using the new service
        projectService.saveProject(project)
    }
}

// MARK: - Supporting Views

struct QuickCreateButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

struct EmptyWidgetsCard: View {
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "plus.circle")
                        .font(.system(size: 28))
                        .foregroundColor(themeManager.accentColor)
                }
                
                VStack(spacing: 4) {
                    Text("No Widgets Yet")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Create your first custom widget")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(themeManager.accentColor.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct SavedWidgetProjectCard: View {
    let project: WidgetProject
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Live preview
                ProjectPreviewCard(project: project, scale: 0.4)
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(project.size.displayName)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text("•")
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Text(project.widgetType.displayName)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(1)
                    }
                }
                
                // Delete button
                HStack {
                    Spacer()
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.hubShadowColor, radius: 6, y: 3)
            )
        }
        .buttonStyle(TilePressStyle())
        .alert("Delete Widget?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

struct TemplatePreviewCard: View {
    let template: WidgetTemplate
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Preview gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: template.previewColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 80)
                    .overlay(
                        Image(systemName: "textformat")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                    
                    Text(template.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(themeManager.cardBackgroundColor)
            )
        }
        .buttonStyle(TilePressStyle())
    }
}

struct StudioInstructionStep: View {
    let number: Int
    let text: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
        }
    }
}

struct NewProjectSheet: View {
    let onCreateProject: (BibleWidgetType, WidgetSize, String?) -> Void
    
    @State private var selectedType: BibleWidgetType = .verseOfDay
    @State private var selectedSize: WidgetSize = .medium
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Widget Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget Type")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(BibleWidgetType.allCases) { type in
                                WidgetTypeOption(
                                    type: type,
                                    isSelected: selectedType == type,
                                    onSelect: {
                                        selectedType = type
                                        HapticManager.shared.lightImpact()
                                    }
                                )
                            }
                        }
                    }
                    
                    // Size Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Widget Size")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        HStack(spacing: 12) {
                            ForEach(selectedType.supportedSizes) { size in
                                SizeOption(
                                    size: size,
                                    isSelected: selectedSize == size,
                                    onSelect: {
                                        selectedSize = size
                                        HapticManager.shared.lightImpact()
                                    }
                                )
                            }
                        }
                    }
                    
                    // Create Button
                    Button(action: {
                        onCreateProject(selectedType, selectedSize, nil)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Widget")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    .buttonStyle(TilePressStyle())
                }
                .padding(20)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("New Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

struct WidgetTypeOption: View {
    let type: BibleWidgetType
    let isSelected: Bool
    let onSelect: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(type.color.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(type.color)
                }
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? type.color.opacity(0.1) : themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SizeOption: View {
    let size: WidgetSize
    let isSelected: Bool
    let onSelect: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                sizeVisualization
                
                VStack(spacing: 2) {
                    Text(size.displayName)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(size.gridDescription)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var sizeVisualization: some View {
        switch size {
        case .small:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.4 : 0.2))
                .frame(width: 24, height: 24)
        case .medium:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.4 : 0.2))
                .frame(width: 48, height: 24)
        case .large:
            RoundedRectangle(cornerRadius: 4)
                .fill(themeManager.accentColor.opacity(isSelected ? 0.4 : 0.2))
                .frame(width: 48, height: 48)
        }
    }
}

#Preview {
    WidgetStudioView()
}


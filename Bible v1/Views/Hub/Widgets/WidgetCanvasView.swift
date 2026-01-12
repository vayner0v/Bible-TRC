//
//  WidgetCanvasView.swift
//  Bible v1
//
//  Layer-based canvas editor for widget customization
//

import SwiftUI

/// Canvas-based widget editor with layer management
struct WidgetCanvasView: View {
    @State var project: WidgetProject
    let onSave: (WidgetProject) -> Void
    let onCancel: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Editor state
    @State private var selectedLayerId: UUID?
    @State private var showingLayerPanel = false
    @State private var showingElementPicker = false
    @State private var showingStyleInspector = false
    @State private var showingBackgroundPicker = false
    @State private var showingSaveSuccess = false
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero
    @State private var editorTab: EditorTab = .layers
    @State private var hasUnsavedChanges = false
    @State private var showingDiscardAlert = false
    
    private enum EditorTab: String, CaseIterable {
        case layers = "Layers"
        case background = "Background"
        case effects = "Effects"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                themeManager.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Canvas preview area
                    canvasArea
                    
                    // Bottom toolbar
                    bottomToolbar
                    
                    // Editor panel
                    editorPanel
                }
            }
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingDiscardAlert = true
                        } else {
                            onCancel()
                        }
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        performSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .overlay(saveSuccessOverlay)
            .sheet(isPresented: $showingElementPicker) {
                ElementPickerSheet(
                    onAddElement: { element in
                        let name = WidgetLayer.autoName(for: element)
                        let layer = WidgetLayer(
                            name: name,
                            element: element,
                            frame: LayerFrame.centered
                        )
                        project.addLayer(layer)
                        selectedLayerId = layer.id
                        hasUnsavedChanges = true
                        showingElementPicker = false
                    }
                )
            }
            .sheet(isPresented: $showingStyleInspector) {
                if let layerId = selectedLayerId,
                   let layerIndex = project.layers.firstIndex(where: { $0.id == layerId }) {
                    StyleInspectorView(
                        layer: $project.layers[layerIndex],
                        onUpdate: {
                            hasUnsavedChanges = true
                        }
                    )
                }
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    onCancel()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
        }
    }
    
    // MARK: - Canvas Area
    
    private var canvasArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Checkered background pattern
                CheckeredPattern()
                    .opacity(0.3)
                
                // Canvas with widget preview
                widgetPreview
                    .scaleEffect(canvasScale)
                    .offset(canvasOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                canvasScale = value.magnitude
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                canvasOffset = value.translation
                            }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var widgetPreview: some View {
        let size = project.size.previewSize
        let scale: CGFloat = min(
            (UIScreen.main.bounds.width - 60) / size.width,
            240 / size.height
        )
        let scaledWidth = size.width * scale
        let scaledHeight = size.height * scale
        
        return ZStack(alignment: .topLeading) {
            // Background
            backgroundView
                .frame(width: scaledWidth, height: scaledHeight)
            
            // Layers container - uses top-left origin
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(width: scaledWidth, height: scaledHeight)
                
                ForEach(project.sortedLayers) { layer in
                    if layer.isVisible {
                        LayerView(
                            layer: layer,
                            widgetSize: size,
                            scaleFactor: scale,
                            isSelected: selectedLayerId == layer.id,
                            onTap: {
                                selectedLayerId = layer.id
                                HapticManager.shared.lightImpact()
                            },
                            onDrag: { newFrame in
                                if let index = project.layers.firstIndex(where: { $0.id == layer.id }) {
                                    project.layers[index].frame = newFrame
                                    hasUnsavedChanges = true
                                }
                            }
                        )
                    }
                }
            }
        }
        .frame(width: scaledWidth, height: scaledHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20 * scale))
        .shadow(color: themeManager.hubShadowColor, radius: 20, y: 10)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch project.background {
        case .solid(let fill):
            fill.color.color.opacity(fill.opacity)
            
        case .gradient(let fill):
            gradientView(for: fill)
            
        case .image(let fill):
            EnhancedImageBackgroundView(
                config: EnhancedImageBackground(
                    imageId: fill.imageId,
                    contentMode: WidgetImageContentMode(rawValue: fill.contentMode.rawValue) ?? .fill,
                    blurRadius: fill.blurRadius,
                    overlayColor: fill.overlayColor,
                    overlayOpacity: fill.overlayOpacity,
                    brightness: fill.brightness,
                    saturation: fill.saturation,
                    opacity: 1.0
                ),
                size: project.size.previewSize
            )
            
        case .glassmorphism(let fill):
            GlassmorphismBackgroundView(
                config: EnhancedGlassmorphismBackground(
                    preset: WidgetGlassmorphismPreset(rawValue: fill.preset.rawValue) ?? .lightGlass,
                    blurRadius: fill.blurRadius,
                    tintColor: fill.tintColor,
                    tintOpacity: fill.tintOpacity,
                    noiseOpacity: fill.noiseOpacity
                )
            )
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            // Zoom controls
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        canvasScale = max(0.5, canvasScale - 0.25)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.textColor)
                }
                
                Text("\(Int(canvasScale * 100))%")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(width: 44)
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        canvasScale = min(2.0, canvasScale + 0.25)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.textColor)
                }
            }
            
            Spacer()
            
            // Reset view
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    canvasScale = 1.0
                    canvasOffset = .zero
                }
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textColor)
            }
            
            Spacer()
            
            // Add element button
            Button(action: {
                showingElementPicker = true
                HapticManager.shared.mediumImpact()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(themeManager.accentColor)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(themeManager.cardBackgroundColor)
    }
    
    // MARK: - Editor Panel
    
    private var editorPanel: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(EditorTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            editorTab = tab
                        }
                    }) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(editorTab == tab ? .semibold : .regular)
                            .foregroundColor(editorTab == tab ? themeManager.accentColor : themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            .background(themeManager.cardBackgroundColor)
            .overlay(
                // Tab indicator
                GeometryReader { geo in
                    let tabWidth = geo.size.width / CGFloat(EditorTab.allCases.count)
                    let tabIndex = CGFloat(EditorTab.allCases.firstIndex(of: editorTab) ?? 0)
                    
                    Rectangle()
                        .fill(themeManager.accentColor)
                        .frame(width: tabWidth - 32, height: 3)
                        .cornerRadius(1.5)
                        .offset(x: tabWidth * tabIndex + 16, y: geo.size.height - 3)
                }
            )
            
            // Tab content
            ScrollView {
                switch editorTab {
                case .layers:
                    layersContent
                case .background:
                    backgroundContent
                case .effects:
                    effectsContent
                }
            }
            .frame(height: 200)
            .background(themeManager.backgroundColor)
        }
    }
    
    // MARK: - Layers Content
    
    private var layersContent: some View {
        VStack(spacing: 12) {
            if project.layers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 32))
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                    
                    Text("No Layers")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Button("Add Element") {
                        showingElementPicker = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(project.sortedLayers.reversed()) { layer in
                    LayerListItem(
                        layer: layer,
                        isSelected: selectedLayerId == layer.id,
                        onSelect: {
                            selectedLayerId = layer.id
                        },
                        onToggleVisibility: {
                            if let index = project.layers.firstIndex(where: { $0.id == layer.id }) {
                                project.layers[index].isVisible.toggle()
                                hasUnsavedChanges = true
                            }
                        },
                        onEdit: {
                            selectedLayerId = layer.id
                            showingStyleInspector = true
                        },
                        onDuplicate: {
                            duplicateLayer(layer)
                        },
                        onDelete: {
                            project.removeLayer(id: layer.id)
                            if selectedLayerId == layer.id {
                                selectedLayerId = nil
                            }
                            hasUnsavedChanges = true
                        }
                    )
                }
            }
        }
        .padding(16)
    }
    
    // MARK: - Save Actions
    
    private func performSave() {
        // Show success animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showingSaveSuccess = true
        }
        
        HapticManager.shared.success()
        
        // Dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                showingSaveSuccess = false
            }
            onSave(project)
        }
    }
    
    @ViewBuilder
    private var saveSuccessOverlay: some View {
        if showingSaveSuccess {
            ZStack {
                // Background blur
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Success card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(showingSaveSuccess ? 1.0 : 0.5)
                    .opacity(showingSaveSuccess ? 1.0 : 0)
                    
                    Text("Widget Saved!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)
                    
                    Text("Your widget is ready to use")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
                )
                .scaleEffect(showingSaveSuccess ? 1.0 : 0.8)
                .opacity(showingSaveSuccess ? 1.0 : 0)
            }
            .transition(.opacity)
        }
    }
    
    // MARK: - Layer Actions
    
    private func duplicateLayer(_ layer: WidgetLayer) {
        // Offset the duplicate slightly so it's visible
        let offsetX = min(layer.frame.x + 5, 100 - layer.frame.width)
        let offsetY = min(layer.frame.y + 5, 100 - layer.frame.height)
        let newZIndex = (project.layers.map { $0.zIndex }.max() ?? 0) + 1
        
        let duplicate = WidgetLayer(
            id: UUID(),
            name: "\(layer.name) Copy",
            element: layer.element,
            frame: LayerFrame(
                x: offsetX,
                y: offsetY,
                width: layer.frame.width,
                height: layer.frame.height,
                rotation: layer.frame.rotation
            ),
            style: layer.style,
            zIndex: newZIndex,
            isVisible: layer.isVisible,
            isLocked: layer.isLocked,
            opacity: layer.opacity,
            blendMode: layer.blendMode
        )
        
        project.layers.append(duplicate)
        selectedLayerId = duplicate.id
        hasUnsavedChanges = true
        HapticManager.shared.lightImpact()
    }
    
    // MARK: - Background Content
    
    private var backgroundContent: some View {
        VStack(spacing: 16) {
            // Background type selector
            HStack(spacing: 8) {
                BackgroundTypeButton(
                    icon: "circle.fill",
                    title: "Solid",
                    isSelected: isSolidBackground,
                    action: {
                        project.background = .solid(SolidFill(color: CodableColor(color: .white)))
                        hasUnsavedChanges = true
                    }
                )
                
                BackgroundTypeButton(
                    icon: "paintpalette.fill",
                    title: "Gradient",
                    isSelected: isGradientBackground,
                    action: {
                        project.background = .gradient(GradientFill())
                        hasUnsavedChanges = true
                    }
                )
                
                BackgroundTypeButton(
                    icon: "photo.fill",
                    title: "Photo",
                    isSelected: isImageBackground,
                    action: {
                        showingBackgroundPicker = true
                    }
                )
                
                BackgroundTypeButton(
                    icon: "rectangle.on.rectangle",
                    title: "Glass",
                    isSelected: isGlassBackground,
                    action: {
                        project.background = .glassmorphism(GlassmorphismPreset.lightGlass.defaultConfig)
                        hasUnsavedChanges = true
                    }
                )
            }
            
            // Background-specific controls
            backgroundControls
        }
        .padding(16)
        .sheet(isPresented: $showingBackgroundPicker) {
            WidgetPhotoPicker { photo in
                project.background = .image(ImageFill(imageId: photo.id))
                hasUnsavedChanges = true
            }
        }
    }
    
    @ViewBuilder
    private var backgroundControls: some View {
        switch project.background {
        case .solid(let fill):
            SolidBackgroundControls(
                fill: fill,
                onChange: { newFill in
                    project.background = .solid(newFill)
                    hasUnsavedChanges = true
                }
            )
            
        case .gradient(let fill):
            GradientBackgroundControls(
                fill: fill,
                onChange: { newFill in
                    project.background = .gradient(newFill)
                    hasUnsavedChanges = true
                }
            )
            
        case .glassmorphism(let fill):
            GlassBackgroundControls(
                fill: fill,
                onChange: { newFill in
                    project.background = .glassmorphism(newFill)
                    hasUnsavedChanges = true
                }
            )
            
        case .image:
            Text("Tap to change photo")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Effects Content
    
    private var effectsContent: some View {
        VStack(spacing: 16) {
            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(themeManager.secondaryTextColor)
            
            Text("Shadow, blur, and blend mode effects will be available in a future update.")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
    
    // MARK: - Helpers
    
    private var isSolidBackground: Bool {
        if case .solid = project.background { return true }
        return false
    }
    
    private var isGradientBackground: Bool {
        if case .gradient = project.background { return true }
        return false
    }
    
    private var isImageBackground: Bool {
        if case .image = project.background { return true }
        return false
    }
    
    private var isGlassBackground: Bool {
        if case .glassmorphism = project.background { return true }
        return false
    }
    
    // MARK: - Gradient Helper
    
    @ViewBuilder
    private func gradientView(for gradient: GradientFill) -> some View {
        switch gradient.type {
        case .linear:
            LinearGradient(
                gradient: Gradient(stops: gradient.gradientStops),
                startPoint: gradient.startPoint.unitPoint,
                endPoint: gradient.endPoint.unitPoint
            )
        case .radial:
            RadialGradient(
                gradient: Gradient(stops: gradient.gradientStops),
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
        case .angular:
            AngularGradient(
                gradient: Gradient(stops: gradient.gradientStops),
                center: .center,
                angle: .degrees(gradient.angle)
            )
        }
    }
}

// MARK: - Layer View

struct LayerView: View {
    let layer: WidgetLayer
    let widgetSize: CGSize
    let scaleFactor: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (LayerFrame) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        let frame = layer.frame
        // Calculate the scaled dimensions
        let scaledWidth = widgetSize.width * scaleFactor
        let scaledHeight = widgetSize.height * scaleFactor
        
        // Calculate position and size in scaled coordinates
        let layerX = scaledWidth * frame.x / 100
        let layerY = scaledHeight * frame.y / 100
        let layerWidth = scaledWidth * frame.width / 100
        let layerHeight = scaledHeight * frame.height / 100
        
        ZStack(alignment: .topLeading) {
            // Layer content
            layerContent
                .frame(width: layerWidth, height: layerHeight)
                .clipped()
                .opacity(layer.opacity)
                .rotationEffect(.degrees(frame.rotation))
                .blendMode(layer.blendMode.swiftUIBlendMode)
                .overlay(
                    isSelected ? selectionOverlay(width: layerWidth, height: layerHeight) : nil
                )
        }
        .offset(
            x: layerX + dragOffset.width,
            y: layerY + dragOffset.height
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .gesture(
            layer.isLocked ? nil : DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    // Calculate new position in percentages, accounting for scale
                    let deltaX = value.translation.width / scaledWidth * 100
                    let deltaY = value.translation.height / scaledHeight * 100
                    
                    let newX = frame.x + deltaX
                    let newY = frame.y + deltaY
                    
                    let newFrame = LayerFrame(
                        x: max(0, min(100 - frame.width, newX)),
                        y: max(0, min(100 - frame.height, newY)),
                        width: frame.width,
                        height: frame.height,
                        rotation: frame.rotation
                    )
                    
                    onDrag(newFrame)
                    dragOffset = .zero
                    HapticManager.shared.lightImpact()
                }
        )
    }
    
    @ViewBuilder
    private var layerContent: some View {
        switch layer.element {
        case .text(let config):
            Text(config.text)
                .font(WidgetFontRegistry.shared.font(withId: config.fontId)?.font(
                    size: config.fontSize,
                    weight: config.fontWeight.fontWeight
                ) ?? .system(size: config.fontSize))
                .foregroundColor(config.textColor.color)
                .multilineTextAlignment(config.alignment.alignment)
            
        case .icon(let config):
            Image(systemName: config.symbolName)
                .font(.system(size: config.size, weight: config.weight.fontWeight))
                .foregroundColor(config.primaryColor.color)
            
        case .shape(let config):
            shapeView(for: config)
            
        case .image(let config):
            imageView(for: config)
            
        case .dataBinding(let config):
            // Placeholder for data binding
            Text(placeholderText(for: config.dataType))
                .font(WidgetFontRegistry.shared.font(withId: config.textStyle.fontId)?.font(
                    size: config.textStyle.fontSize,
                    weight: config.textStyle.fontWeight.fontWeight
                ) ?? .system(size: config.textStyle.fontSize))
                .foregroundColor(config.textStyle.textColor.color)
                .multilineTextAlignment(config.textStyle.alignment.alignment)
        }
    }
    
    @ViewBuilder
    private func shapeView(for config: ShapeElementConfig) -> some View {
        let shape = shapeForType(config.type)
        
        Group {
            switch config.fill {
            case .none:
                shape.stroke(Color.clear)
            case .solid(let color):
                shape.fill(color.color)
            case .gradient(let gradient):
                shape.fill(
                    LinearGradient(
                        gradient: Gradient(stops: gradient.gradientStops),
                        startPoint: gradient.startPoint.unitPoint,
                        endPoint: gradient.endPoint.unitPoint
                    )
                )
            }
        }
    }
    
    private func shapeForType(_ type: ShapeType) -> AnyShape {
        switch type {
        case .rectangle:
            return AnyShape(Rectangle())
        case .circle:
            return AnyShape(Circle())
        case .ellipse:
            return AnyShape(Ellipse())
        case .roundedRectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 12))
        case .capsule:
            return AnyShape(Capsule())
        default:
            return AnyShape(Rectangle())
        }
    }
    
    @ViewBuilder
    private func imageView(for config: ImageElementConfig) -> some View {
        AsyncImage(url: WidgetPhotoService.shared.getImageURL(for: config.imageId)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: config.contentMode == .fill ? .fill : .fit)
        } placeholder: {
            themeManager.secondaryTextColor.opacity(0.2)
        }
        .cornerRadius(config.cornerRadius)
    }
    
    private func placeholderText(for dataType: WidgetDataType) -> String {
        switch dataType {
        case .verseText:
            return "\"For God so loved the world that he gave his one and only Son...\""
        case .verseReference:
            return "John 3:16"
        case .readingProgress:
            return "45%"
        case .readingStreak:
            return "7 days"
        case .currentDate:
            return "January 3, 2026"
        case .currentTime:
            return "10:30 AM"
        default:
            return dataType.displayName
        }
    }
    
    private func selectionOverlay(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Selection border
            RoundedRectangle(cornerRadius: 4)
                .stroke(themeManager.accentColor, lineWidth: 2)
                .frame(width: width, height: height)
            
            // Corner handles
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(themeManager.cardBackgroundColor)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(themeManager.accentColor, lineWidth: 2))
                    .offset(
                        x: i % 2 == 0 ? -width / 2 : width / 2,
                        y: i < 2 ? -height / 2 : height / 2
                    )
            }
        }
    }
}

// MARK: - Layer List Item

struct LayerListItem: View {
    let layer: WidgetLayer
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Layer type icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: layer.element.elementType.systemIcon)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.accentColor)
            }
            
            // Layer name
            VStack(alignment: .leading, spacing: 2) {
                Text(layer.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                
                Text(layer.element.elementType.displayName)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onToggleVisibility) {
                    Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.caption)
                        .foregroundColor(layer.isVisible ? themeManager.accentColor : themeManager.secondaryTextColor)
                }
                
                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(themeManager.textColor)
                }
                
                Button(action: onDuplicate) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(themeManager.textColor)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Background Controls

struct BackgroundTypeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? themeManager.accentColor.opacity(0.15) : themeManager.cardBackgroundColor)
            )
        }
    }
}

struct SolidBackgroundControls: View {
    let fill: SolidFill
    let onChange: (SolidFill) -> Void
    
    @State private var showingColorPicker = false
    
    var body: some View {
        HStack(spacing: 16) {
            Text("Color")
                .font(.subheadline)
            
            Spacer()
            
            ColorPicker("", selection: Binding(
                get: { fill.color.color },
                set: { onChange(SolidFill(color: CodableColor(color: $0), opacity: fill.opacity)) }
            ))
            .labelsHidden()
        }
    }
}

struct GradientBackgroundControls: View {
    let fill: GradientFill
    let onChange: (GradientFill) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Gradient type
            HStack(spacing: 8) {
                ForEach(GradientType.allCases, id: \.self) { type in
                    Button(action: {
                        var newFill = fill
                        newFill.type = type
                        onChange(newFill)
                    }) {
                        Text(type.displayName)
                            .font(.caption)
                            .fontWeight(fill.type == type ? .semibold : .regular)
                            .foregroundColor(fill.type == type ? .white : themeManager.textColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(fill.type == type ? themeManager.accentColor : themeManager.cardBackgroundColor)
                            )
                    }
                }
            }
            
            // Color stops preview
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: fill.gradientStops),
                        startPoint: fill.startPoint.unitPoint,
                        endPoint: fill.endPoint.unitPoint
                    )
                )
                .frame(height: 32)
        }
    }
}

struct GlassBackgroundControls: View {
    let fill: GlassmorphismFill
    let onChange: (GlassmorphismFill) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Preset buttons
            HStack(spacing: 8) {
                ForEach(GlassmorphismPreset.allCases, id: \.self) { preset in
                    Button(action: {
                        onChange(preset.defaultConfig)
                    }) {
                        Text(preset.displayName)
                            .font(.caption2)
                            .fontWeight(fill.preset == preset ? .semibold : .regular)
                            .foregroundColor(fill.preset == preset ? .white : themeManager.textColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(fill.preset == preset ? themeManager.accentColor : themeManager.cardBackgroundColor)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Checkered Pattern

struct CheckeredPattern: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 10
            
            for row in 0..<Int(size.height / tileSize) + 1 {
                for col in 0..<Int(size.width / tileSize) + 1 {
                    if (row + col) % 2 == 0 {
                        context.fill(
                            Path(CGRect(
                                x: CGFloat(col) * tileSize,
                                y: CGFloat(row) * tileSize,
                                width: tileSize,
                                height: tileSize
                            )),
                            with: .color(themeManager.secondaryTextColor.opacity(0.08))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WidgetCanvasView(
        project: WidgetProject(
            name: "Test Widget",
            widgetType: .verseOfDay,
            size: .medium
        ),
        onSave: { _ in },
        onCancel: { }
    )
}


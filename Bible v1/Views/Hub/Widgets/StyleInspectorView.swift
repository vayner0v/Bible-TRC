//
//  StyleInspectorView.swift
//  Bible v1
//
//  Contextual style editing panel for widget layers
//

import SwiftUI

/// Style inspector for editing layer properties
struct StyleInspectorView: View {
    @Binding var layer: WidgetLayer
    let onUpdate: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: InspectorTab = .style
    @State private var showingFontPicker = false
    @State private var showingColorPicker = false
    @State private var colorPickerBinding: Binding<Color>?
    @State private var showingSymbolPicker = false
    @State private var symbolPickerCallback: ((String) -> Void)?
    
    private enum InspectorTab: String, CaseIterable {
        case style = "Style"
        case typography = "Typography"
        case effects = "Effects"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar
                tabBar
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .style:
                            styleContent
                        case .typography:
                            typographyContent
                        case .effects:
                            effectsContent
                        }
                    }
                    .padding(16)
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Edit: \(layer.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .sheet(isPresented: $showingFontPicker) {
                fontPickerSheet
            }
            .sheet(isPresented: $showingSymbolPicker) {
                SFSymbolPicker { selectedSymbol in
                    symbolPickerCallback?(selectedSymbol)
                    showingSymbolPicker = false
                }
            }
        }
    }
    
    // MARK: - Tab Bar
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedTab == tab ? .semibold : .regular)
                        .foregroundColor(selectedTab == tab ? themeManager.accentColor : themeManager.secondaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .background(themeManager.cardBackgroundColor)
    }
    
    private var availableTabs: [InspectorTab] {
        switch layer.element {
        case .text, .dataBinding:
            return InspectorTab.allCases
        case .icon:
            return [.style, .effects]
        case .shape:
            return [.style, .effects]
        case .image:
            return [.style, .effects]
        }
    }
    
    // MARK: - Style Content
    
    @ViewBuilder
    private var styleContent: some View {
        // Layer name
        InspectorSection(title: "Layer") {
            HStack {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                TextField("Layer Name", text: $layer.name)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: layer.name) { _, _ in onUpdate() }
            }
        }
        
        // Element-specific style
        switch layer.element {
        case .text(let config):
            textStyleSection(config: config) { newConfig in
                layer.element = .text(newConfig)
                onUpdate()
            }
            
        case .icon(let config):
            iconStyleSection(config: config) { newConfig in
                layer.element = .icon(newConfig)
                onUpdate()
            }
            
        case .shape(let config):
            shapeStyleSection(config: config) { newConfig in
                layer.element = .shape(newConfig)
                onUpdate()
            }
            
        case .dataBinding(let config):
            dataBindingStyleSection(config: config) { newConfig in
                layer.element = .dataBinding(newConfig)
                onUpdate()
            }
            
        case .image(let config):
            imageStyleSection(config: config) { newConfig in
                layer.element = .image(newConfig)
                onUpdate()
            }
        }
        
        // Position & Size
        positionSection
    }
    
    // MARK: - Typography Content
    
    @ViewBuilder
    private var typographyContent: some View {
        switch layer.element {
        case .text(let config):
            textTypographySection(config: config) { newConfig in
                layer.element = .text(newConfig)
                onUpdate()
            }
            
        case .dataBinding(var config):
            textTypographySection(config: config.textStyle) { newStyle in
                config.textStyle = newStyle
                layer.element = .dataBinding(config)
                onUpdate()
            }
            
        default:
            Text("Typography not available for this element type")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Effects Content
    
    private var effectsContent: some View {
        VStack(spacing: 16) {
            // Opacity
            InspectorSection(title: "Opacity") {
                VStack(spacing: 8) {
                    Slider(value: $layer.opacity, in: 0...1, step: 0.05)
                        .accentColor(themeManager.accentColor)
                        .onChange(of: layer.opacity) { _, _ in onUpdate() }
                    
                    Text("\(Int(layer.opacity * 100))%")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Blend Mode
            InspectorSection(title: "Blend Mode") {
                Picker("Blend Mode", selection: $layer.blendMode) {
                    ForEach(LayerBlendMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: layer.blendMode) { _, _ in onUpdate() }
            }
            
            // Rotation
            InspectorSection(title: "Rotation") {
                VStack(spacing: 8) {
                    Slider(value: $layer.frame.rotation, in: -180...180, step: 1)
                        .accentColor(themeManager.accentColor)
                        .onChange(of: layer.frame.rotation) { _, _ in onUpdate() }
                    
                    Text("\(Int(layer.frame.rotation))°")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            // Lock toggle
            InspectorSection(title: "Lock Layer") {
                Toggle("Locked", isOn: $layer.isLocked)
                    .onChange(of: layer.isLocked) { _, _ in onUpdate() }
            }
        }
    }
    
    // MARK: - Position Section
    
    private var positionSection: some View {
        InspectorSection(title: "Position & Size") {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("X")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        TextField("X", value: $layer.frame.x, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: layer.frame.x) { _, _ in onUpdate() }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Y")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        TextField("Y", value: $layer.frame.y, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: layer.frame.y) { _, _ in onUpdate() }
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Width %")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        TextField("Width", value: $layer.frame.width, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: layer.frame.width) { _, _ in onUpdate() }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Height %")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        TextField("Height", value: $layer.frame.height, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: layer.frame.height) { _, _ in onUpdate() }
                    }
                }
            }
        }
    }
    
    // MARK: - Text Style Section
    
    private func textStyleSection(config: TextElementConfig, onChange: @escaping (TextElementConfig) -> Void) -> some View {
        InspectorSection(title: "Text") {
            TextEditor(text: Binding(
                get: { config.text },
                set: { newValue in
                    var newConfig = config
                    newConfig.text = newValue
                    onChange(newConfig)
                }
            ))
            .font(.subheadline)
            .foregroundColor(themeManager.textColor)
            .frame(height: 80)
            .padding(8)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(8)
        }
    }
    
    private func textTypographySection(config: TextElementConfig, onChange: @escaping (TextElementConfig) -> Void) -> some View {
        VStack(spacing: 16) {
            // Font
            InspectorSection(title: "Font") {
                Button(action: {
                    showingFontPicker = true
                }) {
                    HStack {
                        Text(WidgetFontRegistry.shared.font(withId: config.fontId)?.displayName ?? "System")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    .padding(12)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(8)
                }
            }
            
            // Font Size
            InspectorSection(title: "Size") {
                HStack {
                    Slider(value: Binding(
                        get: { config.fontSize },
                        set: { newValue in
                            var newConfig = config
                            newConfig.fontSize = newValue
                            onChange(newConfig)
                        }
                    ), in: 8...48, step: 1)
                    .accentColor(themeManager.accentColor)
                    
                    Text("\(Int(config.fontSize))pt")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 40)
                }
            }
            
            // Font Weight
            InspectorSection(title: "Weight") {
                Picker("Weight", selection: Binding(
                    get: { config.fontWeight },
                    set: { newValue in
                        var newConfig = config
                        newConfig.fontWeight = newValue
                        onChange(newConfig)
                    }
                )) {
                    ForEach(WidgetFontWeight.allCases, id: \.self) { weight in
                        Text(weight.displayName).tag(weight)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Text Color
            InspectorSection(title: "Color") {
                ColorPicker("Text Color", selection: Binding(
                    get: { config.textColor.color },
                    set: { newColor in
                        var newConfig = config
                        newConfig.textColor = CodableColor(color: newColor)
                        onChange(newConfig)
                    }
                ))
                .labelsHidden()
            }
            
            // Alignment
            InspectorSection(title: "Alignment") {
                Picker("Alignment", selection: Binding(
                    get: { config.alignment },
                    set: { newValue in
                        var newConfig = config
                        newConfig.alignment = newValue
                        onChange(newConfig)
                    }
                )) {
                    Image(systemName: "text.alignleft").tag(WidgetTextAlignment.leading)
                    Image(systemName: "text.aligncenter").tag(WidgetTextAlignment.center)
                    Image(systemName: "text.alignright").tag(WidgetTextAlignment.trailing)
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    // MARK: - Icon Style Section
    
    private func iconStyleSection(config: IconElementConfig, onChange: @escaping (IconElementConfig) -> Void) -> some View {
        VStack(spacing: 16) {
            // Symbol preview
            InspectorSection(title: "Symbol") {
                HStack {
                    Image(systemName: config.symbolName)
                        .font(.system(size: 28))
                        .foregroundColor(config.primaryColor.color)
                        .frame(width: 50, height: 50)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(10)
                    
                    Text(config.symbolName)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                    
                    Spacer()
                    
                    Button("Change") {
                        symbolPickerCallback = { newSymbol in
                            var updated = config
                            updated.symbolName = newSymbol
                            onChange(updated)
                        }
                        showingSymbolPicker = true
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.accentColor)
                }
            }
            
            // Size
            InspectorSection(title: "Size") {
                HStack {
                    Slider(value: Binding(
                        get: { config.size },
                        set: { newValue in
                            var newConfig = config
                            newConfig.size = newValue
                            onChange(newConfig)
                        }
                    ), in: 12...64, step: 1)
                    .accentColor(themeManager.accentColor)
                    
                    Text("\(Int(config.size))pt")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 40)
                }
            }
            
            // Color
            InspectorSection(title: "Color") {
                ColorPicker("Icon Color", selection: Binding(
                    get: { config.primaryColor.color },
                    set: { newColor in
                        var newConfig = config
                        newConfig.primaryColor = CodableColor(color: newColor)
                        onChange(newConfig)
                    }
                ))
                .labelsHidden()
            }
        }
    }
    
    // MARK: - Shape Style Section
    
    private func shapeStyleSection(config: ShapeElementConfig, onChange: @escaping (ShapeElementConfig) -> Void) -> some View {
        VStack(spacing: 16) {
            // Shape type
            InspectorSection(title: "Shape") {
                Picker("Shape", selection: Binding(
                    get: { config.type },
                    set: { newValue in
                        var newConfig = config
                        newConfig.type = newValue
                        onChange(newConfig)
                    }
                )) {
                    ForEach(ShapeType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Fill
            InspectorSection(title: "Fill") {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        fillTypeButton("None", isSelected: isNoFill(config.fill)) {
                            var newConfig = config
                            newConfig.fill = .none
                            onChange(newConfig)
                        }
                        fillTypeButton("Solid", isSelected: isSolidFill(config.fill)) {
                            var newConfig = config
                            newConfig.fill = .solid(CodableColor(color: .blue))
                            onChange(newConfig)
                        }
                        fillTypeButton("Gradient", isSelected: isGradientFill(config.fill)) {
                            var newConfig = config
                            newConfig.fill = .gradient(GradientFill())
                            onChange(newConfig)
                        }
                    }
                    
                    if case .solid(let color) = config.fill {
                        ColorPicker("Fill Color", selection: Binding(
                            get: { color.color },
                            set: { newColor in
                                var newConfig = config
                                newConfig.fill = .solid(CodableColor(color: newColor))
                                onChange(newConfig)
                            }
                        ))
                        .labelsHidden()
                    }
                }
            }
        }
    }
    
    private func fillTypeButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : themeManager.textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                )
        }
    }
    
    private func isNoFill(_ fill: ShapeFill) -> Bool {
        if case .none = fill { return true }
        return false
    }
    
    private func isSolidFill(_ fill: ShapeFill) -> Bool {
        if case .solid = fill { return true }
        return false
    }
    
    private func isGradientFill(_ fill: ShapeFill) -> Bool {
        if case .gradient = fill { return true }
        return false
    }
    
    // MARK: - Data Binding Style Section
    
    private func dataBindingStyleSection(config: DataBindingConfig, onChange: @escaping (DataBindingConfig) -> Void) -> some View {
        VStack(spacing: 16) {
            // Data type
            InspectorSection(title: "Data Source") {
                Picker("Data Type", selection: Binding(
                    get: { config.dataType },
                    set: { newValue in
                        var newConfig = config
                        newConfig.dataType = newValue
                        onChange(newConfig)
                    }
                )) {
                    ForEach(WidgetDataType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Prefix/Suffix
            InspectorSection(title: "Formatting") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Prefix")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("", text: Binding(
                            get: { config.prefix },
                            set: { newValue in
                                var newConfig = config
                                newConfig.prefix = newValue
                                onChange(newConfig)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Suffix")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("", text: Binding(
                            get: { config.suffix },
                            set: { newValue in
                                var newConfig = config
                                newConfig.suffix = newValue
                                onChange(newConfig)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Image Style Section
    
    private func imageStyleSection(config: ImageElementConfig, onChange: @escaping (ImageElementConfig) -> Void) -> some View {
        VStack(spacing: 16) {
            // Content mode
            InspectorSection(title: "Content Mode") {
                Picker("Mode", selection: Binding(
                    get: { config.contentMode },
                    set: { newValue in
                        var newConfig = config
                        newConfig.contentMode = newValue
                        onChange(newConfig)
                    }
                )) {
                    ForEach(ImageContentMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Corner radius
            InspectorSection(title: "Corner Radius") {
                HStack {
                    Slider(value: Binding(
                        get: { config.cornerRadius },
                        set: { newValue in
                            var newConfig = config
                            newConfig.cornerRadius = newValue
                            onChange(newConfig)
                        }
                    ), in: 0...40, step: 1)
                    .accentColor(themeManager.accentColor)
                    
                    Text("\(Int(config.cornerRadius))")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 30)
                }
            }
            
            // Blur
            InspectorSection(title: "Blur") {
                HStack {
                    Slider(value: Binding(
                        get: { config.blurRadius },
                        set: { newValue in
                            var newConfig = config
                            newConfig.blurRadius = newValue
                            onChange(newConfig)
                        }
                    ), in: 0...20, step: 0.5)
                    .accentColor(themeManager.accentColor)
                    
                    Text("\(config.blurRadius, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .frame(width: 30)
                }
            }
        }
    }
    
    // MARK: - Font Picker Sheet
    
    private var fontPickerSheet: some View {
        NavigationStack {
            WidgetFontPicker(
                selectedFontId: Binding(
                    get: {
                        if case .text(let config) = layer.element {
                            return config.fontId
                        } else if case .dataBinding(let config) = layer.element {
                            return config.textStyle.fontId
                        }
                        return "system"
                    },
                    set: { newId in
                        switch layer.element {
                        case .text(var config):
                            config.fontId = newId
                            layer.element = .text(config)
                        case .dataBinding(var config):
                            config.textStyle.fontId = newId
                            layer.element = .dataBinding(config)
                        default:
                            break
                        }
                        onUpdate()
                    }
                ),
                onSelect: { font in
                    showingFontPicker = false
                }
            )
            .navigationTitle("Choose Font")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        showingFontPicker = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Inspector Section

struct InspectorSection<Content: View>: View {
    let title: String
    let content: Content
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .textCase(.uppercase)
            
            content
        }
    }
}

// MARK: - Preview

#Preview {
    StyleInspectorView(
        layer: .constant(WidgetLayer(
            name: "Sample Text",
            element: .text(TextElementConfig(text: "Hello World"))
        )),
        onUpdate: { }
    )
}


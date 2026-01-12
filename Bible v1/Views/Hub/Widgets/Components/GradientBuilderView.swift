//
//  GradientBuilderView.swift
//  Bible v1
//
//  Interactive gradient builder with draggable color stops
//

import SwiftUI

/// Interactive gradient builder component
struct GradientBuilderView: View {
    @Binding var gradient: GradientFill
    let onUpdate: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedStopId: UUID?
    @State private var showingColorPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Gradient type selector
            gradientTypeSelector
            
            // Gradient preview with stops
            gradientPreview
            
            // Color stops list
            colorStopsList
            
            // Preset gradients
            presetGradients
        }
    }
    
    // MARK: - Gradient Type Selector
    
    private var gradientTypeSelector: some View {
        HStack(spacing: 8) {
            ForEach(GradientType.allCases, id: \.self) { type in
                Button(action: {
                    gradient.type = type
                    onUpdate()
                    HapticManager.shared.lightImpact()
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 18))
                        Text(type.displayName)
                            .font(.caption2)
                    }
                    .foregroundColor(gradient.type == type ? .white : themeManager.textColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(gradient.type == type ? themeManager.accentColor : themeManager.cardBackgroundColor)
                    )
                }
            }
        }
    }
    
    // MARK: - Gradient Preview
    
    private var gradientPreview: some View {
        ZStack {
            // Gradient
            RoundedRectangle(cornerRadius: 12)
                .fill(gradientShapeStyle)
                .frame(height: 80)
            
            // Stop indicators on the gradient bar
            GeometryReader { geometry in
                ForEach(gradient.stops) { stop in
                    stopIndicator(for: stop, in: geometry)
                }
            }
            .frame(height: 80)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.secondaryTextColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var gradientShapeStyle: some ShapeStyle {
        switch gradient.type {
        case .linear:
            return AnyShapeStyle(LinearGradient(
                gradient: Gradient(stops: gradient.gradientStops),
                startPoint: gradient.startPoint.unitPoint,
                endPoint: gradient.endPoint.unitPoint
            ))
        case .radial:
            return AnyShapeStyle(RadialGradient(
                gradient: Gradient(stops: gradient.gradientStops),
                center: .center,
                startRadius: 0,
                endRadius: 100
            ))
        case .angular:
            return AnyShapeStyle(AngularGradient(
                gradient: Gradient(stops: gradient.gradientStops),
                center: .center,
                angle: .degrees(gradient.angle)
            ))
        }
    }
    
    private func stopIndicator(for stop: GradientStop, in geometry: GeometryProxy) -> some View {
        let isSelected = selectedStopId == stop.id
        let xPosition = geometry.size.width * stop.location
        
        return Circle()
            .fill(stop.color.color)
            .frame(width: isSelected ? 24 : 20, height: isSelected ? 24 : 20)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            )
            .overlay(
                isSelected ? Circle().stroke(themeManager.accentColor, lineWidth: 2) : nil
            )
            .position(x: xPosition, y: geometry.size.height / 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newLocation = max(0, min(1, value.location.x / geometry.size.width))
                        if let index = gradient.stops.firstIndex(where: { $0.id == stop.id }) {
                            gradient.stops[index] = GradientStop(
                                id: stop.id,
                                color: stop.color,
                                location: newLocation
                            )
                        }
                    }
                    .onEnded { _ in
                        onUpdate()
                    }
            )
            .onTapGesture {
                selectedStopId = stop.id
                showingColorPicker = true
                HapticManager.shared.lightImpact()
            }
    }
    
    // MARK: - Color Stops List
    
    private var colorStopsList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Color Stops")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                if gradient.stops.count < 5 {
                    Button(action: addNewStop) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            ForEach(gradient.stops.sorted { $0.location < $1.location }) { stop in
                ColorStopRow(
                    stop: stop,
                    isSelected: selectedStopId == stop.id,
                    canDelete: gradient.stops.count > 2,
                    onSelect: {
                        selectedStopId = stop.id
                    },
                    onColorChange: { newColor in
                        if let index = gradient.stops.firstIndex(where: { $0.id == stop.id }) {
                            gradient.stops[index] = GradientStop(
                                id: stop.id,
                                color: CodableColor(color: newColor),
                                location: stop.location
                            )
                            onUpdate()
                        }
                    },
                    onDelete: {
                        gradient.stops.removeAll { $0.id == stop.id }
                        onUpdate()
                    }
                )
            }
        }
    }
    
    private func addNewStop() {
        // Find a good location for the new stop (midpoint of largest gap)
        let sortedStops = gradient.stops.sorted { $0.location < $1.location }
        var maxGap: Double = 0
        var newLocation: Double = 0.5
        
        for i in 0..<sortedStops.count - 1 {
            let gap = sortedStops[i + 1].location - sortedStops[i].location
            if gap > maxGap {
                maxGap = gap
                newLocation = sortedStops[i].location + gap / 2
            }
        }
        
        // Blend color between neighbors
        let blendedColor = Color.gray
        
        let newStop = GradientStop(
            color: CodableColor(color: blendedColor),
            location: newLocation
        )
        
        gradient.stops.append(newStop)
        selectedStopId = newStop.id
        onUpdate()
        HapticManager.shared.mediumImpact()
    }
    
    // MARK: - Preset Gradients
    
    private var presetGradients: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GradientPreset.presets.prefix(8)) { preset in
                        Button(action: {
                            gradient = preset.fill
                            onUpdate()
                            HapticManager.shared.mediumImpact()
                        }) {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: preset.fill.gradientStops),
                                            startPoint: preset.fill.startPoint.unitPoint,
                                            endPoint: preset.fill.endPoint.unitPoint
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                Text(preset.name)
                                    .font(.caption2)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Color Stop Row

struct ColorStopRow: View {
    let stop: GradientStop
    let isSelected: Bool
    let canDelete: Bool
    let onSelect: () -> Void
    let onColorChange: (Color) -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            ColorPicker("", selection: Binding(
                get: { stop.color.color },
                set: { onColorChange($0) }
            ))
            .labelsHidden()
            .frame(width: 32, height: 32)
            
            // Location
            VStack(alignment: .leading, spacing: 2) {
                Text("Position")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text("\(Int(stop.location * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
            }
            
            Spacer()
            
            // Delete button
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? themeManager.accentColor.opacity(0.1) : themeManager.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? themeManager.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Direction Picker

struct GradientDirectionPicker: View {
    @Binding var startPoint: GradientPoint
    @Binding var endPoint: GradientPoint
    let onUpdate: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let directions: [(String, GradientPoint, GradientPoint)] = [
        ("↓", .top, .bottom),
        ("↗", .bottomLeading, .topTrailing),
        ("→", .leading, .trailing),
        ("↘", .topLeading, .bottomTrailing),
        ("↑", .bottom, .top),
        ("↙", .topTrailing, .bottomLeading),
        ("←", .trailing, .leading),
        ("↖", .bottomTrailing, .topLeading)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Direction")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(directions, id: \.0) { direction, start, end in
                    let isSelected = startPoint == start && endPoint == end
                    
                    Button(action: {
                        startPoint = start
                        endPoint = end
                        onUpdate()
                        HapticManager.shared.lightImpact()
                    }) {
                        Text(direction)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? themeManager.accentColor : themeManager.cardBackgroundColor)
                            )
                            .foregroundColor(isSelected ? .white : themeManager.textColor)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GradientBuilderView(
        gradient: .constant(GradientFill()),
        onUpdate: { }
    )
    .padding()
}


//
//  HubThemedComponents.swift
//  Bible v1
//
//  Shared themed components for Hub sub-views
//

import SwiftUI

// MARK: - Themed Card

/// A theme-aware card container with consistent styling
struct ThemedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(themeManager.hubElevatedSurface)
                    .shadow(
                        color: themeManager.hubShadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// MARK: - Themed Section Header

/// A consistent section header with optional action button
struct ThemedSectionHeader: View {
    let title: String
    var icon: String? = nil
    var iconColor: Color? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(iconColor ?? themeManager.accentColor)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
    }
}

// MARK: - Themed Primary Button

/// A theme-aware primary action button
struct ThemedPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var gradient: [Color]? = nil
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var buttonGradient: LinearGradient {
        if let colors = gradient {
            return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(
            colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(buttonGradient)
            .cornerRadius(14)
        }
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Themed Secondary Button

/// A theme-aware secondary/outline button
struct ThemedSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(themeManager.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(themeManager.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(TilePressStyle())
    }
}

// MARK: - Themed Stat Pill

/// A theme-aware statistics pill with icon and value
struct ThemedStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// MARK: - Themed Input Field

/// A theme-aware text input field
struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(isFocused ? themeManager.accentColor : themeManager.secondaryTextColor)
            }
            
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .focused($isFocused)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? themeManager.accentColor : themeManager.dividerColor,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
    }
}

// MARK: - Themed Text Editor

/// A theme-aware multi-line text editor
struct ThemedTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(themeManager.textColor)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: minHeight)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? themeManager.accentColor : themeManager.dividerColor,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
    }
}

// MARK: - Themed Progress Bar

/// A theme-aware horizontal progress bar
struct ThemedProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var gradient: [Color]? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private var progressGradient: LinearGradient {
        if let colors = gradient {
            return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(
            colors: [themeManager.accentColor, themeManager.hubTileSecondaryColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(themeManager.dividerColor)
                
                Capsule()
                    .fill(progressGradient)
                    .frame(width: max(geo.size.width * progress, 0))
                    .animation(.spring(response: 0.5), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Themed Streak Badge

/// A theme-aware streak badge with flame icon
struct ThemedStreakBadge: View {
    let streak: Int
    var size: BadgeSize = .medium
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    enum BadgeSize {
        case small, medium, large
        
        var iconFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .body
            }
        }
        
        var textFont: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    var body: some View {
        if streak > 0 {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(size.iconFont)
                Text("\(streak)")
                    .font(size.textFont)
                    .fontWeight(.bold)
            }
            .foregroundColor(.orange)
            .padding(.horizontal, size.padding + 2)
            .padding(.vertical, size.padding)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(size == .large ? 12 : 8)
        }
    }
}

// MARK: - Themed Empty State

/// A theme-aware empty state placeholder
struct ThemedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                ThemedSecondaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(32)
    }
}

// MARK: - Themed Divider

/// A theme-aware divider
struct ThemedDivider: View {
    var vertical: Bool = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Rectangle()
            .fill(themeManager.dividerColor)
            .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
    }
}

// MARK: - Glassmorphic Card

/// A floating glass-like card with blur effect - Apple Music inspired
struct GlassmorphicCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 20
    var glowColor: Color = .clear
    var intensity: GlassIntensity = .regular
    
    enum GlassIntensity {
        case subtle, regular, prominent
        
        var material: Material {
            switch self {
            case .subtle: return .ultraThinMaterial
            case .regular: return .thinMaterial
            case .prominent: return .regularMaterial
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .subtle: return 8
            case .regular: return 12
            case .prominent: return 16
            }
        }
    }
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        glowColor: Color = .clear,
        intensity: GlassIntensity = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.glowColor = glowColor
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(intensity.material)
                    .shadow(
                        color: glowColor != .clear ? glowColor.opacity(0.3) : Color.black.opacity(0.1),
                        radius: intensity.shadowRadius,
                        x: 0,
                        y: 6
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Progress Ring

/// Activity-style circular progress indicator
struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8
    var gradient: [Color] = [.blue, .cyan]
    var showPercentage: Bool = true
    var animate: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animate ? animatedProgress : progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradient + [gradient.first ?? .blue]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedProgress)
            
            // Glow effect
            Circle()
                .trim(from: 0, to: animate ? animatedProgress : progress)
                .stroke(
                    gradient.first ?? .blue,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 6)
                .opacity(0.5)
            
            // Center content
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int((animate ? animatedProgress : progress) * 100))")
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animate {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.2)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { _, newValue in
            if animate {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Journey Node

/// A single node in a journey/timeline visualization
struct JourneyNode: View {
    let dayNumber: Int
    let state: NodeState
    var size: CGFloat = 36
    var themeColor: Color = .blue
    var onTap: (() -> Void)? = nil
    
    enum NodeState {
        case completed
        case current
        case upcoming
        case locked
    }
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap?()
        }) {
            ZStack {
                // Glow for current day
                if state == .current {
                    Circle()
                        .fill(themeColor)
                        .frame(width: size + 8, height: size + 8)
                        .blur(radius: 8)
                        .opacity(isPulsing ? 0.6 : 0.3)
                }
                
                // Main circle
                Circle()
                    .fill(backgroundFill)
                    .frame(width: size, height: size)
                
                // Border for upcoming
                if state == .upcoming {
                    Circle()
                        .stroke(themeColor.opacity(0.4), lineWidth: 2)
                        .frame(width: size, height: size)
                }
                
                // Content
                nodeContent
            }
            .scaleEffect(state == .current ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(state == .locked)
        .onAppear {
            if state == .current {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
    
    private var backgroundFill: some ShapeStyle {
        switch state {
        case .completed:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [themeColor, themeColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .current:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [themeColor, themeColor.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .upcoming:
            return AnyShapeStyle(Color.clear)
        case .locked:
            return AnyShapeStyle(Color.gray.opacity(0.2))
        }
    }
    
    @ViewBuilder
    private var nodeContent: some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        case .current:
            Text("\(dayNumber)")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        case .upcoming:
            Text("\(dayNumber)")
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .foregroundColor(themeColor.opacity(0.7))
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.35))
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}

// MARK: - Journey Map

/// A horizontal scrollable journey/timeline visualization
struct JourneyMapView: View {
    let totalDays: Int
    let completedDays: Set<Int>
    let currentDay: Int
    var themeColor: Color = .blue
    var onDayTap: ((Int) -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(1...totalDays, id: \.self) { day in
                        HStack(spacing: 0) {
                            JourneyNode(
                                dayNumber: day,
                                state: nodeState(for: day),
                                size: 32,
                                themeColor: themeColor
                            ) {
                                onDayTap?(day)
                            }
                            .id(day)
                            
                            // Connector line
                            if day < totalDays {
                                Rectangle()
                                    .fill(
                                        completedDays.contains(day)
                                            ? themeColor.opacity(0.6)
                                            : themeManager.dividerColor
                                    )
                                    .frame(width: 16, height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.5)) {
                        proxy.scrollTo(currentDay, anchor: .center)
                    }
                }
            }
        }
    }
    
    private func nodeState(for day: Int) -> JourneyNode.NodeState {
        if completedDays.contains(day) {
            return .completed
        } else if day == currentDay {
            return .current
        } else if day < currentDay {
            return .upcoming // Past but not completed
        } else {
            return .upcoming
        }
    }
}

// MARK: - Atmospheric Background

/// A gradient background with optional blur overlay for immersive sections
struct AtmosphericBackground: View {
    let colors: [Color]
    var addNoise: Bool = true
    var addVignette: Bool = true
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Radial overlay for depth
            RadialGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 400
            )
            
            // Vignette effect
            if addVignette {
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
            }
        }
    }
}

// MARK: - Floating Action Button

/// A floating action button with gradient and shadow
struct FloatingActionButton: View {
    let title: String
    var icon: String? = nil
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.mediumImpact()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(
            color: gradient.first?.opacity(0.35) ?? .clear,
            radius: 10,
            x: 0,
            y: 5
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Editorial Header

/// Large editorial-style header for immersive sections
struct EditorialHeader: View {
    let title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundColor(.white)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
            }
        }
    }
}

// MARK: - Scripture Quote

/// Elegant scripture quote styling
struct ScriptureQuote: View {
    let text: String
    let reference: String
    var accentColor: Color = .blue
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                Text("\u{201C}")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundColor(accentColor.opacity(0.3))
                    .offset(y: -10)
                
                Text(text)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundColor(themeManager.textColor)
                    .italic()
                    .lineSpacing(6)
            }
            
            if !reference.isEmpty {
                Text("— \(reference)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
                    .padding(.leading, 40)
            }
        }
    }
}

// MARK: - Expandable Scripture Card

/// An expandable card that shows scripture reference and can expand to show full text
struct ExpandableScriptureCard: View {
    let reading: ScriptureReading
    let themeColor: Color
    var onTap: (() -> Void)? = nil
    
    @State private var isExpanded = false
    @State private var isLoading = false
    @State private var loadedText: String? = nil
    @State private var errorMessage: String? = nil
    @ObservedObject private var themeManager = ThemeManager.shared
    
    /// Get the user's selected translation or fall back to a common one
    private var effectiveTranslationId: String {
        StorageService.shared.getSelectedTranslation() ?? "engKJV"  // King James Version as fallback
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                if isExpanded && loadedText == nil && !isLoading {
                    loadScripture()
                }
                onTap?()
                HapticManager.shared.lightImpact()
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundColor(themeColor)
                    }
                    
                    // Reference info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(reading.displayReference)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textColor)
                        
                        Text(isExpanded ? "Tap to collapse" : "Tap to read")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .background(themeManager.dividerColor)
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(themeColor)
                                Text("Loading scripture...")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            Spacer()
                        }
                        .padding()
                    } else if let text = loadedText, !text.isEmpty {
                        // Scripture text with verse numbers
                        Text(text)
                            .font(.system(size: 17, weight: .regular, design: .serif))
                            .foregroundColor(themeManager.textColor)
                            .lineSpacing(8)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    } else if let error = errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .multilineTextAlignment(.center)
                            Button("Try Again") {
                                loadScripture()
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        // Initial loading state
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(themeColor)
                            Spacer()
                        }
                        .padding()
                        .onAppear {
                            loadScripture()
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(
                    color: isExpanded ? themeColor.opacity(0.15) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? themeColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func loadScripture() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let translationToUse = effectiveTranslationId
        print("[Scripture] Loading \(reading.bookId) \(reading.startChapter) with translation: \(translationToUse)")
        
        Task {
            do {
                let chapter = try await BibleAPIService.shared.fetchChapter(
                    translationId: translationToUse,
                    bookId: reading.bookId,
                    chapter: reading.startChapter
                )
                
                // Extract the relevant verses
                let verses = extractVerses(from: chapter)
                
                await MainActor.run {
                    if verses.isEmpty {
                        loadedText = "No verses found for this reference."
                    } else {
                        // Format verses with superscript verse numbers
                        loadedText = formatVerses(verses)
                    }
                    isLoading = false
                }
            } catch let error as BibleError {
                print("[Scripture] BibleError: \(error.errorDescription ?? "unknown")")
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Unable to load scripture."
                    isLoading = false
                }
            } catch {
                print("[Scripture] Error: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Unable to load scripture. Please check your connection."
                    isLoading = false
                }
            }
        }
    }
    
    private func extractVerses(from chapter: Chapter) -> [Verse] {
        let allVerses = chapter.verses
        
        // If specific verses are specified, filter them
        if let startVerse = reading.startVerse {
            let endVerse = reading.endVerse ?? startVerse
            return allVerses.filter { $0.verse >= startVerse && $0.verse <= endVerse }
        }
        
        // If no specific verses, return all verses in the chapter
        return allVerses
    }
    
    private func formatVerses(_ verses: [Verse]) -> String {
        verses.map { verse in
            "[\(verse.verse)] \(verse.text)"
        }.joined(separator: " ")
    }
}

// MARK: - Quiz Card

/// A card for displaying quiz questions with multiple choice or reflection input
struct QuizCard: View {
    let question: QuizQuestion
    let themeColor: Color
    var onAnswer: ((Any) -> Void)? = nil  // Int for comprehension, String for reflection
    
    @State private var selectedOption: Int? = nil
    @State private var reflectionText: String = ""
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question header
            HStack(spacing: 10) {
                Image(systemName: question.type == .comprehension ? "checkmark.circle" : "bubble.left.and.text.bubble.right")
                    .font(.body)
                    .foregroundColor(themeColor)
                
                Text(question.type == .comprehension ? "Knowledge Check" : "Reflect")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeColor)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Question text
            Text(question.question)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
            
            // Answer section
            if question.type == .comprehension {
                comprehensionOptions
            } else {
                reflectionInput
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Comprehension Options
    
    private var comprehensionOptions: some View {
        VStack(spacing: 10) {
            if let options = question.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedOption = index
                            if let correct = question.correctAnswer {
                                isCorrect = index == correct
                                showResult = true
                            }
                            onAnswer?(index)
                        }
                        HapticManager.shared.lightImpact()
                    } label: {
                        HStack(spacing: 12) {
                            // Selection indicator
                            ZStack {
                                Circle()
                                    .stroke(optionBorderColor(for: index), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if selectedOption == index {
                                    Circle()
                                        .fill(optionFillColor(for: index))
                                        .frame(width: 14, height: 14)
                                }
                            }
                            
                            Text(option)
                                .font(.subheadline)
                                .foregroundColor(themeManager.textColor)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            // Result indicator
                            if showResult && selectedOption == index {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isCorrect ? .green : .red)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(optionBackground(for: index))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(showResult)
                }
            }
            
            // Correct answer feedback
            if showResult && !isCorrect, let correctIndex = question.correctAnswer, let options = question.options {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                    Text("The correct answer is: \(options[correctIndex])")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Reflection Input
    
    private var reflectionInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let hint = question.hint {
                Text(hint)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .italic()
            }
            
            ZStack(alignment: .topLeading) {
                if reflectionText.isEmpty {
                    Text("Share your thoughts...")
                        .font(.body)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $reflectionText)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.dividerColor, lineWidth: 1)
            )
            
            if !reflectionText.isEmpty {
                Button {
                    onAnswer?(reflectionText)
                    HapticManager.shared.success()
                } label: {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Save Response")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(themeColor)
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func optionBorderColor(for index: Int) -> Color {
        if showResult {
            if index == question.correctAnswer {
                return .green
            } else if index == selectedOption {
                return .red
            }
        }
        return selectedOption == index ? themeColor : themeManager.dividerColor
    }
    
    private func optionFillColor(for index: Int) -> Color {
        if showResult {
            if index == question.correctAnswer {
                return .green
            } else if index == selectedOption {
                return .red
            }
        }
        return themeColor
    }
    
    private func optionBackground(for index: Int) -> Color {
        if showResult {
            if index == question.correctAnswer {
                return Color.green.opacity(0.1)
            } else if index == selectedOption && !isCorrect {
                return Color.red.opacity(0.1)
            }
        }
        return selectedOption == index ? themeColor.opacity(0.1) : themeManager.backgroundColor.opacity(0.5)
    }
}

// MARK: - Content Section Card

/// A styled card for content sections like Historical Context, Prayer, Challenge
struct ContentSectionCard: View {
    let icon: String
    let title: String
    let content: String
    let accentColor: Color
    var style: CardStyle = .standard
    
    enum CardStyle {
        case standard
        case prayer      // Italicized, spiritual feel
        case challenge   // Action-oriented
    }
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }
            
            // Content
            Text(content)
                .font(style == .prayer ? .system(size: 16, weight: .regular, design: .serif) : .body)
                .italic(style == .prayer)
                .foregroundColor(themeManager.textColor)
                .lineSpacing(4)
            
            // Challenge action (if applicable)
            if style == .challenge {
                HStack {
                    Spacer()
                    Text("Accept this challenge")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(accentColor)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(backgroundFill)
        )
    }
    
    private var backgroundFill: Color {
        switch style {
        case .standard:
            return themeManager.cardBackgroundColor
        case .prayer:
            return themeManager.accentColor.opacity(0.08)
        case .challenge:
            return accentColor.opacity(0.08)
        }
    }
}

// MARK: - Cross Reference Chips

/// Horizontal scrolling chips for cross-references
struct CrossReferenceChips: View {
    let references: [String]
    let themeColor: Color
    var onTap: ((String) -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundColor(themeColor)
                
                Text("Related Passages")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(references, id: \.self) { ref in
                        Button {
                            onTap?(ref)
                            HapticManager.shared.lightImpact()
                        } label: {
                            Text(ref)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(themeColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(themeColor.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ThemedCard {
                VStack(alignment: .leading, spacing: 8) {
                    ThemedSectionHeader(title: "Section", icon: "star.fill", iconColor: .yellow)
                    Text("Card content goes here")
                }
            }
            
            ThemedPrimaryButton(title: "Primary Action", icon: "plus") {}
            ThemedSecondaryButton(title: "Secondary Action", icon: "arrow.right") {}
            
            HStack {
                ThemedStatPill(icon: "flame.fill", value: "7", label: "Streak", color: .orange)
                ThemedStatPill(icon: "checkmark", value: "3/5", label: "Done", color: .green)
            }
            
            ThemedProgressBar(progress: 0.65)
            
            ThemedStreakBadge(streak: 12, size: .large)
        }
        .padding()
    }
}

#Preview("Inputs") {
    VStack(spacing: 16) {
        ThemedTextField(placeholder: "Enter text...", text: .constant(""), icon: "magnifyingglass")
        ThemedTextEditor(placeholder: "Write your thoughts...", text: .constant(""))
    }
    .padding()
}

#Preview("Empty State") {
    ThemedEmptyState(
        icon: "tray",
        title: "No Items Yet",
        message: "Start adding items to see them here",
        actionTitle: "Add First Item"
    ) {}
}

#Preview("Glassmorphic Card") {
    ZStack {
        LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassmorphicCard(glowColor: .blue) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("With subtle blur and glow")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal)
            
            GlassmorphicCard(glowColor: .teal, intensity: .prominent) {
                Text("Prominent intensity")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
    }
}

#Preview("Progress Ring") {
    VStack(spacing: 30) {
        ProgressRing(progress: 0.75, gradient: [.green, .teal])
        
        ProgressRing(progress: 0.45, size: 120, lineWidth: 12, gradient: [.orange, .red])
        
        HStack(spacing: 20) {
            ProgressRing(progress: 0.25, size: 60, lineWidth: 6, gradient: [.blue, .cyan], showPercentage: false)
            ProgressRing(progress: 0.50, size: 60, lineWidth: 6, gradient: [.teal, .pink], showPercentage: false)
            ProgressRing(progress: 1.0, size: 60, lineWidth: 6, gradient: [.green, .mint], showPercentage: false)
        }
    }
    .padding()
}

#Preview("Journey Map") {
    VStack(spacing: 30) {
        JourneyMapView(
            totalDays: 7,
            completedDays: [1, 2, 3],
            currentDay: 4,
            themeColor: .teal
        )
        .background(Color(.systemBackground))
        
        JourneyMapView(
            totalDays: 30,
            completedDays: Set(1...12),
            currentDay: 13,
            themeColor: .orange
        )
        .background(Color(.systemBackground))
    }
}

#Preview("Atmospheric Background") {
    AtmosphericBackground(colors: [
        Color(red: 0.1, green: 0.2, blue: 0.4),
        Color(red: 0.05, green: 0.1, blue: 0.25)
    ])
    .ignoresSafeArea()
    .overlay(
        VStack {
            EditorialHeader(
                title: "Finding Peace",
                subtitle: "A 7-day journey through God's promises of rest"
            )
            .padding()
            Spacer()
        }
    )
}

#Preview("Scripture Quote") {
    VStack {
        ScriptureQuote(
            text: "The Lord is my shepherd; I shall not want. He makes me lie down in green pastures.",
            reference: "Psalm 23:1-2",
            accentColor: .teal
        )
        .padding()
    }
}

#Preview("Expandable Scripture") {
    VStack(spacing: 16) {
        ExpandableScriptureCard(
            reading: ScriptureReading(
                bookId: "GEN",
                bookName: "Genesis",
                startChapter: 1,
                startVerse: 1,
                endVerse: 5
            ),
            themeColor: .green
        )
        
        ExpandableScriptureCard(
            reading: ScriptureReading(
                bookId: "PSA",
                bookName: "Psalms",
                startChapter: 23
            ),
            themeColor: .teal
        )
    }
    .padding()
}

#Preview("Quiz Card - Comprehension") {
    QuizCard(
        question: QuizQuestion(
            question: "What did God say about His creation?",
            type: .comprehension,
            options: ["It was complete", "It was good", "It was finished", "It was perfect"],
            correctAnswer: 1
        ),
        themeColor: .green
    )
    .padding()
}

#Preview("Quiz Card - Reflection") {
    QuizCard(
        question: QuizQuestion(
            question: "How does knowing you were created with purpose change how you see yourself today?",
            type: .reflection,
            hint: "Consider your unique gifts, personality, and circumstances."
        ),
        themeColor: .blue
    )
    .padding()
}

#Preview("Content Section Cards") {
    ScrollView {
        VStack(spacing: 16) {
            ContentSectionCard(
                icon: "book.closed.fill",
                title: "Historical Context",
                content: "Genesis is the book of beginnings, written by Moses around 1400 BC. The Hebrew word 'bara' (create) is used exclusively for God's creative acts.",
                accentColor: .blue
            )
            
            ContentSectionCard(
                icon: "hands.sparkles.fill",
                title: "Guided Prayer",
                content: "Creator God, thank You for making me with intention and purpose. Help me see myself as You see me—wonderfully made and deeply loved. Amen.",
                accentColor: .teal,
                style: .prayer
            )
            
            ContentSectionCard(
                icon: "bolt.fill",
                title: "Today's Challenge",
                content: "Take a walk outside today and notice three things in creation that remind you of God's creativity and care.",
                accentColor: .orange,
                style: .challenge
            )
            
            CrossReferenceChips(
                references: ["Psalm 19:1", "John 1:1-3", "Colossians 1:16"],
                themeColor: .green
            )
        }
        .padding()
    }
}


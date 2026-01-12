//
//  WidgetAnimations.swift
//  Bible v1
//
//  Micro-interactions and animations for widget studio
//

import SwiftUI

// MARK: - Animation Extensions

extension Animation {
    /// Smooth spring for UI interactions
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    
    /// Quick bounce for feedback
    static let quickBounce = Animation.spring(response: 0.25, dampingFraction: 0.6)
    
    /// Gentle ease for transitions
    static let gentleEase = Animation.easeInOut(duration: 0.3)
    
    /// Staggered animation delay
    static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * baseDelay)
    }
}

// MARK: - View Modifiers

/// Adds a subtle pulse animation
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

/// Adds a shimmer loading effect
struct ShimmerModifier: ViewModifier {
    @State private var shimmerOffset: CGFloat = -1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: geometry.size.width * shimmerOffset)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
                }
            )
            .mask(content)
            .onAppear {
                shimmerOffset = 2
            }
    }
}

// MARK: - Shimmer Extension

extension View {
    /// Adds a shimmer loading effect to the view
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

/// Adds a glow effect
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color : .clear, radius: isActive ? radius : 0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

/// Adds a float/hover animation
struct FloatModifier: ViewModifier {
    @State private var isFloating = false
    let amount: CGFloat
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -amount : 0)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

/// Adds a scale on press effect
struct ScaleOnPressModifier: ViewModifier {
    let scale: CGFloat
    @GestureState private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: .infinity)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

/// Adds a rotation animation
struct SpinModifier: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .animation(
                Animation.linear(duration: duration).repeatForever(autoreverses: false),
                value: rotation
            )
            .onAppear {
                rotation = 360
            }
    }
}

/// Adds an entrance animation
struct EntranceModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: hasAppeared)
            .onAppear {
                hasAppeared = true
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a subtle pulse animation
    func pulse(duration: Double = 1.5) -> some View {
        modifier(PulseModifier(duration: duration))
    }
    
    /// Adds a shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
    
    /// Adds a glow effect
    func glow(color: Color = .blue, radius: CGFloat = 10, isActive: Bool = true) -> some View {
        modifier(GlowModifier(color: color, radius: radius, isActive: isActive))
    }
    
    /// Adds a float/hover animation
    func float(amount: CGFloat = 5, duration: Double = 2) -> some View {
        modifier(FloatModifier(amount: amount, duration: duration))
    }
    
    /// Adds a scale on press effect
    func scaleOnPress(scale: CGFloat = 0.95) -> some View {
        modifier(ScaleOnPressModifier(scale: scale))
    }
    
    /// Adds a rotation animation
    func spin(duration: Double = 2) -> some View {
        modifier(SpinModifier(duration: duration))
    }
    
    /// Adds an entrance animation
    func entrance(delay: Double = 0) -> some View {
        modifier(EntranceModifier(delay: delay))
    }
}

// MARK: - Transition Extensions

extension AnyTransition {
    /// Slide and fade from bottom
    static var slideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Slide and fade from top
    static var slideDown: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Scale and fade
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
    
    /// Pop from center
    static var pop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.5).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        )
    }
}

// MARK: - Animated Number

/// Animated number counter
struct AnimatedNumber: View {
    let value: Double
    let format: String
    
    @State private var displayValue: Double = 0
    
    var body: some View {
        Text(String(format: format, displayValue))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Confetti Effect

/// Simple confetti particle
struct ConfettiParticle: View {
    let color: Color
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: 8, height: 5)
            .offset(x: offsetX, y: offsetY)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    offsetY = CGFloat.random(in: 100...200)
                    offsetX = CGFloat.random(in: -50...50)
                    rotation = Double.random(in: 0...720)
                    opacity = 0
                }
            }
    }
}

/// Confetti burst effect
struct ConfettiBurst: View {
    let colors: [Color]
    let particleCount: Int
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { _ in
                ConfettiParticle(color: colors.randomElement() ?? .blue)
                    .offset(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20))
            }
        }
    }
}

// MARK: - Loading Indicators

/// Animated dots loading indicator
struct LoadingDots: View {
    @State private var animatingDot = 0
    let dotCount = 3
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot == index ? 1.3 : 1)
                    .opacity(animatingDot == index ? 1 : 0.5)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                animatingDot = (animatingDot + 1) % dotCount
            }
        }
    }
}

/// Circular progress spinner
struct CircularSpinner: View {
    @State private var rotation: Double = 0
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1).repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        // Pulse
        Circle()
            .fill(.blue)
            .frame(width: 50, height: 50)
            .pulse()
        
        // Float
        RoundedRectangle(cornerRadius: 10)
            .fill(.purple)
            .frame(width: 100, height: 60)
            .float()
        
        // Loading dots
        LoadingDots(color: .gray)
        
        // Circular spinner
        CircularSpinner(color: .blue, lineWidth: 3)
            .frame(width: 30, height: 30)
    }
    .padding()
}


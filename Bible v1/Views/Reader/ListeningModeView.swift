//
//  ListeningModeView.swift
//  Bible v1
//
//  Immersive Full-Screen Listening Mode with Animations
//

import SwiftUI

/// Immersive full-screen listening mode view
struct ListeningModeView: View {
    @ObservedObject var audioService: AudioService
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject private var settings = SettingsStore.shared
    
    let onClose: () -> Void
    let onVerseSelect: (Int) -> Void
    
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var animateWaveform = false
    @State private var animatePulse = false
    @State private var textOpacity: Double = 1.0
    @State private var previousVerseText: String = ""
    @State private var showSleepTimer = false
    @State private var sleepTimerMinutes: Int = 0
    @State private var sleepTimerEndTime: Date?
    
    /// Use settings for auto-hide delay instead of hardcoded value
    private var hideControlsDelay: TimeInterval {
        settings.immersiveAutoHideDelay
    }
    
    /// Check if animations should be shown based on settings
    private var showAnimations: Bool {
        settings.immersiveAnimationStyle != .none && !settings.reducedMotionEnabled
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                AnimatedListeningBackground()
                    .ignoresSafeArea()
                
                // Particle effects - only show if animations are enabled
                if showAnimations {
                    ParticleEffectsView()
                        .ignoresSafeArea()
                        .opacity(settings.immersiveAnimationStyle == .dynamic ? 0.8 : 0.5)
                }
                
                // Main content
                VStack(spacing: 0) {
                    // Top section with reference
                    topSection
                        .opacity(showControls ? 1 : 0)
                    
                    Spacer()
                    
                    // Center section with waveform and verse
                    centerSection(geometry: geometry)
                    
                    Spacer()
                    
                    // Bottom section with controls
                    bottomSection
                        .opacity(showControls ? 1 : 0)
                }
                .padding()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleControls()
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        handleSwipe(value)
                    }
            )
        }
        .onAppear {
            startAnimations()
            scheduleHideControls()
            
            // Keep screen on if setting is enabled
            if settings.immersiveKeepScreenOn {
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
        .onDisappear {
            controlsTimer?.invalidate()
            
            // Re-enable screen idle timer
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: audioService.currentVerseText) { oldValue, newValue in
            animateTextChange(from: oldValue)
        }
        .sheet(isPresented: $showSleepTimer) {
            ListeningSleepTimerSheet(
                selectedMinutes: $sleepTimerMinutes,
                themeManager: themeManager,
                onSet: { minutes in
                    setSleepTimer(minutes: minutes)
                }
            )
        }
        .statusBarHidden(!showControls)
    }
    
    // MARK: - Top Section
    
    private var topSection: some View {
        HStack {
            // Close button
            Button {
                HapticManager.shared.lightImpact()
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 5)
            }
            
            Spacer()
            
            // Reference and progress
            VStack(spacing: 4) {
                Text(audioService.currentReference)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Verse \(audioService.currentVerseNumber) of \(audioService.totalVerses)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Sleep timer button
            Button {
                showSleepTimer = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: sleepTimerEndTime != nil ? "moon.fill" : "moon")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let endTime = sleepTimerEndTime {
                        Text(timerRemainingText(until: endTime))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 5)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.3), value: showControls)
    }
    
    // MARK: - Center Section
    
    private func centerSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 32) {
            // Progress ring with waveform
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: audioService.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: audioService.progress)
                
                // Pulsing center - respects animation style
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(showAnimations && animatePulse && audioService.isPlaying && !audioService.isPaused ? (settings.immersiveAnimationStyle == .dynamic ? 1.15 : 1.05) : 1.0)
                    .animation(
                        showAnimations ? .easeInOut(duration: settings.immersiveAnimationStyle == .dynamic ? 0.8 : 1.5).repeatForever(autoreverses: true) : nil,
                        value: animatePulse
                    )
                
                // Waveform visualization
                WaveformView(
                    isAnimating: audioService.isPlaying && !audioService.isPaused,
                    isLoading: audioService.isLoadingAudio
                )
                .frame(width: 120, height: 60)
            }
            
            // Current verse text with animation
            VStack(spacing: 16) {
                Text(audioService.currentVerseText)
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .opacity(textOpacity)
                    .animation(.easeInOut(duration: 0.4), value: textOpacity)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: {
                        let width = geometry.size.width - 40
                        guard width.isFinite && width > 0 else { return 500 }
                        return min(width, 500)
                    }())
                
                // Verse number badge
                Text("Verse \(audioService.currentVerseNumber)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
            }
            
            // Loading indicator
            if audioService.isLoadingAudio {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Loading audio...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: 24) {
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: geo.size.width * audioService.progress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: audioService.progress)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(audioService.currentVerseNumber)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(audioService.totalVerses)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal)
            
            // Playback controls
            HStack(spacing: 48) {
                // Previous
                Button {
                    HapticManager.shared.lightImpact()
                    audioService.previousVerse()
                    resetControlsTimer()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(audioService.currentVerseIndex > 0 ? .white : .white.opacity(0.3))
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                .disabled(audioService.currentVerseIndex == 0)
                
                // Play/Pause
                Button {
                    HapticManager.shared.mediumImpact()
                    audioService.togglePlayPause()
                    resetControlsTimer()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        
                        if audioService.isLoadingAudio {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Image(systemName: audioService.isPaused ? "play.fill" : "pause.fill")
                                .font(.title)
                                .foregroundColor(.black)
                                .offset(x: audioService.isPaused ? 3 : 0)
                        }
                    }
                }
                .disabled(audioService.isLoadingAudio)
                
                // Next
                Button {
                    HapticManager.shared.lightImpact()
                    audioService.nextVerse()
                    resetControlsTimer()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(audioService.currentVerseIndex < audioService.totalVerses - 1 ? .white : .white.opacity(0.3))
                        .shadow(color: .black.opacity(0.3), radius: 5)
                }
                .disabled(audioService.currentVerseIndex >= audioService.totalVerses - 1)
            }
            
            // Audio source indicator
            HStack(spacing: 8) {
                Image(systemName: audioService.currentAudioSource.icon)
                    .font(.caption)
                Text(audioService.currentAudioSource.displayName)
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.5))
            .padding(.bottom, 16)
        }
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.3), value: showControls)
    }
    
    // MARK: - Helpers
    
    private func startAnimations() {
        animateWaveform = true
        animatePulse = true
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            scheduleHideControls()
        } else {
            controlsTimer?.invalidate()
        }
    }
    
    private func scheduleHideControls() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: hideControlsDelay, repeats: false) { _ in
            Task { @MainActor in
                if audioService.isPlaying && !audioService.isPaused {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls = false
                    }
                }
            }
        }
    }
    
    private func resetControlsTimer() {
        showControls = true
        scheduleHideControls()
    }
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontalAmount = value.translation.width
        let verticalAmount = value.translation.height
        
        if abs(horizontalAmount) > abs(verticalAmount) {
            if horizontalAmount < -50 {
                // Swipe left - next verse
                if audioService.currentVerseIndex < audioService.totalVerses - 1 {
                    HapticManager.shared.lightImpact()
                    audioService.nextVerse()
                }
            } else if horizontalAmount > 50 {
                // Swipe right - previous verse
                if audioService.currentVerseIndex > 0 {
                    HapticManager.shared.lightImpact()
                    audioService.previousVerse()
                }
            }
        } else {
            if verticalAmount > 100 {
                // Swipe down - close
                HapticManager.shared.lightImpact()
                onClose()
            }
        }
    }
    
    private func animateTextChange(from oldText: String) {
        previousVerseText = oldText
        withAnimation(.easeOut(duration: 0.2)) {
            textOpacity = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.3)) {
                textOpacity = 1.0
            }
        }
    }
    
    private func setSleepTimer(minutes: Int) {
        sleepTimerMinutes = minutes
        if minutes > 0 {
            sleepTimerEndTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
            
            // Schedule stop
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60)) { [weak audioService] in
                audioService?.stop()
            }
        } else {
            sleepTimerEndTime = nil
        }
    }
    
    private func timerRemainingText(until date: Date) -> String {
        let remaining = max(0, date.timeIntervalSinceNow)
        let minutes = Int(remaining / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Waveform View

struct WaveformView: View {
    let isAnimating: Bool
    let isLoading: Bool
    
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let midY = size.height / 2
                let barCount = 20
                let barWidth: CGFloat = 3
                let spacing = (size.width - CGFloat(barCount) * barWidth) / CGFloat(barCount - 1)
                
                for i in 0..<barCount {
                    let x = CGFloat(i) * (barWidth + spacing)
                    
                    var height: CGFloat
                    if isLoading {
                        // Loading animation - sequential wave
                        let loadingPhase = (Double(i) / Double(barCount) + phase) * .pi * 2
                        height = CGFloat(sin(loadingPhase)) * 15 + 20
                    } else if isAnimating {
                        // Playing animation - organic wave
                        let wave1 = sin(phase * 3 + Double(i) * 0.3) * 12
                        let wave2 = sin(phase * 5 + Double(i) * 0.5) * 8
                        let wave3 = sin(phase * 2 + Double(i) * 0.2) * 6
                        height = CGFloat(wave1 + wave2 + wave3) + 25
                    } else {
                        // Paused - flat bars
                        height = 8
                    }
                    
                    height = max(4, min(size.height - 4, height))
                    
                    let rect = CGRect(
                        x: x,
                        y: midY - height / 2,
                        width: barWidth,
                        height: height
                    )
                    
                    let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                    context.fill(path, with: .color(.white.opacity(0.8)))
                }
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: isAnimating) { _, _ in
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            phase = .pi * 2
        }
    }
}

// MARK: - Animated Background

struct AnimatedListeningBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.3),
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.02, green: 0.05, blue: 0.15)
                ],
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )
            
            // Overlay gradients for depth
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.clear
                ],
                center: animateGradient ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    ThemeManager.shared.accentColor.opacity(0.1),
                    Color.clear
                ],
                center: animateGradient ? .bottomTrailing : .topLeading,
                startRadius: 50,
                endRadius: 300
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Particle Effects

struct ParticleEffectsView: View {
    @State private var particles: [Particle] = []
    @State private var viewSize: CGSize = .zero
    @State private var animationTimer: Timer?
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        let rect = CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        )
                        
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(.white.opacity(particle.opacity))
                        )
                    }
                }
            }
            .onAppear {
                viewSize = geometry.size
                initializeParticles(in: geometry.size)
                startParticleAnimation(in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
            }
            .onDisappear {
                animationTimer?.invalidate()
                animationTimer = nil
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 0.5...2)
            )
        }
    }
    
    private func startParticleAnimation(in size: CGSize) {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            let currentSize = viewSize.width > 0 ? viewSize : size
            for i in particles.indices {
                particles[i].y -= CGFloat(particles[i].speed)
                particles[i].x += CGFloat.random(in: -0.5...0.5)
                
                // Reset particle when it goes off screen
                if particles[i].y < -10 {
                    particles[i].y = currentSize.height + 10
                    particles[i].x = CGFloat.random(in: 0...currentSize.width)
                }
            }
        }
    }
}

// MARK: - Listening Sleep Timer Sheet

struct ListeningSleepTimerSheet: View {
    @Binding var selectedMinutes: Int
    let themeManager: ThemeManager
    let onSet: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let timerOptions = [0, 5, 10, 15, 30, 45, 60, 90, 120]
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(timerOptions, id: \.self) { minutes in
                            Button {
                                selectedMinutes = minutes
                                onSet(minutes)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(minutes == 0 ? "Off" : formatMinutes(minutes))
                                        .foregroundColor(themeManager.textColor)
                                    
                                    Spacer()
                                    
                                    if selectedMinutes == minutes {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.accentColor)
                                    }
                                }
                                .padding()
                                .background(themeManager.cardBackgroundColor)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
            return "\(hours)h \(mins)m"
        }
        return "\(minutes) minutes"
    }
}

#Preview {
    ListeningModeView(
        audioService: AudioService.shared,
        themeManager: ThemeManager.shared,
        onClose: {},
        onVerseSelect: { _ in }
    )
}


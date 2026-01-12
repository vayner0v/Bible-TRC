//
//  TypewriterTextView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Animated Typewriter Text Display
//

import SwiftUI

/// Animated text view that reveals content character by character with smooth fade-in
struct TypewriterTextView: View {
    let fullText: String
    let isStreaming: Bool
    let textColor: Color
    let speed: Double // characters per second
    
    @State private var displayedCharCount: Int = 0
    @State private var cursorVisible: Bool = true
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let cursorBlinkInterval: Double = 0.5
    
    init(
        text: String,
        isStreaming: Bool,
        textColor: Color = .primary,
        speed: Double = 60 // 60 characters per second default
    ) {
        self.fullText = text
        self.isStreaming = isStreaming
        self.textColor = textColor
        self.speed = speed
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Main text content
            Text(displayedText)
                .font(.body)
                .foregroundColor(textColor)
                .textSelection(.enabled)
            
            // Blinking cursor during streaming
            if isStreaming && displayedCharCount < fullText.count {
                Text("▍")
                    .font(.body)
                    .foregroundColor(themeManager.accentColor)
                    .opacity(cursorVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: cursorVisible)
            }
        }
        .onAppear {
            startTypewriterAnimation()
            startCursorBlink()
        }
        .onChange(of: fullText) { oldValue, newValue in
            // When new text arrives during streaming, continue from current position
            if newValue.count > oldValue.count && isStreaming {
                // Text grew, continue animation
                continueAnimation()
            }
        }
        .onChange(of: isStreaming) { _, streaming in
            if !streaming {
                // Streaming ended, show full text immediately
                displayedCharCount = fullText.count
            }
        }
    }
    
    private var displayedText: AttributedString {
        let endIndex = min(displayedCharCount, fullText.count)
        let substring = String(fullText.prefix(endIndex))
        
        // Parse markdown-style formatting
        do {
            return try AttributedString(markdown: substring)
        } catch {
            return AttributedString(substring)
        }
    }
    
    private func startTypewriterAnimation() {
        guard isStreaming else {
            displayedCharCount = fullText.count
            return
        }
        
        animateNextCharacter()
    }
    
    private func continueAnimation() {
        animateNextCharacter()
    }
    
    private func animateNextCharacter() {
        guard displayedCharCount < fullText.count else { return }
        
        let delay = 1.0 / speed
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.05)) {
                if displayedCharCount < fullText.count {
                    displayedCharCount += 1
                    animateNextCharacter()
                }
            }
        }
    }
    
    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: cursorBlinkInterval, repeats: true) { timer in
            if !isStreaming || displayedCharCount >= fullText.count {
                timer.invalidate()
                cursorVisible = false
                return
            }
            cursorVisible.toggle()
        }
    }
}

/// High-performance typewriter for longer texts - uses word-based animation
struct TypewriterTextViewOptimized: View {
    let fullText: String
    let isStreaming: Bool
    let textColor: Color
    
    @State private var displayedWordCount: Int = 0
    @State private var cursorVisible: Bool = true
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let wordsPerSecond: Double = 15
    private let cursorBlinkInterval: Double = 0.5
    
    private var words: [String] {
        fullText.components(separatedBy: .whitespaces)
    }
    
    init(
        text: String,
        isStreaming: Bool,
        textColor: Color = .primary
    ) {
        self.fullText = text
        self.isStreaming = isStreaming
        self.textColor = textColor
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(displayedText)
                .font(.body)
                .foregroundColor(textColor)
                .textSelection(.enabled)
            
            if isStreaming && displayedWordCount < words.count {
                Text("▍")
                    .font(.body)
                    .foregroundColor(themeManager.accentColor)
                    .opacity(cursorVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: cursorVisible)
            }
        }
        .onAppear {
            startAnimation()
            startCursorBlink()
        }
        .onChange(of: fullText) { _, _ in
            if isStreaming {
                continueAnimation()
            }
        }
        .onChange(of: isStreaming) { _, streaming in
            if !streaming {
                displayedWordCount = words.count
            }
        }
    }
    
    private var displayedText: AttributedString {
        let displayedWords = words.prefix(displayedWordCount).joined(separator: " ")
        do {
            return try AttributedString(markdown: displayedWords)
        } catch {
            return AttributedString(displayedWords)
        }
    }
    
    private func startAnimation() {
        guard isStreaming else {
            displayedWordCount = words.count
            return
        }
        animateNextWord()
    }
    
    private func continueAnimation() {
        animateNextWord()
    }
    
    private func animateNextWord() {
        guard displayedWordCount < words.count else { return }
        
        let delay = 1.0 / wordsPerSecond
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.08)) {
                if displayedWordCount < words.count {
                    displayedWordCount += 1
                    animateNextWord()
                }
            }
        }
    }
    
    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: cursorBlinkInterval, repeats: true) { timer in
            if !isStreaming || displayedWordCount >= words.count {
                timer.invalidate()
                cursorVisible = false
                return
            }
            cursorVisible.toggle()
        }
    }
}

/// Streaming-optimized typewriter that handles real-time text updates
struct StreamingTypewriterView: View {
    let text: String
    let isStreaming: Bool
    let textColor: Color
    
    @State private var revealedLength: Int = 0
    @State private var animationTimer: Timer?
    @State private var cursorOpacity: Double = 1.0
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let charsPerFrame: Int = 3 // Reveal multiple chars per frame for speed
    private let frameInterval: Double = 0.03 // ~33fps
    
    init(text: String, isStreaming: Bool, textColor: Color = .primary) {
        self.text = text
        self.isStreaming = isStreaming
        self.textColor = textColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Revealed text with smooth appearance
            Text(revealedContent)
                .font(.body)
                .foregroundColor(textColor)
                .textSelection(.enabled)
                .animation(.easeOut(duration: 0.1), value: revealedLength)
            
            // Streaming cursor
            if isStreaming {
                HStack(spacing: 2) {
                    Text("▍")
                        .font(.body.weight(.light))
                        .foregroundColor(themeManager.accentColor)
                        .opacity(cursorOpacity)
                }
                .padding(.top, 2)
            }
        }
        .onAppear {
            startReveal()
        }
        .onChange(of: text) { oldText, newText in
            // New content arrived - continue revealing
            if newText.count > revealedLength {
                startReveal()
            }
        }
        .onChange(of: isStreaming) { _, streaming in
            if !streaming {
                // Show all content when streaming ends
                revealedLength = text.count
                animationTimer?.invalidate()
                animationTimer = nil
            }
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private var revealedContent: AttributedString {
        let endIndex = min(revealedLength, text.count)
        let revealed = String(text.prefix(endIndex))
        
        do {
            return try AttributedString(markdown: revealed)
        } catch {
            return AttributedString(revealed)
        }
    }
    
    private func startReveal() {
        // Cancel existing timer
        animationTimer?.invalidate()
        
        guard isStreaming, revealedLength < text.count else {
            if !isStreaming {
                revealedLength = text.count
            }
            return
        }
        
        // Start cursor blink
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            cursorOpacity = 0.3
        }
        
        // Reveal timer
        animationTimer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { timer in
            if revealedLength >= text.count {
                if !isStreaming {
                    timer.invalidate()
                    animationTimer = nil
                }
                return
            }
            
            revealedLength = min(revealedLength + charsPerFrame, text.count)
        }
    }
}

// MARK: - Preview

#Preview("Typewriter Animation") {
    VStack(alignment: .leading, spacing: 20) {
        TypewriterTextView(
            text: "The Lord is my shepherd; I shall not want. He maketh me to lie down in green pastures.",
            isStreaming: true,
            textColor: .primary,
            speed: 40
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        
        StreamingTypewriterView(
            text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            isStreaming: true,
            textColor: .primary
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    .padding()
}





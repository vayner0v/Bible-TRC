//
//  TRCInsightOverlay.swift
//  Bible v1
//
//  Inline thinking animation and expandable result card for TRC Insight
//

import SwiftUI

/// Inline overlay that shows thinking animation and expands to show AI insight
struct TRCInsightOverlay: View {
    let reference: VerseReference
    let state: InsightState
    let onDismiss: () -> Void
    let onSave: (VerseInsight) -> Void
    let onShare: (String) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showContent = false
    @Namespace private var animation
    
    var body: some View {
        // Use TimelineView for smooth continuous animations during loading states
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            
            VStack(spacing: 0) {
                // Main content card
                VStack(spacing: 16) {
                    // Header
                    headerView(phase: phase)
                    
                    // Content based on state
                    switch state {
                    case .idle:
                        EmptyView()
                        
                    case .thinking(let type):
                        thinkingView(type: type, phase: phase)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        
                    case .streaming(let type, let content):
                        streamingView(type: type, content: content, phase: phase)
                            .transition(.opacity)
                        
                    case .complete(let insight):
                        completeView(insight: insight)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        
                    case .error(let message):
                        errorView(message: message)
                            .transition(.opacity)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.cardBackgroundColor)
                        .shadow(color: themeManager.hubShadowColor, radius: 16, y: 8)
                )
                .overlay(
                    // Animated border for loading states
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            AngularGradient(
                                colors: state.isLoading ? [
                                    themeManager.accentColor.opacity(0.6),
                                    themeManager.accentColor.opacity(0.3),
                                    themeManager.accentColor.opacity(0.1),
                                    themeManager.accentColor.opacity(0.3),
                                    themeManager.accentColor.opacity(0.6)
                                ] : [
                                    themeManager.accentColor.opacity(0.3),
                                    themeManager.accentColor.opacity(0.2)
                                ],
                                center: .center,
                                angle: state.isLoading ? .degrees(phase * 60) : .degrees(0)
                            ),
                            lineWidth: state.isLoading ? 2 : 1
                        )
                )
                // Subtle glow effect during loading
                .shadow(
                    color: state.isLoading ? themeManager.accentColor.opacity(0.15 + 0.1 * sin(phase * 2)) : .clear,
                    radius: state.isLoading ? 12 : 0
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Header
    
    private func headerView(phase: Double) -> some View {
        HStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                // Animated background ring during loading
                if state.isLoading {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    themeManager.accentColor.opacity(0.8),
                                    themeManager.accentColor.opacity(0.4),
                                    themeManager.accentColor.opacity(0.2)
                                ],
                                center: .center,
                                angle: .degrees(phase * 120)
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 42, height: 42)
                }
                
                Circle()
                    .fill(themeManager.accentColor)
                    .frame(width: 36, height: 36)
                
                if state.isLoading {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(1 + 0.15 * sin(phase * 3))
                        .rotationEffect(.degrees(sin(phase * 2) * 8))
                } else {
                    Image(systemName: state.analysisType?.icon ?? "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("TRC Insight")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.textColor)
                
                if state.isLoading {
                    // Animated analyzing text
                    HStack(spacing: 0) {
                        Text(state.analysisType?.displayName ?? "Analyzing")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        // Animated ellipsis
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Text(".")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                                    .opacity(dotOpacity(for: i, phase: phase))
                            }
                        }
                    }
                } else {
                    Text(state.analysisType?.displayName ?? "Analyzing...")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(width: 28, height: 28)
                    .background(themeManager.backgroundColor.opacity(0.8))
                    .clipShape(Circle())
            }
        }
    }
    
    // Helper for animated ellipsis
    private func dotOpacity(for index: Int, phase: Double) -> Double {
        let cyclePosition = (phase * 2).truncatingRemainder(dividingBy: 3)
        if cyclePosition >= Double(index) && cyclePosition < Double(index + 1) {
            return 1.0
        }
        return 0.3
    }
    
    // MARK: - Thinking View
    
    private func thinkingView(type: InsightAnalysisType, phase: Double) -> some View {
        VStack(spacing: 16) {
            // Animated thinking indicator with wave effect
            ZStack {
                // Background pulse rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            themeManager.accentColor.opacity(0.3 - Double(i) * 0.08),
                            lineWidth: 1.5
                        )
                        .frame(width: 50 + CGFloat(i) * 25, height: 50 + CGFloat(i) * 25)
                        .scaleEffect(1 + 0.1 * sin(phase * 2 + Double(i) * 0.8))
                        .opacity(0.4 - Double(i) * 0.1)
                }
                
                // Center animated dots container
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 12, height: 12)
                            // Wave bounce animation
                            .offset(y: -8 * sin(phase * 4 + Double(i) * 0.8))
                            .scaleEffect(0.8 + 0.3 * sin(phase * 3 + Double(i) * 0.6))
                            .shadow(color: themeManager.accentColor.opacity(0.5), radius: 4)
                    }
                }
            }
            .frame(height: 100)
            
            // Animated text
            HStack(spacing: 4) {
                Text("TRC is thinking")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themeManager.textColor)
                
                // Animated ellipsis dots
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(themeManager.secondaryTextColor)
                            .frame(width: 4, height: 4)
                            .offset(y: -3 * sin(phase * 5 + Double(i) * 0.7))
                    }
                }
            }
            
            // Type indicator pill with subtle pulse
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                    .rotationEffect(.degrees(sin(phase * 2) * 5))
                Text(type.displayName)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(themeManager.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(themeManager.accentColor.opacity(0.1 + 0.05 * sin(phase * 2)))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Streaming View
    
    private func streamingView(type: InsightAnalysisType, content: String, phase: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content being streamed
            Text(content)
                .font(.subheadline)
                .foregroundColor(themeManager.textColor)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Animated streaming indicator
            HStack(spacing: 8) {
                // Animated typing indicator
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(themeManager.accentColor)
                            .frame(width: 6, height: 6)
                            .scaleEffect(0.7 + 0.4 * sin(phase * 5 + Double(i) * 0.8))
                            .opacity(0.5 + 0.5 * sin(phase * 5 + Double(i) * 0.8))
                    }
                }
                
                Text("Generating...")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                // Blinking cursor
                Rectangle()
                    .fill(themeManager.accentColor)
                    .frame(width: 2, height: 14)
                    .opacity(0.3 + 0.7 * sin(phase * 6))
            }
        }
    }
    
    // MARK: - Complete View
    
    private func completeView(insight: VerseInsight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Verse reference pill
            HStack(spacing: 6) {
                Image(systemName: "book.closed")
                    .font(.caption)
                Text(reference.shortReference)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(themeManager.accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(themeManager.accentColor.opacity(0.12))
            .cornerRadius(8)
            
            // Main content
            ScrollView {
                Text(insight.content)
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            
            // Citations if any
            if !insight.citations.isEmpty {
                citationsView(citations: insight.citations)
            }
            
            // Action buttons
            actionButtons(insight: insight)
        }
    }
    
    private func citationsView(citations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Related Verses")
                .font(.caption.weight(.semibold))
                .foregroundColor(themeManager.secondaryTextColor)
            
            InsightFlowLayout(spacing: 6) {
                ForEach(citations, id: \.self) { citation in
                    Text(citation)
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(themeManager.accentColor.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
    }
    
    private func actionButtons(insight: VerseInsight) -> some View {
        HStack(spacing: 12) {
            // Save button
            Button {
                onSave(insight)
                HapticManager.shared.success()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark")
                        .font(.caption.weight(.semibold))
                    Text("Save")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(themeManager.accentColor)
                .cornerRadius(10)
            }
            
            // Share button
            Button {
                let shareText = "\(reference.shortReference)\n\n\(insight.content)"
                onShare(shareText)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption.weight(.semibold))
                    Text("Share")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(themeManager.backgroundColor)
                .cornerRadius(10)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button("Dismiss") {
                onDismiss()
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(themeManager.accentColor)
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Insight Flow Layout for Citations

struct InsightFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = InsightFlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = InsightFlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct InsightFlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + lineHeight
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        TRCInsightOverlay(
            reference: VerseReference(
                translationId: "BSB",
                bookId: "JHN",
                bookName: "John",
                chapter: 3,
                verse: 16,
                text: "For God so loved the world..."
            ),
            state: .thinking(.contextMeaning),
            onDismiss: {},
            onSave: { _ in },
            onShare: { _ in }
        )
        
        TRCInsightOverlay(
            reference: VerseReference(
                translationId: "BSB",
                bookId: "JHN",
                bookName: "John",
                chapter: 3,
                verse: 16,
                text: "For God so loved the world..."
            ),
            state: .complete(VerseInsight(
                reference: "John 3:16",
                verseText: "For God so loved the world...",
                translationId: "BSB",
                analysisType: .contextMeaning,
                content: "This verse is one of the most famous in all of Scripture, often called 'the Gospel in a nutshell.' Written by the apostle John, it encapsulates the core message of Christianity: God's immense love for humanity and the gift of salvation through Jesus Christ.",
                citations: ["Romans 5:8", "1 John 4:9", "Ephesians 2:4-5"]
            )),
            onDismiss: {},
            onSave: { _ in },
            onShare: { _ in }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}


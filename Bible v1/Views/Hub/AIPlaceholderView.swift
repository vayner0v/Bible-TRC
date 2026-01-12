//
//  AIPlaceholderView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Main Entry Point
//

import SwiftUI

/// Main AI view - now redirects to TRCAIChatView
struct AIPlaceholderView: View {
    var body: some View {
        TRCAIChatView()
    }
}

/// Feature preview row
struct FeaturePreviewRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

/// AI button for Hub header
struct AIFloatingButton: View {
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.accentColor.opacity(isAnimating ? 0.3 : 0.15),
                                themeManager.hubGlowColor.opacity(isAnimating ? 0.3 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .blur(radius: 6)
                
                // Main button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.accentColor,
                                themeManager.hubGlowColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: themeManager.hubShadowColor, radius: 8, y: 4)
                
                // Icon
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    AIPlaceholderView()
}

#Preview("AI Button") {
    ZStack {
        Color.gray.opacity(0.2)
        AIFloatingButton(action: {})
    }
}

//
//  LoadingView.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// A loading indicator view
struct LoadingView: View {
    let message: String?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(themeManager.accentColor)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

/// A full-screen loading overlay
struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(isLoading: Bool, message: String? = nil) {
        self.isLoading = isLoading
        self.message = message
    }
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    if let message = message {
                        Text(message)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding(36)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
    }
}

/// An empty state view
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        themeManager: ThemeManager = ThemeManager.shared
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        // Note: themeManager parameter kept for API compatibility but we use shared instance
        // to ensure reactivity
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Animated icon with circles
            ZStack {
                Circle()
                    .fill(themeManager.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(themeManager.accentColor.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.accentColor)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(themeManager.accentColor)
                        .cornerRadius(25)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

/// Error view with retry option
struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(themeManager.accentColor)
                    .cornerRadius(25)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.backgroundColor)
    }
}

#Preview("Loading") {
    LoadingView("Loading scripture...")
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "heart",
        title: "No Favorites Yet",
        message: "Save your favorite verses to access them quickly",
        actionTitle: "Browse Bible",
        action: {}
    )
}

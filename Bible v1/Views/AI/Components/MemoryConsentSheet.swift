//
//  MemoryConsentSheet.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Memory Consent Flow
//

import SwiftUI

/// First-time consent sheet for AI memory feature
struct MemoryConsentSheet: View {
    @ObservedObject private var preferencesService = AIPreferencesService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPage: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content
                TabView(selection: $currentPage) {
                    introPage.tag(0)
                    whatWeRememberPage.tag(1)
                    privacyPage.tag(2)
                    consentPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page indicators and buttons
                VStack(spacing: 20) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index == currentPage ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Buttons
                    if currentPage < 3 {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.accentColor)
                                .cornerRadius(14)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Button {
                                enableMemory()
                            } label: {
                                Text("Enable Memory")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(themeManager.accentColor)
                                    .cornerRadius(14)
                            }
                            
                            Button {
                                declineMemory()
                            } label: {
                                Text("Not Now")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(themeManager.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        declineMemory()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Pages
    
    private var introPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("TRC AI Memory")
                    .font(.title.bold())
                    .foregroundColor(themeManager.textColor)
                
                Text("A more personal faith companion that remembers what matters to you")
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var whatWeRememberPage: some View {
        VStack(spacing: 24) {
            Text("What TRC AI Can Remember")
                .font(.title2.bold())
                .foregroundColor(themeManager.textColor)
                .padding(.top, 40)
            
            VStack(spacing: 16) {
                MemoryFeatureRow(
                    icon: "hands.sparkles",
                    color: .purple,
                    title: "Prayer Requests",
                    description: "Ongoing prayer intentions you've shared"
                )
                
                MemoryFeatureRow(
                    icon: "heart.fill",
                    color: .red,
                    title: "Favorite Verses",
                    description: "Scriptures that resonate with you"
                )
                
                MemoryFeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange,
                    title: "Personal Context",
                    description: "Challenges you're working through"
                )
                
                MemoryFeatureRow(
                    icon: "lightbulb.fill",
                    color: .yellow,
                    title: "Helpful Insights",
                    description: "Responses that were particularly meaningful"
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var privacyPage: some View {
        VStack(spacing: 24) {
            Text("Your Privacy Matters")
                .font(.title2.bold())
                .foregroundColor(themeManager.textColor)
                .padding(.top, 40)
            
            VStack(spacing: 20) {
                PrivacyFeatureRow(
                    icon: "lock.shield.fill",
                    title: "Stored Securely",
                    description: "Memories are encrypted and stored locally on your device"
                )
                
                PrivacyFeatureRow(
                    icon: "eye.slash.fill",
                    title: "Private to You",
                    description: "Only you can see and manage your memories"
                )
                
                PrivacyFeatureRow(
                    icon: "trash.fill",
                    title: "Full Control",
                    description: "Delete any memory or disable the feature anytime"
                )
                
                PrivacyFeatureRow(
                    icon: "icloud.slash.fill",
                    title: "Optional Sync",
                    description: "Cloud backup is opt-in for signed-in users"
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    private var consentPage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 12) {
                Text("Ready to Begin?")
                    .font(.title2.bold())
                    .foregroundColor(themeManager.textColor)
                
                Text("Enable memory to help TRC AI provide more personalized guidance for your spiritual journey.")
                    .font(.body)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            // Summary box
            VStack(alignment: .leading, spacing: 12) {
                Text("By enabling memory, you agree that:")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                VStack(alignment: .leading, spacing: 8) {
                    ConsentBulletPoint(text: "TRC AI will remember key information from your conversations")
                    ConsentBulletPoint(text: "You can view, edit, or delete memories at any time")
                    ConsentBulletPoint(text: "You can disable this feature in Settings")
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Actions
    
    private func enableMemory() {
        preferencesService.setMemoryEnabled(true)
        preferencesService.markMemoryConsentSeen()
        HapticManager.shared.success()
        dismiss()
    }
    
    private func declineMemory() {
        preferencesService.setMemoryEnabled(false)
        preferencesService.markMemoryConsentSeen()
        dismiss()
    }
}

// MARK: - Supporting Views

struct MemoryFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(themeManager.accentColor)
                .frame(width: 40, height: 40)
                .background(themeManager.accentColor.opacity(0.1))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.textColor)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
        }
    }
}

struct ConsentBulletPoint: View {
    let text: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(themeManager.accentColor)
            Text(text)
                .font(.caption)
                .foregroundColor(themeManager.textColor)
        }
    }
}

// MARK: - Preview

#Preview {
    MemoryConsentSheet()
}


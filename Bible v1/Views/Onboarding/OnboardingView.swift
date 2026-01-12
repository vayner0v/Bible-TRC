//
//  OnboardingView.swift
//  Bible v1
//
//  Main Onboarding Container
//

import SwiftUI

/// Onboarding step enumeration
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case appearance = 1
    case audio = 2
    case account = 3
    case subscription = 4
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .appearance: return "Appearance"
        case .audio: return "Audio"
        case .account: return "Account"
        case .subscription: return "Premium"
        }
    }
}

/// Main onboarding container view
struct OnboardingView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button and progress
                if currentStep != .welcome {
                    HStack {
                        // Back button
                        Button {
                            goToPreviousStep()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.subheadline)
                            .foregroundColor(themeManager.accentColor)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    OnboardingProgressBar(
                        currentStep: currentStep,
                        themeManager: themeManager
                    )
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStepView(onContinue: { goToNextStep() })
                        .tag(OnboardingStep.welcome)
                    
                    AppearanceStepView(onContinue: { goToNextStep() })
                        .tag(OnboardingStep.appearance)
                    
                    AudioStepView(onContinue: { goToNextStep() })
                        .tag(OnboardingStep.audio)
                    
                    AccountStepView(onContinue: { goToNextStep() })
                        .tag(OnboardingStep.account)
                    
                    SubscriptionStepView(onComplete: { completeOnboarding() })
                        .tag(OnboardingStep.subscription)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Navigation
    
    private func goToNextStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = nextStep
            }
        }
        HapticManager.shared.lightImpact()
    }
    
    private func goToPreviousStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prevStep
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeInOut(duration: 0.3)) {
            hasCompletedOnboarding = true
        }
        HapticManager.shared.success()
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Legacy init for compatibility
    init(currentStep: OnboardingStep, themeManager: ThemeManager) {
        self.currentStep = currentStep
    }
    
    // Only show steps 2-5 (appearance, audio, account, subscription)
    private var displaySteps: [OnboardingStep] {
        [.appearance, .audio, .account, .subscription]
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(displaySteps, id: \.rawValue) { step in
                OnboardingProgressSegment(
                    isCompleted: step.rawValue < currentStep.rawValue,
                    isCurrent: step == currentStep
                )
            }
        }
        .frame(height: 4)
    }
}

struct OnboardingProgressSegment: View {
    let isCompleted: Bool
    let isCurrent: Bool
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Capsule()
            .fill(segmentColor)
            .frame(height: 4)
            .animation(.easeInOut(duration: 0.3), value: isCompleted)
            .animation(.easeInOut(duration: 0.3), value: isCurrent)
    }
    
    private var segmentColor: Color {
        if isCompleted {
            return themeManager.accentColor
        } else if isCurrent {
            return themeManager.accentColor.opacity(0.5)
        } else {
            return themeManager.dividerColor
        }
    }
}

// MARK: - Onboarding Button Styles

struct OnboardingPrimaryButton: View {
    let title: String
    var icon: String? = "arrow.right"
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if let icon = icon {
                    Image(systemName: icon)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(themeManager.accentGradient)
            .cornerRadius(16)
        }
    }
}

struct OnboardingSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline)
            .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// Legacy button styles for compatibility
struct OnboardingPrimaryButtonStyle: ButtonStyle {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(themeManager.accentGradient)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OnboardingSecondaryButtonStyle: ButtonStyle {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(themeManager.secondaryTextColor)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}


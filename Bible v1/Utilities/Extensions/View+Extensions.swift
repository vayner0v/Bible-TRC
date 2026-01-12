//
//  View+Extensions.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

// MARK: - Conditional Modifiers

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply different modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Haptic Feedback

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    let generator = UIImpactFeedbackGenerator(style: style)
                    generator.impactOccurred()
                }
        )
    }
    
    func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) -> some View {
        self.onChange(of: UUID()) { _, _ in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        }
    }
}

// MARK: - Accessibility

extension View {
    func accessibleLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }
    
    func accessibleHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }
    
    func accessibleValue(_ value: String) -> some View {
        self.accessibilityValue(value)
    }
    
    func accessibleAction(_ name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }
}

// MARK: - Keyboard

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func onKeyboardAppear(_ action: @escaping (CGFloat) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                action(keyboardFrame.height)
            }
        }
    }
    
    func onKeyboardDisappear(_ action: @escaping () -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            action()
        }
    }
}

// MARK: - Animations

extension View {
    func fadeIn(duration: Double = 0.3) -> some View {
        self
            .opacity(0)
            .animation(.easeIn(duration: duration), value: UUID())
    }
    
    func slideIn(from edge: Edge = .bottom, duration: Double = 0.3) -> some View {
        self
            .transition(.move(edge: edge).combined(with: .opacity))
            .animation(.easeOut(duration: duration), value: UUID())
    }
}

// MARK: - Layout

extension View {
    func centered() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func fullWidth() -> some View {
        self.frame(maxWidth: .infinity)
    }
    
    func fullHeight() -> some View {
        self.frame(maxHeight: .infinity)
    }
}

// MARK: - Card Style

extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(cornerRadius)
    }
    
    func shadowCard(radius: CGFloat = 8) -> some View {
        self
            .shadow(color: Color.black.opacity(0.1), radius: radius, x: 0, y: 4)
    }
}










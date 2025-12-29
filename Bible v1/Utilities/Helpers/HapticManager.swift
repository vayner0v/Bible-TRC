//
//  HapticManager.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import UIKit

/// Manager for haptic feedback
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Haptics
    
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    // MARK: - Notification Haptics
    
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Selection Haptics
    
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // MARK: - Public Methods
    
    /// Light impact feedback (subtle)
    func lightImpact() {
        lightImpactGenerator.impactOccurred()
    }
    
    /// Medium impact feedback
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Heavy impact feedback (strong)
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
    }
    
    /// Soft impact feedback
    func softImpact() {
        softImpactGenerator.impactOccurred()
    }
    
    /// Rigid impact feedback
    func rigidImpact() {
        rigidImpactGenerator.impactOccurred()
    }
    
    /// Success notification feedback
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning notification feedback
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Error notification feedback
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Selection changed feedback
    func selection() {
        selectionGenerator.selectionChanged()
    }
    
    /// Prepare generators for low-latency feedback
    func prepare() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}

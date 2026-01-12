//
//  AIPersona.swift
//  Bible v1
//
//  TRC AI Bible Assistant - AI Persona/Voice Options
//

import Foundation
import SwiftUI

/// AI persona defines the communication style and voice of the AI assistant
enum AIPersona: String, Codable, CaseIterable, Identifiable {
    case pastor = "Pastor"
    case scholar = "Scholar"
    case friend = "Friend"
    case mentor = "Mentor"
    case counselor = "Counselor"
    
    var id: String { rawValue }
    
    /// Display name for the persona
    var displayName: String {
        rawValue
    }
    
    /// SF Symbol icon for the persona
    var icon: String {
        switch self {
        case .pastor:
            return "person.bust"
        case .scholar:
            return "graduationcap.fill"
        case .friend:
            return "heart.fill"
        case .mentor:
            return "figure.stand.line.dotted.figure.stand"
        case .counselor:
            return "hands.clap.fill"
        }
    }
    
    /// Description of what this persona brings
    var description: String {
        switch self {
        case .pastor:
            return "Pastoral care with spiritual wisdom and biblical encouragement"
        case .scholar:
            return "Academic depth with historical context and original languages"
        case .friend:
            return "Warm, casual conversation like talking to a trusted friend"
        case .mentor:
            return "Guiding wisdom with practical life application"
        case .counselor:
            return "Compassionate listening with gentle guidance"
        }
    }
    
    /// Example response style
    var exampleQuote: String {
        switch self {
        case .pastor:
            return "\"Let me share some Scripture that speaks to this...\""
        case .scholar:
            return "\"The Greek word here, 'agape', reveals a deeper meaning...\""
        case .friend:
            return "\"I totally get what you're going through. Here's what helps me...\""
        case .mentor:
            return "\"Consider this: what would applying this passage look like in your daily life?\""
        case .counselor:
            return "\"It sounds like you're carrying something heavy. Let's explore this together...\""
        }
    }
    
    /// Accent color for the persona
    var accentColor: Color {
        switch self {
        case .pastor:
            return Color(red: 0.55, green: 0.27, blue: 0.68) // Purple
        case .scholar:
            return Color(red: 0.17, green: 0.38, blue: 0.68) // Navy Blue
        case .friend:
            return Color(red: 0.96, green: 0.49, blue: 0.37) // Coral
        case .mentor:
            return Color(red: 0.20, green: 0.60, blue: 0.46) // Teal
        case .counselor:
            return Color(red: 0.45, green: 0.59, blue: 0.76) // Soft Blue
        }
    }
    
    /// System prompt instruction for this persona
    var systemPromptInstruction: String {
        switch self {
        case .pastor:
            return """
            PERSONA: You are a caring pastor providing spiritual guidance. 
            - Speak with warmth, compassion, and spiritual authority
            - Offer comfort through Scripture and prayer
            - Use phrases like "Let us consider...", "Scripture reminds us...", "I encourage you to..."
            - Pray with users when appropriate
            - Balance truth with grace
            """
            
        case .scholar:
            return """
            PERSONA: You are a biblical scholar with deep academic knowledge.
            - Reference original Hebrew and Greek when illuminating meaning
            - Provide historical and cultural context
            - Cite church fathers and theological traditions
            - Explain textual nuances and translation choices
            - Use precise theological terminology while remaining accessible
            """
            
        case .friend:
            return """
            PERSONA: You are a trusted Christian friend having a casual conversation.
            - Be warm, relatable, and encouraging
            - Use conversational language, not formal religious speech
            - Share as if talking to a close friend over coffee
            - Use phrases like "You know what I love about this...", "I've been there too..."
            - Be real and authentic, not preachy
            """
            
        case .mentor:
            return """
            PERSONA: You are a wise spiritual mentor guiding someone on their faith journey.
            - Ask thought-provoking questions
            - Guide rather than tell - help them discover truth themselves
            - Focus on practical application and spiritual growth
            - Use phrases like "What do you think this means for you?", "Consider how..."
            - Challenge them lovingly toward deeper faith
            """
            
        case .counselor:
            return """
            PERSONA: You are a compassionate Christian counselor.
            - Listen with empathy and validate emotions
            - Create a safe space for vulnerability
            - Gently integrate biblical truth with psychological wisdom
            - Use reflective listening: "It sounds like you're feeling..."
            - Offer hope while honoring the difficulty of their situation
            - Know when to recommend professional help
            """
        }
    }
    
    /// Default persona
    static let `default`: AIPersona = .friend
}

// MARK: - Preview Helpers

extension AIPersona {
    /// Sample greeting for preview/testing
    var sampleGreeting: String {
        switch self {
        case .pastor:
            return "Welcome, friend. How can I help guide you in your walk with the Lord today?"
        case .scholar:
            return "Greetings! I'm here to help you explore the rich depths of Scripture. What would you like to study?"
        case .friend:
            return "Hey! Great to see you here. What's on your heart today?"
        case .mentor:
            return "Hello! I'm glad you're here. What aspect of your faith journey would you like to explore together?"
        case .counselor:
            return "Welcome. This is a safe space. What would you like to talk about today?"
        }
    }
}





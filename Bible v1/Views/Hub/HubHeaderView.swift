//
//  HubHeaderView.swift
//  Bible v1
//
//  Header component for the Hub with greeting and verse of the day
//

import SwiftUI

/// Header view with greeting and verse of the day
struct HubHeaderView: View {
    let greeting: String
    let summary: String
    let verseText: String
    let verseReference: String
    let onVerseOfDayTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hasAppeared = false
    @State private var verseAppeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Greeting section
            greetingSection
            
            // Verse of the day card
            verseOfDayCard
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                hasAppeared = true
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
                verseAppeared = true
            }
        }
    }
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Date
            Text(Date(), format: .dateTime.weekday(.wide).month().day())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.accentColor)
                .textCase(.uppercase)
                .tracking(1.2)
            
            // Greeting
            Text(greeting)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(themeManager.textColor)
            
            // Summary
            Text(summary)
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(2)
        }
    }
    
    private var verseOfDayCard: some View {
        Button(action: onVerseOfDayTap) {
            HStack(alignment: .top, spacing: 14) {
                // Quote icon with glow
                ZStack {
                    Circle()
                        .fill(themeManager.hubGlowColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .blur(radius: 4)
                    
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundColor(themeManager.hubGlowColor)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verse of the Day")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    
                    Text(verseText)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(3)
                        .italic()
                    
                    Text("— \(verseReference)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.hubElevatedSurface)
                    .shadow(
                        color: themeManager.hubShadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeManager.hubGlowColor.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(TilePressStyle())
        .opacity(verseAppeared ? 1 : 0)
        .offset(y: verseAppeared ? 0 : 10)
    }
}

#Preview {
    ScrollView {
        HubHeaderView(
            greeting: "Good Morning",
            summary: "Today: 3 habits, 2 gratitudes",
            verseText: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you.",
            verseReference: "Jeremiah 29:11",
            onVerseOfDayTap: {}
        )
        .padding()
    }
    .background(Color(.systemBackground))
}








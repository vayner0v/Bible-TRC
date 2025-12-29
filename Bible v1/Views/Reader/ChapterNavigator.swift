//
//  ChapterNavigator.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// Navigation bar for chapter browsing
struct ChapterNavigator: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let onBookTap: () -> Void
    let onChapterTap: () -> Void
    let onTranslationTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Previous chapter button
            Button {
                Task {
                    await viewModel.previousChapter()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.hasPreviousChapter ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .disabled(!viewModel.hasPreviousChapter)
            
            Spacer()
            
            // Book and chapter selector
            HStack(spacing: 8) {
                // Book name - uses short name for long books, scales down if still needed
                Button(action: onBookTap) {
                    Text(viewModel.selectedBook?.shortName ?? "Select Book")
                        .font(.headline)
                        .foregroundColor(themeManager.textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
                
                // Chapter number
                Button(action: onChapterTap) {
                    Text("\(viewModel.currentChapterNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(themeManager.accentColor.opacity(0.12))
                        .cornerRadius(10)
                }
                .fixedSize()
            }
            
            Spacer()
            
            // Next chapter button
            Button {
                Task {
                    await viewModel.nextChapter()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(viewModel.hasNextChapter ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .disabled(!viewModel.hasNextChapter)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(themeManager.cardBackgroundColor)
    }
}

/// Compact chapter navigation for toolbar
struct CompactChapterNavigator: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(viewModel.shortReference)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }
}

/// Translation badge button
struct TranslationBadge: View {
    let translation: Translation?
    @ObservedObject private var themeManager = ThemeManager.shared
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(translation?.id ?? "Select")
                    .font(.caption)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(themeManager.accentColor.opacity(0.15))
            .foregroundColor(themeManager.accentColor)
            .cornerRadius(14)
        }
    }
}

/// Swipe gesture handler for chapter navigation
struct ChapterSwipeGesture: ViewModifier {
    @ObservedObject var viewModel: BibleViewModel
    @State private var isDragging = false
    
    func body(content: Content) -> some View {
        content
            .highPriorityGesture(
                DragGesture(minimumDistance: 50)
                    .onChanged { value in
                        // Only recognize as swipe if horizontal movement is at least 2x vertical
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        if horizontalAmount > verticalAmount * 2 && horizontalAmount > 50 {
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        guard isDragging else { 
                            isDragging = false
                            return 
                        }
                        
                        let horizontalAmount = value.translation.width
                        let velocity = value.velocity.width
                        
                        // Require significant distance (100pt) OR high velocity swipe
                        let isSignificantSwipe = abs(horizontalAmount) > 100 || abs(velocity) > 500
                        
                        if isSignificantSwipe {
                            if (horizontalAmount < -100 || velocity < -500) && viewModel.hasNextChapter {
                                // Swipe left - next chapter
                                HapticManager.shared.mediumImpact()
                                Task {
                                    await viewModel.nextChapter()
                                }
                            } else if (horizontalAmount > 100 || velocity > 500) && viewModel.hasPreviousChapter {
                                // Swipe right - previous chapter
                                HapticManager.shared.mediumImpact()
                                Task {
                                    await viewModel.previousChapter()
                                }
                            }
                        }
                        isDragging = false
                    }
            )
    }
}

extension View {
    func chapterSwipeNavigation(viewModel: BibleViewModel) -> some View {
        modifier(ChapterSwipeGesture(viewModel: viewModel))
    }
}

#Preview {
    VStack {
        ChapterNavigator(
            viewModel: BibleViewModel(),
            onBookTap: {},
            onChapterTap: {},
            onTranslationTap: {}
        )
        
        Divider()
        
        HStack {
            CompactChapterNavigator(viewModel: BibleViewModel(), onTap: {})
            Spacer()
            TranslationBadge(translation: nil, onTap: {})
        }
        .padding()
    }
}

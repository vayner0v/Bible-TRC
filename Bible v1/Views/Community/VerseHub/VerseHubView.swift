//
//  VerseHubView.swift
//  Bible v1
//
//  Community Tab - Verse Hub View (Community Reflections on Verses)
//

import SwiftUI

struct VerseHubView: View {
    @StateObject private var viewModel: VerseHubViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    init(book: String, chapter: Int, verse: Int, translationId: String = "KJV") {
        _viewModel = StateObject(wrappedValue: VerseHubViewModel(
            book: book,
            chapter: chapter,
            verse: verse,
            translationId: translationId
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Verse Card
                verseCard
                
                // Section Selector
                sectionSelector
                
                // Posts
                postsSection
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
        .navigationTitle("Verse Hub")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.openComposer()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .sheet(isPresented: $viewModel.showComposer) {
            PostComposerView()
        }
        .task {
            await viewModel.load()
        }
    }
    
    // MARK: - Verse Card
    
    private var verseCard: some View {
        VStack(spacing: 16) {
            // Reference
            Text(viewModel.fullReference)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(themeManager.accentColor)
            
            // Verse Text (placeholder - would load from Bible service)
            Text("\"For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.\"")
                .font(.system(size: 16, design: .serif))
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .italic()
            
            // Stats
            if let hubData = viewModel.hubData {
                HStack(spacing: 20) {
                    statItem(count: hubData.reflections.count, label: "Reflections", icon: "text.quote")
                    statItem(count: hubData.questions.count, label: "Questions", icon: "questionmark.circle")
                    statItem(count: hubData.prayers.count, label: "Prayers", icon: "hands.sparkles")
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [themeManager.accentColor.opacity(0.1), themeManager.backgroundColor.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func statItem(count: Int, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.accentColor)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.textColor)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(themeManager.textColor.opacity(0.6))
        }
    }
    
    // MARK: - Section Selector
    
    private var sectionSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VerseHubSection.allCases) { section in
                    sectionButton(section)
                }
            }
        }
    }
    
    private func sectionButton(_ section: VerseHubSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSection = section
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.icon)
                    .font(.system(size: 14))
                Text(section.displayName)
                    .font(.system(size: 14, weight: .medium))
                
                // Count badge
                if viewModel.sectionCount > 0 {
                    Text("\(viewModel.sectionCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(themeManager.accentColor)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(viewModel.selectedSection == section ? .white : themeManager.textColor.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(viewModel.selectedSection == section ? themeManager.accentColor : themeManager.backgroundColor.opacity(0.3))
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Posts Section
    
    @ViewBuilder
    private var postsSection: some View {
        if viewModel.isLoading {
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    PostCardSkeleton()
                }
            }
        } else if viewModel.sectionPosts.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sectionPosts) { post in
                    PostCardView(post: post)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.selectedSection.icon)
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.3))
            
            Text(viewModel.selectedSection.emptyMessage)
                .font(.system(size: 15))
                .foregroundColor(themeManager.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.openComposer()
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create First \(viewModel.selectedSection.displayName)")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(themeManager.accentColor)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        VerseHubView(book: "John", chapter: 3, verse: 16)
    }
    .environmentObject(ThemeManager.shared)
}


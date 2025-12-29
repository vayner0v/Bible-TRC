//
//  BookPicker.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import SwiftUI

/// A beautifully redesigned picker for selecting Bible books and chapters
struct BookPicker: View {
    @ObservedObject var viewModel: BibleViewModel
    var autoExpandCurrentBook: Bool = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedTestament: Testament = .old
    @State private var searchText = ""
    @State private var expandedBookId: String? = nil
    @State private var hasAutoExpanded = false
    @Namespace private var animation
    
    private var filteredBooks: [Book] {
        let testamentBooks = selectedTestament == .old
            ? viewModel.oldTestamentBooks
            : viewModel.newTestamentBooks
        
        if searchText.isEmpty {
            return testamentBooks
        }
        
        return testamentBooks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Full background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                headerView
                
                // Testament toggle
                testamentToggle
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // Search bar
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Books list
                if viewModel.isLoadingBooks {
                    Spacer()
                    LoadingView("Loading books...")
                    Spacer()
                } else if filteredBooks.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    booksScrollView
                }
            }
        }
        .onAppear {
            // Set initial testament based on current book
            if let currentBook = viewModel.selectedBook {
                selectedTestament = viewModel.oldTestamentBooks.contains(where: { $0.id == currentBook.id }) ? .old : .new
                
                // Auto-expand current book if requested
                if autoExpandCurrentBook && !hasAutoExpanded {
                    expandedBookId = currentBook.id
                    hasAutoExpanded = true
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(width: 36, height: 36)
                    .background(themeManager.cardBackgroundColor)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Select Book")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Testament Toggle
    
    private var testamentToggle: some View {
        HStack(spacing: 0) {
            ForEach(Testament.allCases, id: \.self) { testament in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTestament = testament
                        expandedBookId = nil
                    }
                    HapticManager.shared.lightImpact()
                } label: {
                    VStack(spacing: 4) {
                        Text(testament.displayName)
                            .font(.system(size: 15, weight: selectedTestament == testament ? .bold : .medium))
                            .foregroundColor(selectedTestament == testament ? .white : themeManager.secondaryTextColor)
                        
                        Text("\(testament == .old ? viewModel.oldTestamentBooks.count : viewModel.newTestamentBooks.count) books")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selectedTestament == testament ? .white.opacity(0.8) : themeManager.secondaryTextColor.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        if selectedTestament == testament {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(themeManager.accentColor)
                                .matchedGeometryEffect(id: "testamentPill", in: animation)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(themeManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeManager.secondaryTextColor)
            
            TextField("Search books...", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(themeManager.textColor)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeManager.cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            Text("No books found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    // MARK: - Books Scroll View
    
    private var booksScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredBooks) { book in
                    BookCard(
                        book: book,
                        isSelected: book.id == viewModel.selectedBook?.id,
                        isExpanded: expandedBookId == book.id,
                        currentChapter: book.id == viewModel.selectedBook?.id ? viewModel.currentChapterNumber : nil,
                        themeManager: themeManager,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedBookId == book.id {
                                    expandedBookId = nil
                                } else {
                                    expandedBookId = book.id
                                }
                            }
                            HapticManager.shared.lightImpact()
                        },
                        onChapterSelect: { chapter in
                            selectBook(book, chapter: chapter)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }
    
    private func selectBook(_ book: Book, chapter: Int = 1) {
        HapticManager.shared.mediumImpact()
        Task {
            await viewModel.selectBook(book, chapter: chapter)
            dismiss()
        }
    }
}

// MARK: - Book Card

struct BookCard: View {
    let book: Book
    let isSelected: Bool
    let isExpanded: Bool
    let currentChapter: Int?
    let themeManager: ThemeManager
    let onTap: () -> Void
    let onChapterSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Book icon with gradient background
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                isSelected
                                    ? themeManager.accentColor.opacity(0.15)
                                    : themeManager.cardBackgroundColor
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
                    }
                    
                    // Book info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor)
                            .lineLimit(1)
                        
                        Text("\(book.numberOfChapters) chapter\(book.numberOfChapters == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.hubElevatedSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? themeManager.accentColor.opacity(0.3) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: themeManager.hubShadowColor, radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            
            // Chapter grid when expanded
            if isExpanded {
                VStack(spacing: 16) {
                    // Divider
                    Rectangle()
                        .fill(themeManager.dividerColor)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                    
                    Text("Select Chapter")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.secondaryTextColor)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    // Chapter grid
                    ChapterGridView(
                        numberOfChapters: book.numberOfChapters,
                        currentChapter: currentChapter,
                        themeManager: themeManager,
                        onSelect: onChapterSelect
                    )
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.cardBackgroundColor)
                )
                .padding(.top, -8)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }
}

// MARK: - Chapter Grid View

struct ChapterGridView: View {
    let numberOfChapters: Int
    let currentChapter: Int?
    let themeManager: ThemeManager
    let onSelect: (Int) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(1...numberOfChapters, id: \.self) { chapter in
                Button {
                    onSelect(chapter)
                } label: {
                    Text("\(chapter)")
                        .font(.system(size: 15, weight: chapter == currentChapter ? .bold : .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    chapter == currentChapter
                                        ? themeManager.accentColor
                                        : themeManager.hubElevatedSurface
                                )
                        )
                        .foregroundColor(
                            chapter == currentChapter
                                ? .white
                                : themeManager.textColor
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    chapter == currentChapter
                                        ? Color.clear
                                        : themeManager.dividerColor,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Quick chapter picker sheet
struct ChapterPickerSheet: View {
    @ObservedObject var viewModel: BibleViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Spacer for drag indicator
                Color.clear.frame(height: 8)
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedBook?.displayName ?? "Chapters")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(themeManager.textColor)
                        
                        Text("Select a chapter")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.secondaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(themeManager.cardBackgroundColor)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Divider
                Rectangle()
                    .fill(themeManager.dividerColor)
                    .frame(height: 1)
                
                // Chapter grid
                ScrollView {
                    if let book = viewModel.selectedBook {
                        ChapterGridView(
                            numberOfChapters: book.numberOfChapters,
                            currentChapter: viewModel.currentChapterNumber,
                            themeManager: themeManager
                        ) { chapter in
                            HapticManager.shared.mediumImpact()
                            Task {
                                await viewModel.goToChapter(chapter)
                                dismiss()
                            }
                        }
                        .padding(24)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Legacy Support

/// A themed grid of chapter numbers (legacy support)
struct ThemedChapterGrid: View {
    let numberOfChapters: Int
    let currentChapter: Int?
    let themeManager: ThemeManager
    let onSelect: (Int) -> Void
    
    var body: some View {
        ChapterGridView(
            numberOfChapters: numberOfChapters,
            currentChapter: currentChapter,
            themeManager: themeManager,
            onSelect: onSelect
        )
    }
}

// Keep old ChapterGrid for backward compatibility
struct ChapterGrid: View {
    let numberOfChapters: Int
    let currentChapter: Int?
    var onSelect: ((Int) -> Void)?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...numberOfChapters, id: \.self) { chapter in
                Button {
                    onSelect?(chapter)
                } label: {
                    Text("\(chapter)")
                        .font(.subheadline)
                        .fontWeight(chapter == currentChapter ? .bold : .regular)
                        .frame(width: 44, height: 44)
                        .background(
                            chapter == currentChapter
                                ? Color.accentColor
                                : Color(.secondarySystemBackground)
                        )
                        .foregroundColor(chapter == currentChapter ? .white : .primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Keep old BookRow for backward compatibility
struct BookRow: View {
    let book: Book
    let isSelected: Bool
    let currentChapter: Int?
    
    var body: some View {
        HStack {
            Text(book.displayName)
                .font(.headline)
                .foregroundColor(isSelected ? .accentColor : .primary)
            
            Spacer()
            
            Text("\(book.numberOfChapters) ch")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
    }
}

// Legacy BookRowSimple for compatibility
struct BookRowSimple: View {
    let book: Book
    let isSelected: Bool
    let themeManager: ThemeManager
    let onSelect: () -> Void
    let onChapterSelect: (Int) -> Void
    
    var body: some View {
        BookCard(
            book: book,
            isSelected: isSelected,
            isExpanded: false,
            currentChapter: nil,
            themeManager: themeManager,
            onTap: onSelect,
            onChapterSelect: onChapterSelect
        )
    }
}

#Preview {
    BookPicker(viewModel: BibleViewModel())
}

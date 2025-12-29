//
//  JournalEntryDetailView.swift
//  Bible v1
//
//  Spiritual Journal - Entry Detail View
//

import SwiftUI

/// Detailed view of a journal entry
struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject var favoritesViewModel: FavoritesViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var selectedPhotoIndex: Int?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        headerSection
                        
                        // Content
                        contentSection
                        
                        // Linked verses
                        if !entry.linkedVerses.isEmpty {
                            linkedVersesSection
                        }
                        
                        // Photos
                        if entry.hasPhotos {
                            photosSection
                        }
                        
                        // Metadata
                        metadataSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.startEditing(entry)
                            showingEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button {
                            viewModel.toggleFavorite(entry)
                        } label: {
                            Label(
                                entry.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: entry.isFavorite ? "heart.slash" : "heart"
                            )
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                JournalEntryEditorView(
                    viewModel: viewModel,
                    favoritesViewModel: favoritesViewModel,
                    isPresented: $showingEditSheet
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [shareText])
            }
            .fullScreenCover(item: Binding(
                get: { selectedPhotoIndex.map { PhotoViewerItem(index: $0) } },
                set: { selectedPhotoIndex = $0?.index }
            )) { item in
                PhotoViewer(
                    photoFileNames: entry.photoFileNames,
                    initialIndex: item.index,
                    viewModel: viewModel
                )
            }
            .alert("Delete Entry?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteEntry(entry)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and favorite
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.dayOfWeek)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(entry.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                if entry.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            // Title
            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
            }
            
            // Mood and tags
            HStack(spacing: 12) {
                if let mood = entry.mood {
                    HStack(spacing: 6) {
                        Image(systemName: mood.icon)
                        Text(mood.displayName)
                    }
                    .font(.subheadline)
                    .foregroundColor(mood.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(mood.lightColor)
                    .cornerRadius(20)
                }
                
                Spacer()
            }
            
            // Tags
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.tags) { tag in
                            HStack(spacing: 6) {
                                Image(systemName: tag.icon)
                                    .font(.caption)
                                Text(tag.name)
                                    .font(.caption)
                            }
                            .foregroundColor(tag.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(tag.lightColor)
                            .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Prompt used (if any)
            if let prompt = entry.promptUsed {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: prompt.category.icon)
                            .font(.caption)
                        Text("Prompt: \(prompt.category.displayName)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(prompt.category.color)
                    
                    Text(prompt.text)
                        .font(.caption)
                        .italic()
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding()
                .background(prompt.category.color.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Content - rendered with formatting
            FormattedTextView(content: entry.content)
        }
    }
    
    private var linkedVersesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linked Verses")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            ForEach(entry.linkedVerses) { verse in
                VStack(alignment: .leading, spacing: 8) {
                    Text(verse.shortReference)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                    
                    Text(verse.text)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor)
                        .italic()
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(12)
            }
        }
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(entry.photoFileNames.enumerated()), id: \.element) { index, fileName in
                    PhotoGridItem(
                        fileName: fileName,
                        photoURL: viewModel.photoURL(for: fileName)
                    )
                    .onTapGesture {
                        selectedPhotoIndex = index
                    }
                }
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            HStack {
                Text("Created")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                Spacer()
                Text(entry.dateCreated.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            if entry.dateModified != entry.dateCreated {
                HStack {
                    Text("Modified")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    Spacer()
                    Text(entry.dateModified.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            HStack {
                Text("Word count")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                Spacer()
                Text("\(entry.wordCount)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.top, 12)
    }
    
    private var shareText: String {
        var text = ""
        if !entry.title.isEmpty {
            text += "\(entry.title)\n\n"
        }
        text += entry.content
        if !entry.linkedVerses.isEmpty {
            text += "\n\n---\n"
            for verse in entry.linkedVerses {
                text += "\(verse.fullReference)\n"
            }
        }
        return text
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let fileName: String
    let photoURL: URL?
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 100)
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = photoURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }
    }
}

// MARK: - Photo Viewer

struct PhotoViewerItem: Identifiable {
    let index: Int
    var id: Int { index }
}

struct PhotoViewer: View {
    let photoFileNames: [String]
    let initialIndex: Int
    let viewModel: JournalViewModel
    
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    init(photoFileNames: [String], initialIndex: Int, viewModel: JournalViewModel) {
        self.photoFileNames = photoFileNames
        self.initialIndex = initialIndex
        self.viewModel = viewModel
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(photoFileNames.enumerated()), id: \.element) { index, fileName in
                    FullSizePhoto(
                        fileName: fileName,
                        photoURL: viewModel.photoURL(for: fileName)
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page)
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                Spacer()
                
                Text("\(currentIndex + 1) of \(photoFileNames.count)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.bottom)
            }
        }
    }
}

struct FullSizePhoto: View {
    let fileName: String
    let photoURL: URL?
    
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = value
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        scale = max(1.0, min(scale, 3.0))
                                    }
                                }
                        )
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = photoURL else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = loadedImage
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    JournalEntryDetailView(
        entry: JournalEntry(
            title: "Morning Reflection",
            content: "Today I spent time meditating on Psalm 23. The Lord is my shepherd, I shall not want...",
            mood: .peaceful,
            tags: [JournalTag.defaultTags[0], JournalTag.defaultTags[2]]
        ),
        viewModel: JournalViewModel(),
        favoritesViewModel: FavoritesViewModel()
    )
}


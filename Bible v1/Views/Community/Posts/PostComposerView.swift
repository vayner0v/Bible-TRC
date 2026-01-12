//
//  PostComposerView.swift
//  Bible v1
//
//  Community Tab - Post Composer View
//

import SwiftUI
import PhotosUI

struct PostComposerView: View {
    @StateObject private var viewModel = PostComposerViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Post Type Selector
                    postTypeSelector
                    
                    // Content Area
                    contentArea
                    
                    // Verse Attachment
                    verseSection
                    
                    // Media Section (for image posts)
                    if viewModel.postType == .image {
                        mediaSection
                    }
                    
                    // Additional Options
                    optionsSection
                    
                    // Tags
                    tagsSection
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.textColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if let _ = await viewModel.publish() {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canPost || viewModel.isLoading)
                    .foregroundColor(viewModel.canPost ? themeManager.accentColor : themeManager.textColor.opacity(0.3))
                }
            }
            .sheet(isPresented: $viewModel.showVersePicker) {
                VersePicker { verse, text in
                    viewModel.selectVerse(verse, text: text)
                }
            }
        }
    }
    
    // MARK: - Post Type Selector
    
    private var postTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PostType.allCases) { type in
                    postTypeButton(type)
                }
            }
        }
    }
    
    private func postTypeButton(_ type: PostType) -> some View {
        Button {
            viewModel.postType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(width: 70, height: 60)
            .foregroundColor(viewModel.postType == type ? .white : type.color)
            .background(viewModel.postType == type ? type.color : type.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Content Area
    
    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $viewModel.content)
                .frame(minHeight: 150)
                .padding(12)
                .background(themeManager.backgroundColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.textColor.opacity(0.1), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.content.isEmpty {
                        Text(placeholderText)
                            .foregroundColor(themeManager.textColor.opacity(0.4))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
            
            // Character count
            HStack {
                Spacer()
                Text("\(viewModel.characterCount)/\(viewModel.characterLimit)")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.isOverLimit ? .red : themeManager.textColor.opacity(0.5))
            }
        }
    }
    
    private var placeholderText: String {
        switch viewModel.postType {
        case .reflection: return "Share your thoughts on scripture..."
        case .question: return "Ask the community a question..."
        case .prayer: return "Share your prayer request..."
        case .testimony: return "Share what God has done in your life..."
        case .image: return "Add a caption..."
        case .verseCard: return "Add a reflection for this verse..."
        }
    }
    
    // MARK: - Verse Section
    
    private var verseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(themeManager.accentColor)
                Text(viewModel.postType.requiresVerse ? "Verse (Required)" : "Attach Verse")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textColor)
            }
            
            if let verse = viewModel.selectedVerse {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.fullReference)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(themeManager.accentColor)
                        
                        if let text = viewModel.verseText {
                            Text(text)
                                .font(.system(size: 13))
                                .foregroundColor(themeManager.textColor.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.clearVerse()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.textColor.opacity(0.4))
                    }
                }
                .padding()
                .background(themeManager.accentColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Button {
                    viewModel.showVersePicker = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Select a verse")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.backgroundColor.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                }
            }
        }
    }
    
    // MARK: - Media Section
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Images")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Selected images
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: viewModel.selectedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button {
                                viewModel.removeImage(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: 5, y: -5)
                        }
                    }
                    
                    // Add image button
                    if viewModel.selectedImages.count < 4 {
                        PhotosPicker(selection: $viewModel.imageSelections, maxSelectionCount: 4 - viewModel.selectedImages.count, matching: .images) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                            }
                            .frame(width: 100, height: 100)
                            .background(themeManager.backgroundColor.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(themeManager.textColor.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .onChange(of: viewModel.imageSelections) { _, _ in
                            Task {
                                await viewModel.processImageSelections()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(spacing: 12) {
            // Visibility
            HStack {
                Image(systemName: viewModel.visibility.icon)
                    .foregroundColor(themeManager.accentColor)
                
                Text(viewModel.visibility.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
                
                Picker("", selection: $viewModel.visibility) {
                    ForEach(PostVisibility.allCases, id: \.self) { visibility in
                        Text(visibility.displayName).tag(visibility)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(themeManager.backgroundColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Anonymous toggle (if supported)
            if viewModel.postType.supportsAnonymous {
                Toggle(isOn: $viewModel.isAnonymous) {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                            .foregroundColor(themeManager.accentColor)
                        Text("Post Anonymously")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.textColor)
                    }
                }
                .padding()
                .background(themeManager.backgroundColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Allow comments toggle
            Toggle(isOn: $viewModel.allowComments) {
                HStack {
                    Image(systemName: "bubble.right")
                        .foregroundColor(themeManager.accentColor)
                    Text("Allow Comments")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.textColor)
                }
            }
            .padding()
            .background(themeManager.backgroundColor.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Tags")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textColor)
            }
            
            // Current tags
            if !viewModel.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .font(.system(size: 13, weight: .medium))
                                
                                Button {
                                    viewModel.removeTag(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(themeManager.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(themeManager.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Add tag
            if viewModel.tags.count < 5 {
                HStack {
                    TextField("Add tag", text: $viewModel.newTag)
                        .font(.system(size: 14))
                        .textFieldStyle(.plain)
                        .onSubmit {
                            viewModel.addTag()
                        }
                    
                    Button {
                        viewModel.addTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                    }
                    .disabled(viewModel.newTag.isEmpty)
                }
                .padding()
                .background(themeManager.backgroundColor.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Verse Picker Placeholder

struct VersePicker: View {
    let onSelect: (PostVerseRef, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Verse Picker")
                    .font(.title2)
                
                Text("Select a verse from your Bible")
                    .foregroundColor(themeManager.textColor.opacity(0.6))
                
                // Placeholder - would integrate with existing verse selection
                Button("Select John 3:16") {
                    let verse = PostVerseRef(
                        book: "John",
                        chapter: 3,
                        startVerse: 16,
                        endVerse: nil,
                        translationId: "KJV"
                    )
                    onSelect(verse, "For God so loved the world...")
                }
                .padding()
            }
            .navigationTitle("Select Verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PostComposerView()
        .environmentObject(ThemeManager.shared)
}


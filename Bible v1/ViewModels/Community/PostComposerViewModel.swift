//
//  PostComposerViewModel.swift
//  Bible v1
//
//  Community Tab - Post Composer View Model
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

@MainActor
final class PostComposerViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var postType: PostType = .reflection
    @Published var content = ""
    @Published var selectedVerse: PostVerseRef?
    @Published var verseText: String?
    @Published var reflectionType: ReflectionType?
    @Published var tone: PostTone?
    @Published var tags: [String] = []
    @Published var newTag = ""
    @Published var visibility: PostVisibility = .public
    @Published var isAnonymous = false
    @Published var allowComments = true
    @Published var selectedGroup: CommunityGroup?
    
    // Media
    @Published var selectedImages: [UIImage] = []
    @Published var imageSelections: [PhotosPickerItem] = []
    
    // Verse Card
    @Published var verseCardConfig: VerseCardConfig = .default
    
    // Prayer specific
    @Published var prayerCategory: CommunityPrayerCategory = .other
    @Published var prayerUrgency: CommunityPrayerUrgency = .normal
    @Published var prayerDurationDays = 7
    
    // State
    @Published var isLoading = false
    @Published var error: CommunityError?
    @Published var showVersePicker = false
    @Published var showGroupPicker = false
    @Published var showPreview = false
    
    // MARK: - Properties
    
    private var postService: PostService { CommunityService.shared.postService }
    private var currentUserId: UUID? { CommunityService.shared.currentProfile?.id }
    
    var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        (postType == .verseCard && selectedVerse != nil) ||
        (postType == .image && !selectedImages.isEmpty)
    }
    
    var characterCount: Int {
        content.count
    }
    
    var characterLimit: Int {
        postType == .verseCard ? 500 : 2000
    }
    
    var isOverLimit: Bool {
        characterCount > characterLimit
    }
    
    // MARK: - Initialization
    
    init(initialType: PostType? = nil, initialVerse: PostVerseRef? = nil) {
        if let type = initialType {
            self.postType = type
        }
        if let verse = initialVerse {
            self.selectedVerse = verse
        }
    }
    
    // MARK: - Public Methods
    
    /// Create and publish the post
    func publish() async -> Post? {
        guard canPost, !isLoading else { return nil }
        
        isLoading = true
        defer { isLoading = false }
        
        // Upload images if needed
        let mediaUrls: [String] = []
        // TODO: Implement image upload to Supabase Storage
        
        do {
            let request = CreatePostRequest(
                type: postType,
                content: content,
                verseRef: selectedVerse,
                reflectionType: reflectionType,
                tone: tone,
                tags: tags,
                mediaUrls: mediaUrls,
                verseCardConfig: postType == .verseCard ? verseCardConfig : nil,
                visibility: selectedGroup != nil ? .group : visibility,
                groupId: selectedGroup?.id,
                isAnonymous: isAnonymous,
                allowComments: allowComments
            )
            
            let post = try await CommunityService.shared.createPost(request)
            
            // Add to feed
            CommunityService.shared.feedService.addPost(post)
            
            return post
        } catch {
            self.error = error as? CommunityError ?? .unknown(error.localizedDescription)
            return nil
        }
    }
    
    /// Add a tag
    func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "#", with: "")
        
        guard !tag.isEmpty, !tags.contains(tag), tags.count < 5 else {
            newTag = ""
            return
        }
        
        tags.append(tag)
        newTag = ""
    }
    
    /// Remove a tag
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    /// Select verse
    func selectVerse(_ verse: PostVerseRef, text: String?) {
        selectedVerse = verse
        verseText = text
        showVersePicker = false
    }
    
    /// Clear verse
    func clearVerse() {
        selectedVerse = nil
        verseText = nil
    }
    
    /// Select group
    func selectGroup(_ group: CommunityGroup?) {
        selectedGroup = group
        if group != nil {
            visibility = .group
        }
        showGroupPicker = false
    }
    
    /// Process selected images
    func processImageSelections() async {
        selectedImages = []
        
        for item in imageSelections {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }
    
    /// Remove image
    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        imageSelections.remove(at: index)
    }
    
    /// Reset composer
    func reset() {
        content = ""
        selectedVerse = nil
        verseText = nil
        reflectionType = nil
        tone = nil
        tags = []
        visibility = .public
        isAnonymous = false
        selectedImages = []
        imageSelections = []
        selectedGroup = nil
        verseCardConfig = .default
        prayerCategory = .other
        prayerUrgency = .normal
        prayerDurationDays = 7
    }
    
    /// Check content for violations
    func checkContent() -> ContentCheckResult {
        CommunityService.shared.moderationService.checkContent(content)
    }
}


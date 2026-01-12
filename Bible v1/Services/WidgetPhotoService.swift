//
//  WidgetPhotoService.swift
//  Bible v1
//
//  Service for managing photo backgrounds in widgets
//  Handles photo selection, processing, and storage in App Group
//

import Foundation
import SwiftUI
import PhotosUI
import UIKit
import Combine

// MARK: - Widget Photo Service

/// Service for managing widget photo backgrounds
@MainActor
final class WidgetPhotoService: ObservableObject {
    static let shared = WidgetPhotoService()
    
    // MARK: - Published Properties
    
    @Published private(set) var savedPhotos: [WidgetPhoto] = []
    @Published private(set) var isProcessing = false
    @Published var processingError: String?
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let maxPhotoCount = 50
    private let maxImageDimension: CGFloat = 1000 // Max dimension for storage
    private let compressionQuality: CGFloat = 0.8
    
    private var containerURL: URL? {
        fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppGroupConstants.suiteName)
    }
    
    private var imagesFolder: URL? {
        guard let container = containerURL else { return nil }
        return container.appendingPathComponent(AppGroupConstants.widgetImagesFolder)
    }
    
    private var metadataURL: URL? {
        guard let folder = imagesFolder else { return nil }
        return folder.appendingPathComponent("metadata.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        setupImagesFolder()
        loadSavedPhotos()
    }
    
    // MARK: - Public Methods
    
    /// Save a photo from PhotosPickerItem
    func savePhoto(from item: PhotosPickerItem, name: String? = nil) async throws -> WidgetPhoto {
        isProcessing = true
        processingError = nil
        
        defer { isProcessing = false }
        
        // Load image data
        guard let data = try await item.loadTransferable(type: Data.self),
              let originalImage = UIImage(data: data) else {
            let error = "Failed to load image data"
            processingError = error
            throw WidgetPhotoError.loadFailed
        }
        
        return try await processAndSaveImage(originalImage, name: name)
    }
    
    /// Save a UIImage directly
    func savePhoto(from image: UIImage, name: String? = nil) async throws -> WidgetPhoto {
        isProcessing = true
        processingError = nil
        
        defer { isProcessing = false }
        
        return try await processAndSaveImage(image, name: name)
    }
    
    /// Delete a saved photo
    func deletePhoto(_ photo: WidgetPhoto) {
        guard let folder = imagesFolder else { return }
        
        let imageURL = folder.appendingPathComponent("\(photo.id).jpg")
        let thumbnailURL = folder.appendingPathComponent("\(photo.id)_thumb.jpg")
        
        try? fileManager.removeItem(at: imageURL)
        try? fileManager.removeItem(at: thumbnailURL)
        
        savedPhotos.removeAll { $0.id == photo.id }
        saveMetadata()
    }
    
    /// Delete photo by ID
    func deletePhoto(withId id: String) {
        guard let photo = savedPhotos.first(where: { $0.id == id }) else { return }
        deletePhoto(photo)
    }
    
    /// Get full-size image for a photo
    func getImage(for photo: WidgetPhoto) -> UIImage? {
        guard let folder = imagesFolder else { return nil }
        let imageURL = folder.appendingPathComponent("\(photo.id).jpg")
        
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// Get thumbnail for a photo
    func getThumbnail(for photo: WidgetPhoto) -> UIImage? {
        guard let folder = imagesFolder else { return nil }
        let thumbnailURL = folder.appendingPathComponent("\(photo.id)_thumb.jpg")
        
        guard let data = try? Data(contentsOf: thumbnailURL) else { return nil }
        return UIImage(data: data)
    }
    
    /// Get image URL for widget extension
    func getImageURL(for photoId: String) -> URL? {
        guard let folder = imagesFolder else { return nil }
        return folder.appendingPathComponent("\(photoId).jpg")
    }
    
    /// Rename a photo
    func renamePhoto(_ photo: WidgetPhoto, to newName: String) {
        guard let index = savedPhotos.firstIndex(where: { $0.id == photo.id }) else { return }
        savedPhotos[index].name = newName
        saveMetadata()
    }
    
    /// Mark photo as recently used
    func markAsUsed(_ photoId: String) {
        guard let index = savedPhotos.firstIndex(where: { $0.id == photoId }) else { return }
        savedPhotos[index].lastUsedAt = Date()
        savedPhotos[index].useCount += 1
        saveMetadata()
    }
    
    /// Get recently used photos
    var recentPhotos: [WidgetPhoto] {
        savedPhotos
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(10)
            .map { $0 }
    }
    
    /// Check if we can add more photos
    var canAddMore: Bool {
        savedPhotos.count < maxPhotoCount
    }
    
    /// Available storage space
    var availableCount: Int {
        max(0, maxPhotoCount - savedPhotos.count)
    }
    
    // MARK: - Private Methods
    
    private func setupImagesFolder() {
        guard let folder = imagesFolder else { return }
        
        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
    }
    
    private func loadSavedPhotos() {
        guard let metadataURL = metadataURL,
              let data = try? Data(contentsOf: metadataURL),
              let photos = try? JSONDecoder().decode([WidgetPhoto].self, from: data) else {
            savedPhotos = []
            return
        }
        savedPhotos = photos
    }
    
    private func saveMetadata() {
        guard let metadataURL = metadataURL else { return }
        
        if let data = try? JSONEncoder().encode(savedPhotos) {
            try? data.write(to: metadataURL)
        }
    }
    
    private func processAndSaveImage(_ originalImage: UIImage, name: String?) async throws -> WidgetPhoto {
        guard let folder = imagesFolder else {
            throw WidgetPhotoError.storageUnavailable
        }
        
        guard canAddMore else {
            throw WidgetPhotoError.storageFull
        }
        
        // Generate unique ID
        let photoId = UUID().uuidString
        
        // Process image (resize if needed)
        let processedImage = resizeImageIfNeeded(originalImage)
        
        // Create thumbnail
        let thumbnail = createThumbnail(from: processedImage)
        
        // Save full-size image
        let imageURL = folder.appendingPathComponent("\(photoId).jpg")
        guard let imageData = processedImage.jpegData(compressionQuality: compressionQuality) else {
            throw WidgetPhotoError.processingFailed
        }
        try imageData.write(to: imageURL)
        
        // Save thumbnail
        let thumbnailURL = folder.appendingPathComponent("\(photoId)_thumb.jpg")
        if let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
            try? thumbnailData.write(to: thumbnailURL)
        }
        
        // Extract dominant colors
        let dominantColors = extractDominantColors(from: processedImage)
        
        // Create photo metadata
        let photo = WidgetPhoto(
            id: photoId,
            name: name ?? "Photo \(savedPhotos.count + 1)",
            width: Int(processedImage.size.width),
            height: Int(processedImage.size.height),
            fileSize: imageData.count,
            dominantColors: dominantColors,
            createdAt: Date()
        )
        
        savedPhotos.insert(photo, at: 0)
        saveMetadata()
        
        return photo
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension = maxImageDimension
        
        let width = image.size.width
        let height = image.size.height
        
        if width <= maxDimension && height <= maxDimension {
            return image
        }
        
        let ratio = width / height
        let newSize: CGSize
        
        if width > height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func createThumbnail(from image: UIImage) -> UIImage {
        let thumbnailSize = CGSize(width: 200, height: 200)
        
        let widthRatio = thumbnailSize.width / image.size.width
        let heightRatio = thumbnailSize.height / image.size.height
        let ratio = max(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        return renderer.image { _ in
            let origin = CGPoint(
                x: (thumbnailSize.width - newSize.width) / 2,
                y: (thumbnailSize.height - newSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: newSize))
        }
    }
    
    private func extractDominantColors(from image: UIImage) -> [String] {
        // Simplified color extraction - in production would use more sophisticated algorithm
        guard let cgImage = image.cgImage else { return [] }
        
        let width = min(50, cgImage.width)
        let height = min(50, cgImage.height)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return [] }
        let pointer = data.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        var colorCounts: [String: Int] = [:]
        
        for y in stride(from: 0, to: height, by: 5) {
            for x in stride(from: 0, to: width, by: 5) {
                let offset = (y * width + x) * 4
                let r = Int(pointer[offset]) / 32 * 32
                let g = Int(pointer[offset + 1]) / 32 * 32
                let b = Int(pointer[offset + 2]) / 32 * 32
                
                let hex = String(format: "%02X%02X%02X", r, g, b)
                colorCounts[hex, default: 0] += 1
            }
        }
        
        let sortedColors = colorCounts.sorted { $0.value > $1.value }
        return Array(sortedColors.prefix(5).map { "#\($0.key)" })
    }
}

// MARK: - Widget Photo Model

/// Metadata for a saved widget photo
struct WidgetPhoto: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    let width: Int
    let height: Int
    let fileSize: Int
    let dominantColors: [String]
    let createdAt: Date
    var lastUsedAt: Date?
    var useCount: Int = 0
    
    var aspectRatio: CGFloat {
        CGFloat(width) / CGFloat(height)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

// MARK: - Errors

enum WidgetPhotoError: LocalizedError {
    case loadFailed
    case processingFailed
    case storageUnavailable
    case storageFull
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load the image"
        case .processingFailed:
            return "Failed to process the image"
        case .storageUnavailable:
            return "Storage is unavailable"
        case .storageFull:
            return "Photo storage is full (max 50 photos)"
        case .saveFailed:
            return "Failed to save the image"
        }
    }
}

// MARK: - Photo Picker View

/// Photo picker component for widget designer
struct WidgetPhotoPicker: View {
    let onSelect: (WidgetPhoto) -> Void
    
    @StateObject private var photoService = WidgetPhotoService.shared
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var isLoading = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Add new photo button
                    addPhotoSection
                    
                    // Recent photos
                    if !photoService.recentPhotos.isEmpty {
                        photoSection(title: "Recently Used", photos: photoService.recentPhotos)
                    }
                    
                    // All photos
                    if !photoService.savedPhotos.isEmpty {
                        photoSection(title: "My Photos", photos: photoService.savedPhotos)
                    } else {
                        emptyState
                    }
                }
                .padding(16)
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Photo Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { _, newItem in
                if let item = newItem {
                    handlePhotoSelection(item)
                }
            }
            .overlay {
                if isLoading || photoService.isProcessing {
                    loadingOverlay
                }
            }
        }
    }
    
    private var addPhotoSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingPhotoPicker = true
            }) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(themeManager.accentColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Add Photo")
                            .font(.headline)
                            .foregroundColor(themeManager.textColor)
                        
                        Text("\(photoService.availableCount) slots remaining")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(themeManager.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                )
            }
            .disabled(!photoService.canAddMore)
            .opacity(photoService.canAddMore ? 1 : 0.5)
        }
    }
    
    private func photoSection(title: String, photos: [WidgetPhoto]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    WidgetPhotoThumbnail(
                        photo: photo,
                        onSelect: {
                            photoService.markAsUsed(photo.id)
                            onSelect(photo)
                            dismiss()
                        },
                        onDelete: {
                            photoService.deletePhoto(photo)
                        }
                    )
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Photos Yet")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                
                Text("Add photos to use as widget backgrounds")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processing photo...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) {
        isLoading = true
        
        Task {
            do {
                let photo = try await photoService.savePhoto(from: item)
                await MainActor.run {
                    isLoading = false
                    onSelect(photo)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Error handling
                }
            }
        }
    }
}

// MARK: - Photo Thumbnail

struct WidgetPhotoThumbnail: View {
    let photo: WidgetPhoto
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var showingDeleteAlert = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(themeManager.cardBackgroundColor)
                        .frame(height: 100)
                        .overlay(
                            ProgressView()
                                .tint(themeManager.secondaryTextColor)
                        )
                }
            }
            .cornerRadius(12)
            .overlay(
                // Delete button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .padding(4),
                alignment: .topTrailing
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            loadThumbnail()
        }
        .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This photo will be removed from your widget backgrounds.")
        }
    }
    
    private func loadThumbnail() {
        Task { @MainActor in
            if let image = WidgetPhotoService.shared.getThumbnail(for: photo) {
                self.thumbnail = image
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WidgetPhotoPicker { photo in
        print("Selected: \(photo.name)")
    }
}


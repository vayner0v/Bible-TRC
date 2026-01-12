//
//  ImageAttachmentView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Image Attachment Components
//

import SwiftUI
import PhotosUI

/// Preview of attached images before sending
struct ImageAttachmentPreviewView: View {
    let attachments: [ChatImageAttachment]
    let onRemove: (ChatImageAttachment) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    ImageAttachmentThumbnail(
                        attachment: attachment,
                        onRemove: { onRemove(attachment) }
                    )
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 80)
        .background(themeManager.cardBackgroundColor)
    }
}

/// Single image thumbnail with remove button
struct ImageAttachmentThumbnail: View {
    let attachment: ChatImageAttachment
    let onRemove: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = attachment.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.cardBackgroundColor)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(themeManager.secondaryTextColor)
                    )
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .offset(x: 6, y: -6)
        }
    }
}

/// Image picker button for input bar
struct ImagePickerButton: View {
    @Binding var selectedItems: [PhotosPickerItem]
    let onImageSelected: ([UIImage]) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var isProcessing = false
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 4,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Image(systemName: "photo")
                .font(.system(size: 20))
                .foregroundColor(themeManager.accentColor)
        }
        .disabled(isProcessing)
        .onChange(of: selectedItems) { _, newItems in
            processSelectedItems(newItems)
        }
    }
    
    private func processSelectedItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            var images: [UIImage] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                isProcessing = false
                onImageSelected(images)
                selectedItems = [] // Reset selection
            }
        }
    }
}

/// Camera capture button for input bar
struct CameraCaptureButton: View {
    @Binding var isShowingCamera: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button {
            isShowingCamera = true
        } label: {
            Image(systemName: "camera")
                .font(.system(size: 20))
                .foregroundColor(themeManager.accentColor)
        }
    }
}

/// Image viewer for full-screen image display
struct FullImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: geometry.size.width * scale,
                            height: geometry.size.height * scale
                        )
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    scale = max(1.0, min(scale, 4.0))
                                    lastScale = scale
                                }
                        )
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("Image", image: Image(uiImage: image)))
                }
            }
        }
    }
}

/// Message bubble image display
struct MessageImageView: View {
    let attachment: ChatImageAttachment
    let onTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onTap) {
            if let image = attachment.thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.dividerColor, lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .frame(width: 200, height: 150)
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

/// Grid of images in a message
struct MessageImagesGridView: View {
    let attachments: [ChatImageAttachment]
    let onImageTap: (ChatImageAttachment) -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        Group {
            if attachments.count == 1, let first = attachments.first {
                MessageImageView(attachment: first) {
                    onImageTap(first)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(attachments.prefix(4)) { attachment in
                        MessageImageView(attachment: attachment) {
                            onImageTap(attachment)
                        }
                        .frame(height: 100)
                    }
                }
                .frame(maxWidth: 250)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ImageAttachmentPreviewView(
            attachments: [],
            onRemove: { _ in }
        )
        
        Spacer()
    }
}





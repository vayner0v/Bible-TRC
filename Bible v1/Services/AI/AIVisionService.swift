//
//  AIVisionService.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Vision API Service
//

import Foundation
import SwiftUI
import UIKit
import Combine

/// Service for handling image analysis with OpenAI Vision API
@MainActor
class AIVisionService: ObservableObject {
    static let shared = AIVisionService()
    
    // MARK: - Configuration
    
    private let model = "gpt-4o"  // Vision-capable model
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let maxImageSize: CGFloat = 1024  // Max dimension for uploaded images
    private let jpegQuality: CGFloat = 0.8
    
    // MARK: - API Key
    
    private var apiKey: String {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return key
        }
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path),
           let key = secrets["OPENAI_API_KEY"] as? String {
            return key
        }
        return ""
    }
    
    // MARK: - State
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Analyze an image with a text prompt
    func analyzeImage(
        _ image: UIImage,
        prompt: String,
        mode: AIMode,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let response = try await performVisionRequest(
                    images: [image],
                    prompt: prompt,
                    mode: mode
                )
                onComplete(.success(response))
            } catch {
                lastError = error
                onComplete(.failure(error))
            }
        }
    }
    
    /// Analyze multiple images with a text prompt
    func analyzeImages(
        _ images: [UIImage],
        prompt: String,
        mode: AIMode,
        onComplete: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let response = try await performVisionRequest(
                    images: images,
                    prompt: prompt,
                    mode: mode
                )
                onComplete(.success(response))
            } catch {
                lastError = error
                onComplete(.failure(error))
            }
        }
    }
    
    // MARK: - Image Processing
    
    /// Resize and compress image for upload
    func prepareImageForUpload(_ image: UIImage) -> Data? {
        // Resize if needed
        let resizedImage = resizeImage(image, maxDimension: maxImageSize)
        
        // Convert to JPEG
        return resizedImage.jpegData(compressionQuality: jpegQuality)
    }
    
    /// Convert image data to base64 for API
    func imageToBase64(_ imageData: Data) -> String {
        return imageData.base64EncodedString()
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - API Request
    
    private func performVisionRequest(
        images: [UIImage],
        prompt: String,
        mode: AIMode
    ) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw VisionError.invalidURL
        }
        
        // Build content array with images
        var content: [[String: Any]] = []
        
        // Add text prompt
        content.append([
            "type": "text",
            "text": buildVisionPrompt(userPrompt: prompt, mode: mode)
        ])
        
        // Add images
        for image in images {
            guard let imageData = prepareImageForUpload(image) else {
                continue
            }
            
            let base64 = imageToBase64(imageData)
            content.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(base64)",
                    "detail": "high"
                ]
            ])
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": content
                ]
            ],
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw VisionError.invalidResponse
        }
        
        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            // Parse error
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw VisionError.apiError(message)
            }
            throw VisionError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let responseContent = message["content"] as? String else {
            throw VisionError.parseError
        }
        
        return responseContent
    }
    
    // MARK: - Prompt Building
    
    private func buildVisionPrompt(userPrompt: String, mode: AIMode) -> String {
        let modeContext: String
        switch mode {
        case .study:
            modeContext = "You are in STUDY mode. Provide detailed biblical analysis of what you see."
        case .devotional:
            modeContext = "You are in DEVOTIONAL mode. Provide warm, encouraging reflections on what you see."
        case .prayer:
            modeContext = "You are in PRAYER mode. Help the user pray about or reflect on what you see."
        }
        
        return """
        You are TRC AI, a Bible assistant with vision capabilities.
        
        \(modeContext)
        
        The user has shared an image with you. This could be:
        - A photo of a Bible page or passage
        - Religious artwork or imagery
        - Handwritten notes or prayers
        - A scene they want biblical perspective on
        
        USER'S QUESTION: \(userPrompt)
        
        Please analyze the image and respond helpfully. If it's a Bible passage, help explain it. \
        If it's artwork, discuss its biblical themes. If it's notes, help organize or expand on them.
        
        Always cite relevant Scripture in parentheses like (John 3:16).
        Respond naturally and conversationally.
        """
    }
}

// MARK: - Vision Errors

enum VisionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parseError
    case noImages
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return message
        case .parseError:
            return "Failed to parse response"
        case .noImages:
            return "No images provided"
        }
    }
}

// MARK: - Image Attachment Model

/// Represents an image attached to a chat message
struct ChatImageAttachment: Identifiable, Codable, Hashable {
    let id: UUID
    let fileName: String
    let thumbnailData: Data?
    let fullImageData: Data?
    let dateAdded: Date
    
    init(
        id: UUID = UUID(),
        fileName: String = UUID().uuidString + ".jpg",
        thumbnailData: Data? = nil,
        fullImageData: Data? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.thumbnailData = thumbnailData
        self.fullImageData = fullImageData
        self.dateAdded = dateAdded
    }
    
    /// Create from UIImage
    static func from(_ image: UIImage) -> ChatImageAttachment {
        // Create thumbnail
        let thumbnailSize = CGSize(width: 150, height: 150)
        UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return ChatImageAttachment(
            thumbnailData: thumbnail?.jpegData(compressionQuality: 0.7),
            fullImageData: image.jpegData(compressionQuality: 0.8)
        )
    }
    
    /// Get thumbnail as UIImage
    var thumbnailImage: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    /// Get full image as UIImage
    var fullImage: UIImage? {
        guard let data = fullImageData else { return nil }
        return UIImage(data: data)
    }
}


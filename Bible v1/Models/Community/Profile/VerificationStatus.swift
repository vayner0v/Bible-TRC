//
//  VerificationStatus.swift
//  Bible v1
//
//  Community Tab - Verification Status Model
//

import Foundation
import SwiftUI

/// Types of verification for community members
enum VerificationType: String, Codable, CaseIterable {
    case church = "church"
    case leader = "leader"
    case notable = "notable"
    
    var displayName: String {
        switch self {
        case .church: return "Verified Church"
        case .leader: return "Verified Leader"
        case .notable: return "Notable Member"
        }
    }
    
    var icon: String {
        switch self {
        case .church: return "building.columns.fill"
        case .leader: return "person.badge.shield.checkmark.fill"
        case .notable: return "checkmark.seal.fill"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .church: return .blue
        case .leader: return .purple
        case .notable: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .church: return "This is an official church account"
        case .leader: return "This is a verified ministry leader"
        case .notable: return "This account has been verified"
        }
    }
}

/// Status of a verification request
enum VerificationRequestStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Under Review"
        case .approved: return "Approved"
        case .rejected: return "Not Approved"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

/// Social links for verification
struct SocialLinks: Codable, Hashable {
    var website: String?
    var facebook: String?
    var instagram: String?
    var twitter: String?
    var youtube: String?
    var linkedin: String?
    
    var hasAnyLink: Bool {
        website != nil || facebook != nil || instagram != nil ||
        twitter != nil || youtube != nil || linkedin != nil
    }
}

/// A verification request from a user
struct VerificationRequest: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let type: VerificationType
    var status: VerificationRequestStatus
    var documents: [String]?
    var churchName: String?
    var churchWebsite: String?
    var socialLinks: SocialLinks?
    var reviewedBy: UUID?
    var reviewedAt: Date?
    var rejectionReason: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, status, documents
        case churchName = "church_name"
        case churchWebsite = "church_website"
        case socialLinks = "social_links"
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
        case rejectionReason = "rejection_reason"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        type: VerificationType,
        status: VerificationRequestStatus = .pending,
        documents: [String]? = nil,
        churchName: String? = nil,
        churchWebsite: String? = nil,
        socialLinks: SocialLinks? = nil,
        reviewedBy: UUID? = nil,
        reviewedAt: Date? = nil,
        rejectionReason: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.status = status
        self.documents = documents
        self.churchName = churchName
        self.churchWebsite = churchWebsite
        self.socialLinks = socialLinks
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
        self.rejectionReason = rejectionReason
        self.createdAt = createdAt
    }
}


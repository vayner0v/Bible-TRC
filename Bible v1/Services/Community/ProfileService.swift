//
//  ProfileService.swift
//  Bible v1
//
//  Community Tab - Profile Service
//

import Foundation
import Supabase

/// Service for managing community profiles
@MainActor
final class ProfileService {
    
    // MARK: - Properties
    
    private var supabase: SupabaseClient { SupabaseService.shared.client }
    
    // MARK: - Public Methods
    
    /// Get or create a community profile for a user
    func getOrCreateProfile(for userId: UUID) async throws -> CommunityProfile {
        // Try to get existing profile first
        if let existing = try await getProfile(userId: userId) {
            return existing
        }
        
        // Create new profile using upsert to handle race conditions
        return try await createProfileWithUpsert(for: userId)
    }
    
    /// Get a profile by user ID
    func getProfile(userId: UUID) async throws -> CommunityProfile? {
        do {
            // Use array query instead of .single() to handle missing profiles gracefully
            let response: [CommunityProfile] = try await supabase
                .from("community_profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            
            return response.first
        } catch {
            throw CommunityError.database(error.localizedDescription)
        }
    }
    
    /// Get a profile by username
    func getProfile(username: String) async throws -> CommunityProfile? {
        do {
            // Use array query instead of .single() to handle missing profiles gracefully
            let response: [CommunityProfile] = try await supabase
                .from("community_profiles")
                .select()
                .eq("username", value: username)
                .limit(1)
                .execute()
                .value
            
            return response.first
        } catch {
            throw CommunityError.database(error.localizedDescription)
        }
    }
    
    /// Create a new community profile
    func createProfile(for userId: UUID) async throws -> CommunityProfile {
        return try await createProfileWithUpsert(for: userId)
    }
    
    /// Create a new community profile using upsert to handle race conditions
    private func createProfileWithUpsert(for userId: UUID) async throws -> CommunityProfile {
        // Get display name from auth user
        let session = try await supabase.auth.session
        let displayName = session.user.userMetadata["display_name"]?.stringValue ??
                         session.user.userMetadata["full_name"]?.stringValue ??
                         session.user.userMetadata["name"]?.stringValue ??
                         "User"
        
        let avatarUrl = session.user.userMetadata["avatar_url"]?.stringValue ??
                       session.user.userMetadata["picture"]?.stringValue
        
        let newProfile = CommunityProfile(
            id: userId,
            displayName: displayName,
            avatarUrl: avatarUrl,
            preferredTranslation: StorageService.shared.getSelectedTranslation() ?? "KJV"
        )
        
        // Use upsert to handle race conditions (if profile already exists, return existing)
        let response: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .upsert(newProfile, onConflict: "id")
            .select()
            .execute()
            .value
        
        guard let profile = response.first else {
            throw CommunityError.database("Failed to create profile")
        }
        
        return profile
    }
    
    /// Update a community profile
    func updateProfile(_ profile: CommunityProfile) async throws -> CommunityProfile {
        let response: CommunityProfile = try await supabase
            .from("community_profiles")
            .update(profile)
            .eq("id", value: profile.id.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update specific profile fields
    func updateProfileFields(
        userId: UUID,
        displayName: String? = nil,
        username: String? = nil,
        bio: String? = nil,
        testimony: String? = nil,
        avatarUrl: String? = nil,
        denomination: String? = nil,
        churchName: String? = nil,
        locationCity: String? = nil
    ) async throws -> CommunityProfile {
        var updates: [String: AnyEncodable] = [:]
        
        if let displayName = displayName {
            updates["display_name"] = AnyEncodable(displayName)
        }
        if let username = username {
            // Validate username
            guard isValidUsername(username) else {
                throw CommunityError.validation("Username must be 3-30 characters, alphanumeric and underscores only")
            }
            updates["username"] = AnyEncodable(username)
        }
        if let bio = bio {
            guard bio.count <= 500 else {
                throw CommunityError.validation("Bio must be 500 characters or less")
            }
            updates["bio"] = AnyEncodable(bio)
        }
        if let testimony = testimony {
            guard testimony.count <= 2000 else {
                throw CommunityError.validation("Testimony must be 2000 characters or less")
            }
            updates["testimony"] = AnyEncodable(testimony)
        }
        if let avatarUrl = avatarUrl {
            updates["avatar_url"] = AnyEncodable(avatarUrl)
        }
        if let denomination = denomination {
            updates["denomination"] = AnyEncodable(denomination)
        }
        if let churchName = churchName {
            updates["church_name"] = AnyEncodable(churchName)
        }
        if let locationCity = locationCity {
            updates["location_city"] = AnyEncodable(locationCity)
        }
        
        updates["updated_at"] = AnyEncodable(ISO8601DateFormatter().string(from: Date()))
        
        let response: CommunityProfile = try await supabase
            .from("community_profiles")
            .update(updates)
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    /// Update privacy settings
    func updatePrivacySettings(userId: UUID, settings: ProfilePrivacySettings) async throws {
        try await supabase
            .from("community_profiles")
            .update(["privacy_settings": settings])
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    /// Update content filters
    func updateContentFilters(userId: UUID, filters: ContentFilterSettings) async throws {
        try await supabase
            .from("community_profiles")
            .update(["content_filters": filters])
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    /// Check if username is available
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        guard isValidUsername(username) else { return false }
        
        let response: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select("id")
            .eq("username", value: username.lowercased())
            .execute()
            .value
        
        return response.isEmpty
    }
    
    /// Get profile summary by ID
    func getProfileSummary(id: UUID) async throws -> CommunityProfileSummary? {
        if let profile = try await getProfile(userId: id) {
            return CommunityProfileSummary(from: profile)
        }
        return nil
    }
    
    /// Search profiles
    func searchProfiles(query: String, limit: Int = 20) async throws -> [CommunityProfileSummary] {
        let response: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .or("display_name.ilike.%\(query)%,username.ilike.%\(query)%")
            .limit(limit)
            .execute()
            .value
        
        return response.map { CommunityProfileSummary(from: $0) }
    }
    
    /// Get multiple profiles by IDs
    func getProfiles(ids: [UUID]) async throws -> [CommunityProfile] {
        guard !ids.isEmpty else { return [] }
        
        let response: [CommunityProfile] = try await supabase
            .from("community_profiles")
            .select()
            .in("id", values: ids.map { $0.uuidString })
            .execute()
            .value
        
        return response
    }
    
    /// Update last active timestamp
    func updateLastActive(userId: UUID) async throws {
        try await supabase
            .from("community_profiles")
            .update(["last_active_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Private Methods
    
    private func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-zA-Z0-9_]{3,30}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(username.startIndex..., in: username)
        return regex?.firstMatch(in: username, range: range) != nil
    }
}

// MARK: - AnyEncodable Helper

struct AnyEncodable: Encodable {
    private let value: any Encodable
    
    init(_ value: any Encodable) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}


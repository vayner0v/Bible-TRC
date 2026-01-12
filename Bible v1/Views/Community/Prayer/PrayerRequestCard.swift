//
//  PrayerRequestCard.swift
//  Bible v1
//
//  Community Tab - Prayer Request Card Component
//

import SwiftUI

struct PrayerRequestCard: View {
    let request: CommunityPrayerRequest
    @EnvironmentObject var themeManager: ThemeManager
    @State private var hasPrayed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            headerSection
            
            // Content
            if let post = request.post {
                contentSection(post)
            }
            
            // Category & Duration
            metadataSection
            
            // Prayer Circle
            prayerCircleSection
            
            // Prayed Button
            PrayedButton(
                count: request.prayerCount,
                hasPrayed: hasPrayed
            ) {
                Task {
                    await pray()
                }
            }
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(urgencyBorderColor, lineWidth: request.urgency == .urgent ? 2 : 0)
        )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 10) {
            // Avatar
            if let author = request.post?.author {
                if request.post?.isAnonymous == true {
                    anonymousAvatar
                } else {
                    UserAvatarView(profile: author, size: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if request.post?.isAnonymous == true {
                        Text("Anonymous")
                            .font(.system(size: 15, weight: .semibold))
                    } else if let author = request.post?.author {
                        Text(author.displayName)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    
                    // Urgent Badge
                    if request.urgency == .urgent {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("Urgent")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .foregroundColor(themeManager.textColor)
                
                if let createdAt = request.post?.createdAt {
                    Text(relativeTime(from: createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textColor.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Menu
            Menu {
                Button("Share") { }
                Button("Set Reminder") { }
                Button("Report", role: .destructive) { }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
                    .padding(8)
            }
        }
    }
    
    private var anonymousAvatar: some View {
        Circle()
            .fill(Color.purple.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.purple)
            )
    }
    
    // MARK: - Content
    
    private func contentSection(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(post.content)
                .font(.system(size: 15))
                .foregroundColor(themeManager.textColor)
                .lineLimit(6)
            
            // Linked Verse
            if let verseRef = post.verseRef {
                HStack(spacing: 6) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 12))
                    Text(verseRef.shortReference)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(themeManager.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(themeManager.accentColor.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Metadata
    
    private var metadataSection: some View {
        HStack(spacing: 12) {
            // Category
            HStack(spacing: 4) {
                Image(systemName: request.category.icon)
                    .font(.system(size: 12))
                Text(request.category.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(request.category.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(request.category.color.opacity(0.1))
            .clipShape(Capsule())
            
            // Days remaining
            if let daysRemaining = request.daysRemaining, !request.isAnswered {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("\(daysRemaining) days left")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(themeManager.textColor.opacity(0.6))
            }
            
            // Answered Badge
            if request.isAnswered {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Answered!")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Prayer Circle
    
    private var prayerCircleSection: some View {
        HStack(spacing: 8) {
            if let circle = request.prayerCircle, !circle.isEmpty {
                AvatarGroupView(profiles: circle, maxVisible: 4, size: 28)
                
                Text("\(request.prayerCount) praying")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textColor.opacity(0.6))
            } else {
                Image(systemName: "person.3")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor.opacity(0.4))
                
                Text("Be the first to pray")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
            }
        }
    }
    
    // MARK: - Helpers
    
    private var urgencyBorderColor: Color {
        request.urgency == .urgent ? Color.red.opacity(0.3) : Color.clear
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func pray() async {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        
        hasPrayed = true
        
        do {
            try await CommunityService.shared.prayerService.joinPrayerCircle(
                request: JoinPrayerCircleRequest(
                    prayerPostId: request.postId,
                    setReminder: false,
                    reminderFrequency: nil
                ),
                userId: userId
            )
        } catch {
            hasPrayed = false
            print("Error joining prayer circle: \(error)")
        }
    }
}

// MARK: - Prayer Card Skeleton

struct PrayerCardSkeleton: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 10) {
                Circle()
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.backgroundColor.opacity(0.3))
                        .frame(width: 100, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.backgroundColor.opacity(0.3))
                        .frame(width: 60, height: 12)
                }
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(height: 14)
            }
            
            // Button
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.backgroundColor.opacity(0.3))
                .frame(width: 140, height: 44)
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shimmering()
    }
}

#Preview {
    VStack(spacing: 16) {
        PrayerRequestCard(request: CommunityPrayerRequest(
            postId: UUID(),
            category: .health,
            urgency: .urgent,
            durationDays: 7,
            prayerCount: 12,
            post: Post(
                authorId: UUID(),
                type: .prayer,
                content: "Please pray for my grandmother who is in the hospital. She has been sick for a while and we need God's healing touch.",
                isAnonymous: false,
                author: CommunityProfileSummary(id: UUID(), displayName: "Sarah Johnson")
            ),
            prayerCircle: [
                CommunityProfileSummary(id: UUID(), displayName: "John"),
                CommunityProfileSummary(id: UUID(), displayName: "Jane"),
                CommunityProfileSummary(id: UUID(), displayName: "Bob")
            ]
        ))
        
        PrayerCardSkeleton()
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}


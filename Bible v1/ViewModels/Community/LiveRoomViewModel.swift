//
//  LiveRoomViewModel.swift
//  Bible v1
//
//  Community Tab - Live Room View Model
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class LiveRoomViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var room: LiveRoom?
    @Published var host: CommunityProfileSummary?
    @Published var participants: [RoomParticipant] = []
    @Published var isLoading = false
    
    // User state
    @Published var isSpeaker = false
    @Published var isMuted = true
    @Published var handRaised = false
    @Published var hasReminder = false
    
    // Live state
    @Published var speakingParticipants: Set<UUID> = []
    @Published var mutedParticipants: Set<UUID> = []
    @Published var countdown: String = ""
    
    // Sheets
    @Published var showLeaveConfirmation = false
    @Published var showReportSheet = false
    
    // MARK: - Computed Properties
    
    var speakers: [RoomParticipant] {
        participants.filter { $0.role == .speaker || $0.role == .coHost || $0.role == .host }
    }
    
    var listeners: [RoomParticipant] {
        participants.filter { $0.role == .listener }
    }
    
    // MARK: - Properties
    
    private let roomId: UUID
    private var liveRoomService: LiveRoomService { CommunityService.shared.liveRoomService }
    private var countdownTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(roomId: UUID) {
        self.roomId = roomId
    }
    
    init(room: LiveRoom) {
        self.roomId = room.id
        self.room = room
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func load() async {
        await loadRoom()
        
        if room?.status == .scheduled {
            startCountdownTimer()
        } else if room?.status == .live {
            await joinRoom()
            await loadParticipants()
            setupRealtimeUpdates()
        }
    }
    
    func loadRoom() async {
        guard room == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            room = try await liveRoomService.getRoom(id: roomId)
            
            if let hostId = room?.hostId {
                host = try await CommunityService.shared.profileService.getProfileSummary(id: hostId)
            }
        } catch {
            print("❌ LiveRoom: Failed to load - \(error.localizedDescription)")
        }
    }
    
    func loadParticipants() async {
        do {
            participants = try await liveRoomService.getParticipants(roomId: roomId)
            
            // Determine if current user is a speaker
            if let userId = CommunityService.shared.currentProfile?.id {
                if let myParticipant = participants.first(where: { $0.userId == userId }) {
                    isSpeaker = myParticipant.role == .speaker || myParticipant.role == .coHost || myParticipant.role == .host
                }
            }
        } catch {
            print("❌ LiveRoom: Failed to load participants - \(error.localizedDescription)")
        }
    }
    
    func joinRoom() async {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        do {
            _ = try await liveRoomService.joinRoom(roomId: roomId, userId: userId, role: .listener)
        } catch {
            print("❌ LiveRoom: Failed to join - \(error.localizedDescription)")
        }
    }
    
    func leaveRoom() async {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        do {
            try await liveRoomService.leaveRoom(roomId: roomId, userId: userId)
        } catch {
            print("❌ LiveRoom: Failed to leave - \(error.localizedDescription)")
        }
    }
    
    func toggleMute() {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        isMuted.toggle()
        
        if isMuted {
            mutedParticipants.insert(userId)
        } else {
            mutedParticipants.remove(userId)
        }
        
        // Notify server about mute state
        Task {
            // await liveRoomService.setMuteState(roomId: roomId, userId: userId, isMuted: isMuted)
        }
    }
    
    func toggleRaiseHand() {
        handRaised.toggle()
        
        // Notify server
        Task {
            // await liveRoomService.setHandRaised(roomId: roomId, raised: handRaised)
        }
    }
    
    func setReminder() {
        hasReminder.toggle()
        
        guard let room = room else { return }
        
        if hasReminder {
            // Schedule local notification
            let content = UNMutableNotificationContent()
            content.title = "Live Room Starting"
            content.body = "\(room.title) is starting now!"
            content.sound = .default
            
            if let scheduledAt = room.scheduledAt, scheduledAt > Date() {
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: scheduledAt.timeIntervalSinceNow,
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: "live_room_\(room.id)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        } else {
            // Remove notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["live_room_\(room.id)"]
            )
        }
    }
    
    func shareRoom() {
        guard let room = room else { return }
        _ = "Join '\(room.title)' on Bible App Community!"
        // TODO: Implement share sheet
    }
    
    // MARK: - Private Methods
    
    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.updateCountdown()
            }
        }
        
        updateCountdown()
    }
    
    private func updateCountdown() {
        guard let startTime = room?.scheduledAt else {
            countdown = ""
            return
        }
        
        let remaining = startTime.timeIntervalSinceNow
        
        if remaining <= 0 {
            countdown = "Starting..."
            countdownTimer?.invalidate()
            
            // Reload to check if room is now live
            Task {
                await loadRoom()
                if room?.status == .live {
                    await joinRoom()
                    await loadParticipants()
                }
            }
            return
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        
        if hours > 0 {
            countdown = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            countdown = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func setupRealtimeUpdates() {
        // Setup Supabase realtime subscription for participant updates
        // This would listen for:
        // - New participants joining
        // - Participants leaving
        // - Role changes
        // - Speaking state changes
    }
}


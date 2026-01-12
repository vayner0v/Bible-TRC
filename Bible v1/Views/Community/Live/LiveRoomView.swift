//
//  LiveRoomView.swift
//  Bible v1
//
//  Community Tab - Live Room View
//

import SwiftUI

struct LiveRoomView: View {
    @StateObject private var viewModel: LiveRoomViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    init(roomId: UUID) {
        _viewModel = StateObject(wrappedValue: LiveRoomViewModel(roomId: roomId))
    }
    
    init(room: LiveRoom) {
        _viewModel = StateObject(wrappedValue: LiveRoomViewModel(room: room))
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content based on room status
                if let room = viewModel.room {
                    if room.status == .scheduled {
                        scheduledView
                    } else if room.status == .live {
                        liveContent
                    } else {
                        endedView
                    }
                } else if viewModel.isLoading {
                    loadingView
                } else {
                    errorView
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .onDisappear {
            Task { await viewModel.leaveRoom() }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                if let room = viewModel.room {
                    Text(room.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        if room.status == .live {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("LIVE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text(room.type.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Menu {
                Button {
                    viewModel.shareRoom()
                } label: {
                    Label("Share Room", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    viewModel.showReportSheet = true
                } label: {
                    Label("Report Room", systemImage: "flag")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    // MARK: - Scheduled View
    
    private var scheduledView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Room Type Icon
            ZStack {
                Circle()
                    .fill(roomTypeColor.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: viewModel.room?.type.icon ?? "dot.radiowaves.left.and.right")
                    .font(.system(size: 50))
                    .foregroundColor(roomTypeColor)
            }
            
            // Title & Description
            VStack(spacing: 12) {
                Text(viewModel.room?.title ?? "")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if let description = viewModel.room?.description {
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            
            // Scheduled Time
            if let startTime = viewModel.room?.scheduledAt {
                VStack(spacing: 8) {
                    Text("Starts at")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(formatDateTime(startTime))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Countdown
                    if startTime > Date() {
                        Text(viewModel.countdown)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(roomTypeColor)
                    }
                }
                .padding(.top, 20)
            }
            
            // Host Info
            if let host = viewModel.host {
                VStack(spacing: 8) {
                    Text("Hosted by")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 10) {
                        UserAvatarView(profile: host, size: 36)
                        
                        Text(host.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    viewModel.setReminder()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.hasReminder ? "bell.fill" : "bell")
                        Text(viewModel.hasReminder ? "Reminder Set" : "Set Reminder")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.hasReminder ? Color.green : roomTypeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button {
                    viewModel.shareRoom()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Live Content
    
    private var liveContent: some View {
        VStack(spacing: 0) {
            // Participants Grid
            participantsGrid
            
            // Bottom Controls
            liveControls
        }
    }
    
    private var participantsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Host First
                if let host = viewModel.host {
                    ParticipantTile(
                        profile: host,
                        role: .host,
                        isSpeaking: viewModel.speakingParticipants.contains(host.id),
                        isMuted: false
                    )
                }
                
                // Speakers
                ForEach(viewModel.speakers, id: \.userId) { participant in
                    if let profile = participant.user, participant.userId != viewModel.host?.id {
                        ParticipantTile(
                            profile: profile,
                            role: participant.role,
                            isSpeaking: viewModel.speakingParticipants.contains(profile.id),
                            isMuted: viewModel.mutedParticipants.contains(profile.id)
                        )
                    }
                }
                
                // Listeners
                ForEach(viewModel.listeners, id: \.userId) { participant in
                    if let profile = participant.user {
                        ParticipantTile(
                            profile: profile,
                            role: .listener,
                            isSpeaking: false,
                            isMuted: true
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var liveControls: some View {
        VStack(spacing: 16) {
            // Listener Count
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                Text("\(viewModel.participants.count) listening")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.7))
            
            // Control Buttons
            HStack(spacing: 30) {
                // Mute/Unmute (if speaker)
                if viewModel.isSpeaker {
                    Button {
                        viewModel.toggleMute()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.isMuted ? .red : .white)
                                .frame(width: 56, height: 56)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                            
                            Text(viewModel.isMuted ? "Unmute" : "Mute")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                // Raise Hand (if listener)
                if !viewModel.isSpeaker {
                    Button {
                        viewModel.toggleRaiseHand()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: viewModel.handRaised ? "hand.raised.fill" : "hand.raised")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.handRaised ? .yellow : .white)
                                .frame(width: 56, height: 56)
                                .background(viewModel.handRaised ? Color.yellow.opacity(0.2) : Color.white.opacity(0.15))
                                .clipShape(Circle())
                            
                            Text(viewModel.handRaised ? "Lower" : "Raise Hand")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                // Leave Room
                Button {
                    viewModel.showLeaveConfirmation = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                            .frame(width: 56, height: 56)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                        
                        Text("Leave")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .alert("Leave Room", isPresented: $viewModel.showLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task { await viewModel.leaveRoom() }
                dismiss()
            }
        }
    }
    
    // MARK: - Ended View
    
    private var endedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Room Ended")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Thanks for joining!")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(themeManager.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Spacer()
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to Load Room")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(themeManager.accentColor)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private var roomTypeColor: Color {
        viewModel.room?.type.color ?? .purple
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Participant Tile

struct ParticipantTile: View {
    let profile: CommunityProfileSummary
    let role: RoomRole
    let isSpeaking: Bool
    let isMuted: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Speaking indicator
                Circle()
                    .stroke(isSpeaking ? Color.green : Color.clear, lineWidth: 3)
                    .frame(width: 76, height: 76)
                
                UserAvatarView(profile: profile, size: 70)
                
                // Muted indicator
                if isMuted && role != .listener {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 25, y: 25)
                }
                
                // Role badge
                if role == .host {
                    Text("HOST")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                        .offset(y: 40)
                }
            }
            
            Text(profile.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
        }
    }
}

// MARK: - Supporting Types
// Note: LiveRoomType properties (displayName, icon, color) are defined in LiveRoom.swift

#Preview {
    LiveRoomView(roomId: UUID())
        .environmentObject(ThemeManager.shared)
}


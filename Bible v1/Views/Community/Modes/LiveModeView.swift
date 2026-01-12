//
//  LiveModeView.swift
//  Bible v1
//
//  Community Tab - Live Mode (Audio Rooms, Video, Scheduled Events)
//

import SwiftUI
import Combine

struct LiveModeView: View {
    @StateObject private var viewModel = LiveRoomsListViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showCreateRoom = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Live Now Section
                if !viewModel.liveRooms.isEmpty {
                    liveNowSection
                }
                
                // Scheduled Section
                scheduledSection
                
                // Empty State
                if viewModel.liveRooms.isEmpty && viewModel.scheduledRooms.isEmpty && !viewModel.isLoading {
                    emptyView
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showCreateRoom) {
            // TODO: Implement CreateLiveRoomView
            Text("Create Live Room - Coming Soon")
                .padding()
        }
        .task {
            await viewModel.load()
        }
    }
    
    private var liveNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Live Now")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            
            ForEach(viewModel.liveRooms) { room in
                LiveRoomCard(room: room)
            }
        }
    }
    
    private var scheduledSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(themeManager.accentColor)
                Text("Upcoming")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Button {
                    showCreateRoom = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            if viewModel.scheduledRooms.isEmpty {
                Text("No upcoming events")
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.scheduledRooms) { room in
                    ScheduledRoomCard(room: room)
                }
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No Live Rooms")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Start a prayer room, Bible study, or discussion with the community.")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showCreateRoom = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Room")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(themeManager.accentColor)
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Live Rooms List ViewModel

@MainActor
final class LiveRoomsListViewModel: ObservableObject {
    @Published private(set) var liveRooms: [LiveRoom] = []
    @Published private(set) var scheduledRooms: [LiveRoom] = []
    @Published private(set) var isLoading = false
    
    private var liveRoomService: LiveRoomService { CommunityService.shared.liveRoomService }
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let live = liveRoomService.getLiveRooms()
            async let scheduled = liveRoomService.getScheduledRooms()
            
            (liveRooms, scheduledRooms) = try await (live, scheduled)
        } catch {
            print("Error loading live rooms: \(error)")
        }
    }
    
    func refresh() async {
        await load()
    }
}

// MARK: - Live Room Card

struct LiveRoomCard: View {
    let room: LiveRoom
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Type Icon
                Image(systemName: room.type.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(room.type.color)
                    .padding(8)
                    .background(room.type.color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textColor)
                    
                    if let host = room.host {
                        Text("Hosted by \(host.displayName)")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.textColor.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .clipShape(Capsule())
            }
            
            // Participants
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12))
                Text("\(room.participantCount) listening")
                    .font(.system(size: 13))
            }
            .foregroundColor(themeManager.textColor.opacity(0.6))
            
            // Join Button
            Button {
                // Join room
            } label: {
                Text("Join Room")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Scheduled Room Card

struct ScheduledRoomCard: View {
    let room: LiveRoom
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Type Icon
            Image(systemName: room.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(room.type.color)
                .frame(width: 44, height: 44)
                .background(room.type.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(room.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.textColor)
                
                if let scheduledTime = room.formattedScheduledTime {
                    Text(scheduledTime)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            Button {
                // Set reminder
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.accentColor)
                    .padding(10)
                    .background(themeManager.accentColor.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LiveModeView()
        .environmentObject(ThemeManager.shared)
}


//
//  StudyModeView.swift
//  Bible v1
//
//  Community Tab - Study Mode (Groups, Reading Plans, Studies)
//

import SwiftUI
import Combine

struct StudyModeView: View {
    @StateObject private var viewModel = GroupsListViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab: StudyTab = .myGroups
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tab Selector
                tabSelector
                
                // Content
                switch selectedTab {
                case .myGroups:
                    myGroupsSection
                case .discover:
                    discoverSection
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .task {
            await viewModel.load()
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("My Groups", tab: .myGroups)
            tabButton("Discover", tab: .discover)
        }
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func tabButton(_ title: String, tab: StudyTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedTab == tab ? themeManager.accentColor : themeManager.textColor.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedTab == tab ? themeManager.accentColor.opacity(0.1) : Color.clear)
        }
    }
    
    @ViewBuilder
    private var myGroupsSection: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.myGroups.isEmpty {
            emptyMyGroupsView
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.myGroups) { group in
                    GroupCardView(group: group)
                }
            }
        }
    }
    
    @ViewBuilder
    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Group Types
            ForEach(GroupType.allCases) { type in
                groupTypeSection(type)
            }
        }
    }
    
    private func groupTypeSection(_ type: GroupType) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                Text(type.displayName + "s")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button("See All") {
                    // Navigate to full list
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeManager.accentColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.suggestedGroups.filter { $0.group.type == type }.prefix(5)) { suggestion in
                        GroupCardCompact(group: suggestion.group)
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.backgroundColor.opacity(0.3))
                    .frame(height: 100)
                    .shimmering()
            }
        }
    }
    
    private var emptyMyGroupsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No Groups Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Join a Bible study, reading plan group, or connect with your church community.")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                selectedTab = .discover
            } label: {
                Text("Discover Groups")
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

// MARK: - Supporting Types

enum StudyTab {
    case myGroups
    case discover
}

// MARK: - Groups List ViewModel

@MainActor
final class GroupsListViewModel: ObservableObject {
    @Published private(set) var myGroups: [CommunityGroup] = []
    @Published private(set) var suggestedGroups: [GroupSuggestion] = []
    @Published private(set) var isLoading = false
    
    private var groupService: GroupService { CommunityService.shared.groupService }
    private var discoveryService: DiscoveryService { CommunityService.shared.discoveryService }
    
    func load() async {
        guard let userId = CommunityService.shared.currentProfile?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            async let myGroupsTask = groupService.getUserGroups(userId: userId)
            async let suggestionsTask = discoveryService.getSuggestedGroups(userId: userId)
            
            (myGroups, suggestedGroups) = try await (myGroupsTask, suggestionsTask)
        } catch {
            print("Error loading groups: \(error)")
        }
    }
}

#Preview {
    StudyModeView()
        .environmentObject(ThemeManager.shared)
}


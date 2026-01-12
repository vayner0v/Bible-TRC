//
//  PrayModeView.swift
//  Bible v1
//
//  Community Tab - Pray Mode (Prayer Requests and Prayer Circles)
//

import SwiftUI
import Combine

struct PrayModeView: View {
    @StateObject private var viewModel = PrayerFeedViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCategory: CommunityPrayerCategory? = nil
    @State private var showMyPrayers = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Category Filter
                categoryFilter
                
                // Tabs
                tabSelector
                
                if viewModel.isLoading && viewModel.requests.isEmpty {
                    loadingView
                } else if viewModel.requests.isEmpty {
                    emptyView
                } else {
                    // Prayer Requests
                    ForEach(viewModel.requests) { request in
                        PrayerRequestCard(request: request)
                    }
                    
                    // Loading More
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            if viewModel.requests.isEmpty {
                await viewModel.load()
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, title: "All")
                ForEach(CommunityPrayerCategory.allCases) { category in
                    categoryChip(category, title: category.displayName)
                }
            }
        }
    }
    
    private func categoryChip(_ category: CommunityPrayerCategory?, title: String) -> some View {
        Button {
            selectedCategory = category
            Task { await viewModel.load(category: category) }
        } label: {
            HStack(spacing: 4) {
                if let category = category {
                    Image(systemName: category.icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(selectedCategory == category ? .white : themeManager.textColor.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedCategory == category ? themeManager.accentColor : themeManager.backgroundColor.opacity(0.3))
            .clipShape(Capsule())
        }
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("Prayer Feed", isSelected: !showMyPrayers) {
                showMyPrayers = false
            }
            tabButton("My Prayers", isSelected: showMyPrayers) {
                showMyPrayers = true
            }
        }
        .background(themeManager.backgroundColor.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func tabButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? themeManager.accentColor : themeManager.textColor.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? themeManager.accentColor.opacity(0.1) : Color.clear)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                PrayerCardSkeleton()
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "hands.sparkles")
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.5))
            
            Text("No Prayer Requests")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.textColor)
            
            Text("Share a prayer request or join someone's prayer circle to support them.")
                .font(.system(size: 14))
                .foregroundColor(themeManager.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

// MARK: - Prayer Feed ViewModel

@MainActor
final class PrayerFeedViewModel: ObservableObject {
    @Published private(set) var requests: [CommunityPrayerRequest] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    
    private var prayerService: PrayerService { CommunityService.shared.prayerService }
    private var offset = 0
    private let pageSize = 20
    
    func load(category: CommunityPrayerCategory? = nil) async {
        isLoading = true
        offset = 0
        defer { isLoading = false }
        
        do {
            requests = try await prayerService.getPrayerFeed(category: category, offset: 0, limit: pageSize)
            offset = requests.count
        } catch {
            print("Error loading prayers: \(error)")
        }
    }
    
    func refresh() async {
        await load()
    }
    
    func loadMore() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        do {
            let more = try await prayerService.getPrayerFeed(offset: offset, limit: pageSize)
            requests.append(contentsOf: more)
            offset = requests.count
        } catch {
            print("Error loading more prayers: \(error)")
        }
    }
}

#Preview {
    PrayModeView()
        .environmentObject(ThemeManager.shared)
}


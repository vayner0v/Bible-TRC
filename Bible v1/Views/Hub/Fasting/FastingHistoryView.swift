//
//  FastingHistoryView.swift
//  Bible v1
//
//  Spiritual Hub - Fasting History
//

import SwiftUI

struct FastingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    @State private var selectedFilter: FastingStatus? = nil
    @State private var selectedFast: FastingEntry?
    
    var filteredFasts: [FastingEntry] {
        if let filter = selectedFilter {
            return storageService.fastingEntries.filter { $0.status == filter }
        }
        return storageService.fastingEntries
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        FilterPill(title: "Completed", isSelected: selectedFilter == .completed) {
                            selectedFilter = .completed
                        }
                        FilterPill(title: "Active", isSelected: selectedFilter == .active) {
                            selectedFilter = .active
                        }
                        FilterPill(title: "Ended Early", isSelected: selectedFilter == .broken) {
                            selectedFilter = .broken
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(UIColor.secondarySystemBackground))
                
                // List
                if filteredFasts.isEmpty {
                    ContentUnavailableView {
                        Label("No Fasts", systemImage: "moon.stars")
                    } description: {
                        Text("Your fasting history will appear here")
                    }
                } else {
                    List {
                        ForEach(groupedByMonth.keys.sorted().reversed(), id: \.self) { month in
                            Section(month) {
                                ForEach(groupedByMonth[month] ?? []) { fast in
                                    FastHistoryDetailRow(fast: fast)
                                        .onTapGesture {
                                            selectedFast = fast
                                        }
                                }
                                .onDelete { indexSet in
                                    deleteFasts(at: indexSet, in: month)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fasting History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedFast) { fast in
                FastDetailSheet(fast: fast)
            }
        }
    }
    
    private var groupedByMonth: [String: [FastingEntry]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return Dictionary(grouping: filteredFasts) { fast in
            formatter.string(from: fast.startDate)
        }
    }
    
    private func deleteFasts(at indexSet: IndexSet, in month: String) {
        guard let fasts = groupedByMonth[month] else { return }
        for index in indexSet {
            storageService.deleteFastingEntry(fasts[index])
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Fast History Detail Row

struct FastHistoryDetailRow: View {
    let fast: FastingEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(fast.type.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: fast.type.icon)
                    .foregroundStyle(fast.type.color)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(fast.type.rawValue)
                        .font(.headline)
                    
                    statusBadge
                }
                
                Text(fast.durationString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if !fast.intention.isEmpty {
                    Text(fast.intention)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Date
            VStack(alignment: .trailing, spacing: 2) {
                Text(fast.startDate, style: .date)
                    .font(.caption)
                Text(fast.startDate, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusBadge: some View {
        Text(fast.status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch fast.status {
        case .completed: return .green
        case .active: return .blue
        case .broken: return .orange
        case .scheduled: return .gray
        }
    }
}

// MARK: - Fast Detail Sheet

struct FastDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let fast: FastingEntry
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(fast.type.color.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: fast.type.icon)
                                .font(.largeTitle)
                                .foregroundStyle(fast.type.color)
                        }
                        
                        Text(fast.type.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        statusBadge
                    }
                    .padding()
                    
                    // Details grid
                    VStack(spacing: 16) {
                        DetailRow(label: "Started", value: formattedDate(fast.startDate))
                        
                        if let endDate = fast.actualEndDate {
                            DetailRow(label: "Ended", value: formattedDate(endDate))
                        } else {
                            DetailRow(label: "Planned End", value: formattedDate(fast.plannedEndDate))
                        }
                        
                        DetailRow(label: "Duration", value: fast.durationString)
                        
                        if let actualHours = fast.actualDurationHours {
                            DetailRow(label: "Actual Duration", value: "\(actualHours) hours")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Intention
                    if !fast.intention.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intention")
                                .font(.headline)
                            Text(fast.intention)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Reflection
                    if let reflection = fast.reflection, !reflection.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reflection")
                                .font(.headline)
                            Text(reflection)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Spiritual insights
                    if let insights = fast.spiritualInsights, !insights.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spiritual Insights")
                                .font(.headline)
                            Text(insights)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Fast Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var statusBadge: some View {
        Text(fast.status.rawValue)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch fast.status {
        case .completed: return .green
        case .active: return .blue
        case .broken: return .orange
        case .scheduled: return .gray
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    FastingHistoryView()
}









//
//  CrossReferenceExplorerView.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Interactive Cross-Reference Visual Explorer
//

import SwiftUI

struct CrossReferenceExplorerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var crossRefService = CrossReferenceService.shared
    
    let initialVerse: String
    let onNavigateToVerse: (String) -> Void
    
    @State private var graph = CrossReferenceGraph()
    @State private var selectedNode: VerseNode?
    @State private var selectedConnection: VerseConnection?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showFilters = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if graph.nodes.isEmpty {
                    emptyStateView
                } else {
                    graphView
                }
                
                // Detail panel
                if let node = selectedNode {
                    VStack {
                        Spacer()
                        nodeDetailCard(node)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Cross-References")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(ConnectionType.allCases) { type in
                            Button {
                                toggleConnectionType(type)
                            } label: {
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.displayName)
                                    if crossRefService.selectedConnectionTypes.contains(type) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                await loadGraph()
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Building cross-reference map...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Cross-References Found")
                .font(.headline)
            
            Text("No direct connections were found for this verse.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var graphView: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw connections
                ForEach(filteredConnections, id: \.id) { connection in
                    ConnectionLine(
                        connection: connection,
                        graph: graph,
                        geometry: geometry
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedConnection = connection
                        }
                    }
                }
                
                // Draw nodes
                ForEach(Array(graph.nodes.values), id: \.id) { node in
                    NodeView(
                        node: node,
                        isCenter: node.reference == graph.centerVerse,
                        isSelected: selectedNode?.id == node.id,
                        geometry: geometry
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedNode?.id == node.id {
                                selectedNode = nil
                            } else {
                                selectedNode = node
                                selectedConnection = nil
                            }
                        }
                    }
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(value, 0.5), 2.0)
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
            )
        }
        .padding()
    }
    
    private func nodeDetailCard(_ node: VerseNode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(node.displayReference)
                        .font(.headline)
                    
                    Text(node.testament.displayName)
                        .font(.caption)
                        .foregroundColor(node.testament.color)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        selectedNode = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Connections
            let nodeConnections = graph.connections.filter {
                $0.sourceReference == node.reference || $0.targetReference == node.reference
            }
            
            if !nodeConnections.isEmpty {
                Text("Connections")
                    .font(.subheadline.bold())
                
                ForEach(nodeConnections, id: \.id) { connection in
                    HStack {
                        Circle()
                            .fill(connection.connectionType.color)
                            .frame(width: 8, height: 8)
                        
                        let otherRef = connection.sourceReference == node.reference 
                            ? connection.targetReference 
                            : connection.sourceReference
                        
                        Text(otherRef)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(connection.connectionType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Actions
            HStack {
                Button {
                    onNavigateToVerse(node.reference)
                    dismiss()
                } label: {
                    Label("Read Verse", systemImage: "book")
                }
                .buttonStyle(.borderedProminent)
                
                if node.reference != graph.centerVerse {
                    Button {
                        Task {
                            await exploreFromNode(node)
                        }
                    } label: {
                        Label("Explore", systemImage: "arrow.triangle.branch")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
        .padding()
    }
    
    // MARK: - Helpers
    
    private var filteredConnections: [VerseConnection] {
        graph.connections.filter { crossRefService.selectedConnectionTypes.contains($0.connectionType) }
    }
    
    private func toggleConnectionType(_ type: ConnectionType) {
        if crossRefService.selectedConnectionTypes.contains(type) {
            crossRefService.selectedConnectionTypes.remove(type)
        } else {
            crossRefService.selectedConnectionTypes.insert(type)
        }
    }
    
    private func loadGraph() async {
        isLoading = true
        graph = await crossRefService.buildGraph(for: initialVerse, depth: 1)
        isLoading = false
    }
    
    private func exploreFromNode(_ node: VerseNode) async {
        isLoading = true
        graph = await crossRefService.buildGraph(for: node.reference, depth: 1)
        selectedNode = nil
        isLoading = false
    }
}

// MARK: - Node View

struct NodeView: View {
    let node: VerseNode
    let isCenter: Bool
    let isSelected: Bool
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            Circle()
                .fill(node.testament.color.opacity(0.2))
                .frame(width: nodeSize, height: nodeSize)
            
            Circle()
                .stroke(isSelected ? Color.accentColor : node.testament.color, lineWidth: isSelected ? 3 : 2)
                .frame(width: nodeSize, height: nodeSize)
            
            VStack(spacing: 2) {
                Text(node.bookName)
                    .font(.system(size: isCenter ? 10 : 8, weight: .semibold))
                
                Text("\(node.chapter):\(node.verseStart)")
                    .font(.system(size: isCenter ? 12 : 10, weight: .bold))
            }
            .foregroundColor(node.testament.color)
        }
        .position(adjustedPosition)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var nodeSize: CGFloat {
        isCenter ? 80 : 60
    }
    
    private var adjustedPosition: CGPoint {
        CGPoint(
            x: node.position.x + geometry.size.width / 2 - 200,
            y: node.position.y + geometry.size.height / 2 - 200
        )
    }
}

// MARK: - Connection Line

struct ConnectionLine: View {
    let connection: VerseConnection
    let graph: CrossReferenceGraph
    let geometry: GeometryProxy
    
    var body: some View {
        Path { path in
            guard let source = graph.nodes[connection.sourceReference],
                  let target = graph.nodes[connection.targetReference] else { return }
            
            let sourcePoint = adjustedPosition(source.position)
            let targetPoint = adjustedPosition(target.position)
            
            path.move(to: sourcePoint)
            path.addLine(to: targetPoint)
        }
        .stroke(
            connection.connectionType.color,
            style: StrokeStyle(
                lineWidth: connection.strength.lineWidth,
                lineCap: .round,
                dash: connection.connectionType == .thematicLink ? [5, 5] : []
            )
        )
        .opacity(connection.strength.opacity)
    }
    
    private func adjustedPosition(_ position: CGPoint) -> CGPoint {
        CGPoint(
            x: position.x + geometry.size.width / 2 - 200,
            y: position.y + geometry.size.height / 2 - 200
        )
    }
}

// MARK: - Legend View

struct ConnectionLegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connection Types")
                .font(.caption.bold())
            
            ForEach(ConnectionType.allCases) { type in
                HStack(spacing: 8) {
                    Circle()
                        .fill(type.color)
                        .frame(width: 10, height: 10)
                    
                    Text(type.displayName)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(12)
    }
}

#Preview {
    CrossReferenceExplorerView(
        initialVerse: "John 3:16",
        onNavigateToVerse: { _ in }
    )
}




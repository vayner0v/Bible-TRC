//
//  RoutineManagerView.swift
//  Bible v1
//
//  Manage multiple custom routines - create, edit, delete, duplicate
//

import SwiftUI

struct RoutineManagerView: View {
    @ObservedObject var viewModel: HubViewModel
    @Binding var selectedConfiguration: RoutineConfiguration?
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    @State private var showCreateRoutine = false
    @State private var routineToEdit: RoutineConfiguration?
    @State private var routineToDelete: RoutineConfiguration?
    @State private var showDeleteConfirmation = false
    @State private var selectedFilter: RoutineMode? = nil
    
    private var filteredRoutines: [RoutineConfiguration] {
        let routines = viewModel.getAllRoutineConfigurations()
        if let filter = selectedFilter {
            return routines.filter { $0.mode == filter || $0.mode == .anytime }
        }
        return routines
    }
    
    private var morningRoutines: [RoutineConfiguration] {
        filteredRoutines.filter { $0.mode == .morning }
    }
    
    private var eveningRoutines: [RoutineConfiguration] {
        filteredRoutines.filter { $0.mode == .evening }
    }
    
    private var anytimeRoutines: [RoutineConfiguration] {
        filteredRoutines.filter { $0.mode == .anytime }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Journal.paper.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Filter pills
                        filterPills
                        
                        // Morning routines
                        if !morningRoutines.isEmpty || selectedFilter == nil || selectedFilter == .morning {
                            routineSection(
                                title: "Morning Routines",
                                icon: "sunrise.fill",
                                routines: morningRoutines,
                                mode: .morning
                            )
                        }
                        
                        // Evening routines
                        if !eveningRoutines.isEmpty || selectedFilter == nil || selectedFilter == .evening {
                            routineSection(
                                title: "Evening Routines",
                                icon: "moon.stars.fill",
                                routines: eveningRoutines,
                                mode: .evening
                            )
                        }
                        
                        // Anytime routines
                        if !anytimeRoutines.isEmpty {
                            routineSection(
                                title: "Anytime Routines",
                                icon: "clock.fill",
                                routines: anytimeRoutines,
                                mode: .anytime
                            )
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("My Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(accessibility.bodyFont())
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateRoutine = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.Journal.Morning.primary)
                    }
                }
            }
            .sheet(isPresented: $showCreateRoutine) {
                RoutineEditorView(viewModel: viewModel, routine: nil)
            }
            .sheet(item: $routineToEdit) { routine in
                RoutineEditorView(viewModel: viewModel, routine: routine)
            }
            .alert("Delete Routine?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let routine = routineToDelete {
                        viewModel.deleteRoutineConfiguration(routine)
                    }
                }
            } message: {
                if let routine = routineToDelete {
                    Text("Are you sure you want to delete \"\(routine.name)\"? This cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Filter Pills
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                RoutineFilterPill(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    color: Color.Journal.warmBrown
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = nil
                    }
                }
                
                RoutineFilterPill(
                    title: "Morning",
                    icon: "sunrise.fill",
                    isSelected: selectedFilter == .morning,
                    color: Color.Journal.Morning.primary
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = .morning
                    }
                }
                
                RoutineFilterPill(
                    title: "Evening",
                    icon: "moon.stars.fill",
                    isSelected: selectedFilter == .evening,
                    color: Color.Journal.Evening.primary
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedFilter = .evening
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Routine Section
    
    private func routineSection(title: String, icon: String, routines: [RoutineConfiguration], mode: RoutineMode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(mode.accentColor)
                
                Text(title)
                    .font(accessibility.headingFont(size: 17))
                    .foregroundColor(Color.Journal.inkBrown)
                
                Spacer()
            }
            
            if routines.isEmpty {
                emptyStateCard(mode: mode)
            } else {
                ForEach(routines) { routine in
                    routineCard(routine)
                }
            }
        }
    }
    
    // MARK: - Routine Card
    
    private func routineCard(_ routine: RoutineConfiguration) -> some View {
        Button {
            selectedConfiguration = routine
            dismiss()
        } label: {
            RoutineJournalCard(mode: routine.mode, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header row
                    HStack(alignment: .top) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(routine.accentColor.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: routine.icon)
                                .font(.system(size: 18))
                                .foregroundColor(routine.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(routine.name)
                                    .font(accessibility.headingFont(size: 17))
                                    .foregroundColor(Color.Journal.inkBrown)
                                
                                if routine.isDefault {
                                    Text("Default")
                                        .font(accessibility.captionFont(size: 11))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(routine.accentColor)
                                        )
                                }
                            }
                            
                            if !routine.description.isEmpty {
                                Text(routine.description)
                                    .font(accessibility.captionFont())
                                    .foregroundColor(Color.Journal.mutedText)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Menu
                        Menu {
                            Button {
                                routineToEdit = routine
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button {
                                let duplicate = viewModel.duplicateRoutineConfiguration(routine)
                                routineToEdit = duplicate
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            
                            if !routine.isDefault {
                                Button {
                                    viewModel.setDefaultRoutine(id: routine.id, for: routine.mode)
                                } label: {
                                    Label("Set as Default", systemImage: "star")
                                }
                            }
                            
                            Divider()
                            
                            if routine.isCustom {
                                Button(role: .destructive) {
                                    routineToDelete = routine
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(Color.Journal.mutedText)
                                .frame(width: 32, height: 32)
                        }
                    }
                    
                    JournalDivider(mode: routine.mode, style: .dotted)
                    
                    // Stats row
                    HStack(spacing: 16) {
                        // Steps count
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 12))
                            Text("\(routine.stepCount) steps")
                                .font(accessibility.captionFont())
                        }
                        .foregroundColor(Color.Journal.mutedText)
                        
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(routine.formattedTotalDuration)
                                .font(accessibility.captionFont())
                        }
                        .foregroundColor(Color.Journal.mutedText)
                        
                        // Completions
                        if routine.completionCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("\(routine.completionCount)x")
                                    .font(accessibility.captionFont())
                            }
                            .foregroundColor(routine.accentColor)
                        }
                        
                        Spacer()
                    }
                    
                    // Linked habits
                    if !routine.linkedHabits.isEmpty {
                        HStack(spacing: 8) {
                            Text("Auto-tracks:")
                                .font(accessibility.captionFont(size: 11))
                                .foregroundColor(Color.Journal.mutedText)
                            
                            ForEach(routine.linkedHabits.prefix(3), id: \.self) { habit in
                                Image(systemName: habit.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(habit.color)
                            }
                            
                            if routine.linkedHabits.count > 3 {
                                Text("+\(routine.linkedHabits.count - 3)")
                                    .font(accessibility.captionFont(size: 11))
                                    .foregroundColor(Color.Journal.mutedText)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private func emptyStateCard(mode: RoutineMode) -> some View {
        RoutineJournalCard(mode: mode, padding: 20) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 32))
                    .foregroundColor(Color.Journal.mutedText.opacity(0.5))
                
                Text("No \(mode.displayName.lowercased()) routines yet")
                    .font(accessibility.bodyFont(size: 15))
                    .foregroundColor(Color.Journal.mutedText)
                
                Button {
                    showCreateRoutine = true
                } label: {
                    Text("Create One")
                        .font(accessibility.captionFont())
                        .fontWeight(.medium)
                        .foregroundColor(mode.accentColor)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Routine Filter Pill

struct RoutineFilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                
                Text(title)
                    .font(accessibility.captionFont())
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Routine Editor View

struct RoutineEditorView: View {
    @ObservedObject var viewModel: HubViewModel
    let routine: RoutineConfiguration?
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: EditorField?
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    enum EditorField: Hashable {
        case name
        case description
    }
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var mode: RoutineMode = .morning
    @State private var icon: String = "sparkles"
    @State private var steps: [RoutineStep] = []
    @State private var linkedHabits: Set<SpiritualHabit> = []
    @State private var showIconPicker = false
    @State private var showAddStep = false
    
    private var isEditing: Bool {
        routine != nil
    }
    
    private var isValid: Bool {
        !name.isEmpty && !steps.isEmpty
    }
    
    init(viewModel: HubViewModel, routine: RoutineConfiguration?) {
        self.viewModel = viewModel
        self.routine = routine
        
        if let routine = routine {
            _name = State(initialValue: routine.name)
            _description = State(initialValue: routine.description)
            _mode = State(initialValue: routine.mode)
            _icon = State(initialValue: routine.icon)
            _steps = State(initialValue: routine.steps)
            _linkedHabits = State(initialValue: Set(routine.linkedHabits))
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Journal.paper.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                        hideKeyboard()
                    }
                
                Form {
                    // Basic info section
                    Section {
                        HStack(spacing: 12) {
                            // Icon button
                            Button {
                                showIconPicker = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(mode.accentColor.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(mode.accentColor)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Routine Name", text: $name)
                                    .font(accessibility.headingFont(size: 17))
                                    .foregroundColor(Color.Journal.inkBrown)
                                    .focused($focusedField, equals: .name)
                                
                                TextField("Description (optional)", text: $description)
                                    .font(accessibility.captionFont())
                                    .foregroundColor(Color.Journal.mutedText)
                                    .focused($focusedField, equals: .description)
                            }
                        }
                        .listRowBackground(Color.Journal.cardBackground)
                        
                        Picker("Time of Day", selection: $mode) {
                            ForEach([RoutineMode.morning, .evening, .anytime], id: \.self) { mode in
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode.displayName)
                                }
                                .tag(mode)
                            }
                        }
                        .font(accessibility.bodyFont())
                        .listRowBackground(Color.Journal.cardBackground)
                    } header: {
                        Text("Routine Info")
                            .font(accessibility.captionFont())
                    }
                    
                    // Steps section
                    Section {
                        ForEach(steps) { step in
                            HStack(spacing: 12) {
                                Image(systemName: step.category.icon)
                                    .foregroundColor(step.category.color)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.title)
                                        .font(accessibility.bodyFont(size: 15))
                                        .fontWeight(.medium)
                                    
                                    if let duration = step.formattedDuration {
                                        Text(duration)
                                            .font(accessibility.captionFont())
                                            .foregroundColor(Color.Journal.mutedText)
                                    }
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { step.isEnabled },
                                    set: { newValue in
                                        if let index = steps.firstIndex(where: { $0.id == step.id }) {
                                            steps[index].isEnabled = newValue
                                        }
                                    }
                                ))
                                .tint(mode.accentColor)
                            }
                            .listRowBackground(Color.Journal.cardBackground)
                        }
                        .onMove { from, to in
                            steps.move(fromOffsets: from, toOffset: to)
                            for i in 0..<steps.count {
                                steps[i].order = i
                            }
                        }
                        .onDelete { offsets in
                            steps.remove(atOffsets: offsets)
                        }
                        
                        Button {
                            showAddStep = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Step")
                                    .font(accessibility.bodyFont())
                            }
                            .foregroundColor(mode.accentColor)
                        }
                        .listRowBackground(Color.Journal.cardBackground)
                    } header: {
                        HStack {
                            Text("Steps")
                                .font(accessibility.captionFont())
                            Spacer()
                            EditButton()
                                .font(accessibility.captionFont())
                        }
                    }
                    
                    // Linked habits section
                    Section {
                        ForEach(SpiritualHabit.allCases) { habit in
                            Button {
                                if linkedHabits.contains(habit) {
                                    linkedHabits.remove(habit)
                                } else {
                                    linkedHabits.insert(habit)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: habit.icon)
                                        .foregroundColor(habit.color)
                                        .frame(width: 24)
                                    
                                    Text(habit.rawValue)
                                        .font(accessibility.bodyFont())
                                        .foregroundColor(Color.Journal.inkBrown)
                                    
                                    Spacer()
                                    
                                    if linkedHabits.contains(habit) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(mode.accentColor)
                                    }
                                }
                            }
                            .listRowBackground(Color.Journal.cardBackground)
                        }
                    } header: {
                        Text("Auto-Track Habits")
                            .font(accessibility.captionFont())
                    } footer: {
                        Text("These habits will be automatically marked complete when you finish this routine")
                            .font(accessibility.captionFont(size: 11))
                    }
                }
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(accessibility.bodyFont())
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .font(accessibility.bodyFont())
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                        hideKeyboard()
                    }
                    .font(accessibility.bodyFont())
                    .fontWeight(.semibold)
                    .foregroundColor(mode.accentColor)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $icon, accentColor: mode.accentColor)
            }
            .sheet(isPresented: $showAddStep) {
                AddStepView(mode: mode) { newStep in
                    var step = newStep
                    step.order = steps.count
                    steps.append(step)
                }
            }
        }
    }
    
    private func saveRoutine() {
        let configuration = RoutineConfiguration(
            id: routine?.id ?? UUID(),
            name: name,
            description: description,
            steps: steps,
            mode: mode,
            createdAt: routine?.createdAt ?? Date(),
            lastUsedAt: routine?.lastUsedAt,
            completionCount: routine?.completionCount ?? 0,
            isDefault: routine?.isDefault ?? false,
            isCustom: true,
            icon: icon,
            linkedHabits: Array(linkedHabits)
        )
        
        if isEditing {
            viewModel.updateRoutineConfiguration(configuration)
        } else {
            viewModel.addRoutineConfiguration(configuration)
        }
        
        dismiss()
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    @Binding var selectedIcon: String
    let accentColor: Color
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var accessibility = AccessibilityManager.shared
    
    private let icons = [
        "sparkles", "star.fill", "heart.fill", "sun.max.fill", "moon.stars.fill",
        "sunrise.fill", "sunset.fill", "cloud.fill", "leaf.fill", "flame.fill",
        "hands.sparkles", "figure.mind.and.body", "cross.fill", "book.fill",
        "text.book.closed.fill", "quote.opening", "lightbulb.fill", "brain.head.profile",
        "wind", "drop.fill", "bolt.fill", "waveform.path.ecg", "heart.circle.fill"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Journal.paper.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                                dismiss()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? accentColor.opacity(0.2) : Color.Journal.cardBackground)
                                        .frame(width: 56, height: 56)
                                    
                                    Circle()
                                        .strokeBorder(selectedIcon == icon ? accentColor : Color.clear, lineWidth: 2)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(selectedIcon == icon ? accentColor : Color.Journal.mutedText)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(accessibility.bodyFont())
                }
            }
        }
    }
}

#Preview {
    RoutineManagerView(viewModel: HubViewModel(), selectedConfiguration: .constant(nil))
}


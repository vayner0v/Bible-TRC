//
//  SettingsComponents.swift
//  Bible v1
//
//  Reusable settings UI components
//

import SwiftUI
import Combine

// #region agent log
/// Debug logging helper for slider debugging - prints to console for visibility
@discardableResult
private func debugLog(location: String, message: String, data: [String: Any], hypothesisId: String) -> Bool {
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let dataStr = data.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    let logLine = "🔍 [\(hypothesisId)] \(location): \(message) | \(dataStr)"
    print(logLine)
    
    // Also write to file
    let logPath = "/Users/vayner0v/Desktop/Bible /Bible v1/.cursor/debug.log"
    let jsonLine = "{\"location\":\"\(location)\",\"message\":\"\(message)\",\"data\":{\(data.map { "\"\($0.key)\":\"\($0.value)\"" }.joined(separator: ","))},\"timestamp\":\(timestamp),\"hypothesisId\":\"\(hypothesisId)\"}\n"
    if let handle = FileHandle(forWritingAtPath: logPath) {
        handle.seekToEndOfFile()
        if let d = jsonLine.data(using: .utf8) { handle.write(d) }
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logPath, contents: jsonLine.data(using: .utf8))
    }
    return true
}
// #endregion

// MARK: - Settings Summary Row

/// A row that shows a setting with its current value, tapping navigates to detail
struct SettingsSummaryRow<Destination: View>: View {
    let icon: String
    let title: String
    let summary: String
    let destination: Destination
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(themeManager.textColor)
                    
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
            }
            .padding(.vertical, 4)
        }
        .accessibilityLabel("\(title), \(summary)")
        .accessibilityHint("Double tap to open settings")
    }
}

// MARK: - Settings Toggle Row

/// A consistent toggle row with icon and optional subtitle
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(icon: String, title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(themeManager.textColor)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
        }
        .tint(themeManager.accentColor)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(subtitle ?? "")
    }
}

// MARK: - Settings Slider Row

/// An enhanced slider with tick marks, haptics, and value display
/// Optimized to use local state during dragging to prevent lag
struct SettingsSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tickMarks: [Double]?
    let formatValue: (Double) -> String
    let onChange: ((Double) -> Void)?
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var localValue: Double = 0
    @State private var isDragging: Bool = false
    @State private var lastHapticValue: Double = 0
    
    init(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 0.1,
        tickMarks: [Double]? = nil,
        formatValue: @escaping (Double) -> String = { String(format: "%.1f", $0) },
        onChange: ((Double) -> Void)? = nil
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.tickMarks = tickMarks
        self.formatValue = formatValue
        self.onChange = onChange
    }
    
    /// The displayed value - uses local state during dragging for smooth updates
    /// Always clamps to range to prevent showing invalid values
    private var displayValue: Double {
        let rawValue = isDragging ? localValue : value
        return min(max(rawValue, range.lowerBound), range.upperBound)
    }
    
    var body: some View {
        // #region agent log
        let _ = debugLog(location: "SettingsSliderRow.body", message: "Rendering slider", data: ["title": title, "value": value, "localValue": localValue, "isDragging": isDragging, "displayValue": displayValue, "range": "\(range)"], hypothesisId: "A,B,C")
        // #endregion
        return VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
                
                Text(formatValue(displayValue))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)
                    .monospacedDigit()
            }
            
            ZStack(alignment: .center) {
                // Tick marks
                if let ticks = tickMarks {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(ticks, id: \.self) { tick in
                                let position = (tick - range.lowerBound) / (range.upperBound - range.lowerBound)
                                
                                Circle()
                                    .fill(displayValue >= tick ? themeManager.accentColor : themeManager.secondaryTextColor.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .position(
                                        x: geometry.size.width * position,
                                        y: geometry.size.height / 2
                                    )
                            }
                        }
                    }
                    .frame(height: 20)
                }
                
                Slider(
                    value: isDragging ? $localValue : $value,
                    in: range,
                    step: step,
                    onEditingChanged: { editing in
                        // #region agent log
                        debugLog(location: "SettingsSliderRow.onEditingChanged", message: "Editing changed", data: ["editing": editing, "value": value, "localValue": localValue], hypothesisId: "B,D")
                        // #endregion
                        if editing {
                            // Starting to drag - copy current value to local state
                            localValue = value
                            isDragging = true
                            lastHapticValue = value
                        } else {
                            // Finished dragging - commit the value
                            isDragging = false
                            value = localValue
                            onChange?(localValue)
                        }
                    }
                )
                .tint(themeManager.accentColor)
                // Ensure slider captures horizontal gestures before parent views
                .defersSystemGestures(on: .horizontal)
                .onChange(of: localValue) { oldValue, newValue in
                    // Only provide haptic feedback during dragging
                    if isDragging {
                        provideTickHaptic(from: oldValue, to: newValue)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(formatValue(displayValue))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
                onChange?(value)
            case .decrement:
                value = max(value - step, range.lowerBound)
                onChange?(value)
            @unknown default:
                break
            }
        }
        .onAppear {
            // #region agent log
            let isOutOfRange = value < range.lowerBound || value > range.upperBound
            debugLog(location: "SettingsSliderRow.onAppear", message: "Slider appeared", data: ["value": value, "localValue_before": localValue, "isDragging": isDragging, "range": "\(range)", "isOutOfRange": isOutOfRange], hypothesisId: "A")
            // #endregion
            // CRITICAL: Clamp value to range if out of bounds and commit back
            if value < range.lowerBound {
                debugLog(location: "SettingsSliderRow.onAppear", message: "VALUE BELOW RANGE - clamping and committing", data: ["value": value, "clamping_to": range.lowerBound], hypothesisId: "A")
                localValue = range.lowerBound
                value = range.lowerBound  // Commit the clamped value back to binding
            } else if value > range.upperBound {
                debugLog(location: "SettingsSliderRow.onAppear", message: "VALUE ABOVE RANGE - clamping and committing", data: ["value": value, "clamping_to": range.upperBound], hypothesisId: "A")
                localValue = range.upperBound
                value = range.upperBound  // Commit the clamped value back to binding
            } else {
                localValue = value
            }
            lastHapticValue = localValue
        }
        .onChange(of: value) { _, newValue in
            // #region agent log
            debugLog(location: "SettingsSliderRow.onChange(value)", message: "External value changed", data: ["newValue": newValue, "isDragging": isDragging, "willSync": !isDragging], hypothesisId: "D")
            // #endregion
            // Sync local value when external value changes (and not dragging)
            if !isDragging {
                localValue = newValue
            }
        }
    }
    
    private func provideTickHaptic(from oldValue: Double, to newValue: Double) {
        guard let ticks = tickMarks else { return }
        
        for tick in ticks {
            let crossedUp = oldValue < tick && newValue >= tick
            let crossedDown = oldValue > tick && newValue <= tick
            if crossedUp || crossedDown {
                HapticManager.shared.selection()
                break
            }
        }
    }
}

// MARK: - Settings Picker Row

/// A picker row that works inline or as navigation
struct SettingsPickerRow<T: Hashable & Identifiable>: View where T: CustomStringConvertible {
    let icon: String?
    let title: String
    @Binding var selection: T
    let options: [T]
    let style: PickerStyle
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    enum PickerStyle {
        case inline
        case navigation
        case segmented
    }
    
    init(
        icon: String? = nil,
        title: String,
        selection: Binding<T>,
        options: [T],
        style: PickerStyle = .inline
    ) {
        self.icon = icon
        self.title = title
        self._selection = selection
        self.options = options
        self.style = style
    }
    
    var body: some View {
        Group {
            switch style {
            case .inline:
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 28)
                    }
                    
                    Picker(title, selection: $selection) {
                        ForEach(options) { option in
                            Text(option.description).tag(option)
                        }
                    }
                    .tint(themeManager.accentColor)
                }
                
            case .navigation:
                NavigationLink {
                    List {
                        ForEach(options) { option in
                            Button {
                                selection = option
                            } label: {
                                HStack {
                                    Text(option.description)
                                        .foregroundColor(themeManager.textColor)
                                    Spacer()
                                    if selection.id == option.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(themeManager.accentColor)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle(title)
                } label: {
                    HStack(spacing: 12) {
                        if let icon = icon {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(themeManager.accentColor)
                                .frame(width: 28)
                        }
                        
                        Text(title)
                            .foregroundColor(themeManager.textColor)
                        
                        Spacer()
                        
                        Text(selection.description)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                    }
                }
                
            case .segmented:
                VStack(alignment: .leading, spacing: 8) {
                    if let icon = icon {
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .foregroundColor(themeManager.accentColor)
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                    } else {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    
                    Picker(title, selection: $selection) {
                        ForEach(options) { option in
                            Text(option.description).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .onChange(of: selection) { _, _ in
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Collapsible Section

/// A section that can be expanded/collapsed
struct CollapsibleSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.selection()
            } label: {
                HStack {
                    Text(title.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .accessibilityLabel(title)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
            
            // Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    content()
                }
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Resettable Section

/// A settings section with built-in reset functionality
struct ResettableSection<Content: View>: View {
    let title: String
    let resetTitle: String
    let onReset: () -> Void
    @ViewBuilder let content: () -> Content
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showResetConfirmation = false
    
    init(
        title: String,
        resetTitle: String = "Reset to Defaults",
        onReset: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.resetTitle = resetTitle
        self.onReset = onReset
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 0) {
                content()
                
                Divider()
                    .background(themeManager.dividerColor)
                    .padding(.vertical, 12)
                
                Button {
                    showResetConfirmation = true
                } label: {
                    Text(resetTitle)
                        .font(.subheadline)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
        .confirmationDialog("Reset Settings", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                onReset()
                HapticManager.shared.success()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset all settings in this section to their default values.")
        }
    }
}

// MARK: - Destructive Action Row

/// A row for destructive actions with confirmation
struct DestructiveActionRow: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let requiresTyping: Bool
    let confirmationText: String
    let onConfirm: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showSheet = false
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        requiresTyping: Bool = false,
        confirmationText: String = "DELETE",
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.requiresTyping = requiresTyping
        self.confirmationText = confirmationText
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.red)
                        .frame(width: 28)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.red)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showSheet) {
            DestructiveConfirmationSheet(
                title: title,
                requiresTyping: requiresTyping,
                confirmationText: confirmationText,
                onConfirm: {
                    showSheet = false
                    onConfirm()
                }
            )
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Destructive Confirmation Sheet

struct DestructiveConfirmationSheet: View {
    let title: String
    let requiresTyping: Bool
    let confirmationText: String
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var typedText = ""
    
    private var canConfirm: Bool {
        !requiresTyping || typedText.uppercased() == confirmationText.uppercased()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text("Are you sure?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This action cannot be undone.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
                
                if requiresTyping {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type \"\(confirmationText)\" to confirm:")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        TextField("", text: $typedText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding()
                            .background(themeManager.backgroundColor)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(canConfirm ? Color.red : themeManager.dividerColor, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button {
                        HapticManager.shared.error()
                        onConfirm()
                    } label: {
                        Text(title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canConfirm ? Color.red : Color.red.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .disabled(!canConfirm)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.cardBackgroundColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 40)
            .padding(.bottom)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Quick Settings Section

/// A compact section for frequently-used settings
struct QuickSettingsSection: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK SETTINGS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.secondaryTextColor)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                // Theme picker (segmented)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    HStack(spacing: 8) {
                        ForEach(AppTheme.allCases) { theme in
                            QuickThemeButton(
                                theme: theme,
                                isSelected: settings.selectedTheme == theme
                            ) {
                                settings.selectedTheme = theme
                                HapticManager.shared.selection()
                            }
                        }
                    }
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Reader size slider (compact)
                SettingsSliderRow(
                    title: "Reader Text Size",
                    value: $settings.readerTextOffset,
                    range: 0.70...2.0,
                    step: 0.05,
                    tickMarks: [0.70, 1.0, 1.25, 1.5, 1.75, 2.0],
                    formatValue: { String(format: "%.0f%%", $0 * 100) }
                )
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Voice toggle
                HStack {
                    SettingsToggleRow(
                        icon: "waveform",
                        title: "Premium Voice",
                        subtitle: "AI-powered narration",
                        isOn: Binding(
                            get: { settings.preferredVoiceType == .premium },
                            set: { settings.preferredVoiceType = $0 ? .premium : .builtin }
                        )
                    )
                }
                
                Divider()
                    .background(themeManager.dividerColor)
                
                // Auto-continue toggle
                SettingsToggleRow(
                    icon: "arrow.right.circle",
                    title: "Auto-Continue",
                    subtitle: "Play next chapter automatically",
                    isOn: $settings.autoContinueToNextChapter
                )
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(14)
        }
    }
}

// MARK: - Quick Theme Button

struct QuickThemeButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: theme.icon)
                    .font(.title3)
                
                Text(theme.displayName)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? themeManager.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? themeManager.accentColor : themeManager.secondaryTextColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? themeManager.accentColor : themeManager.dividerColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Settings Row (Legacy Support)

/// Basic settings row for simple display
struct SettingsInfoRow: View {
    let icon: String?
    let title: String
    let value: String
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(icon: String? = nil, title: String, value: String) {
        self.icon = icon
        self.title = title
        self.value = value
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 28)
            }
            
            Text(title)
                .foregroundColor(themeManager.textColor)
            
            Spacer()
            
            Text(value)
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            VStack(spacing: 24) {
                QuickSettingsSection()
                
                CollapsibleSection(title: "Example", isExpanded: .constant(true)) {
                    Text("Collapsible content here")
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Settings Preview")
    }
}


//
//  RichTextEditor.swift
//  Bible v1
//
//  Spiritual Journal - Rich Text Editor with Formatting
//

import SwiftUI
import UIKit

// MARK: - Rich Text Editor

/// A rich text editor with formatting capabilities
struct RichTextEditor: View {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var isBold = false
    @State private var isItalic = false
    @State private var isUnderline = false
    @State private var currentStyle: TextBlockStyle = .body
    
    @FocusState private var isFocused: Bool
    
    enum TextBlockStyle: String, CaseIterable {
        case body = "Body"
        case heading = "Heading"
        case quote = "Quote"
        case bulletList = "Bullet List"
        case numberedList = "Numbered List"
        
        var icon: String {
            switch self {
            case .body: return "text.alignleft"
            case .heading: return "textformat.size"
            case .quote: return "text.quote"
            case .bulletList: return "list.bullet"
            case .numberedList: return "list.number"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Formatting toolbar
            formattingToolbar
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(themeManager.cardBackgroundColor)
            
            Divider()
            
            // Text editor
            RichTextEditorRepresentable(
                text: $text,
                attributedText: $attributedText,
                selectedRange: $selectedRange,
                isBold: $isBold,
                isItalic: $isItalic,
                isUnderline: $isUnderline,
                textColor: UIColor(themeManager.textColor),
                backgroundColor: UIColor(themeManager.cardBackgroundColor)
            )
            .frame(minHeight: 200)
        }
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Formatting Toolbar
    
    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Style picker
                Menu {
                    ForEach(TextBlockStyle.allCases, id: \.self) { style in
                        Button {
                            currentStyle = style
                            applyBlockStyle(style)
                        } label: {
                            Label(style.rawValue, systemImage: style.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: currentStyle.icon)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(themeManager.backgroundColor)
                    .cornerRadius(8)
                }
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)
                
                // Bold
                formatButton(
                    icon: "bold",
                    isActive: isBold,
                    action: toggleBold
                )
                
                // Italic
                formatButton(
                    icon: "italic",
                    isActive: isItalic,
                    action: toggleItalic
                )
                
                // Underline
                formatButton(
                    icon: "underline",
                    isActive: isUnderline,
                    action: toggleUnderline
                )
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)
                
                // Bullet list
                formatButton(
                    icon: "list.bullet",
                    isActive: currentStyle == .bulletList,
                    action: { applyBlockStyle(.bulletList) }
                )
                
                // Numbered list
                formatButton(
                    icon: "list.number",
                    isActive: currentStyle == .numberedList,
                    action: { applyBlockStyle(.numberedList) }
                )
                
                // Quote
                formatButton(
                    icon: "text.quote",
                    isActive: currentStyle == .quote,
                    action: { applyBlockStyle(.quote) }
                )
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func formatButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: isActive ? .bold : .regular))
                .foregroundColor(isActive ? themeManager.accentColor : themeManager.textColor)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isActive ? themeManager.accentColor.opacity(0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Formatting Actions
    
    private func toggleBold() {
        isBold.toggle()
        applyFormatting()
    }
    
    private func toggleItalic() {
        isItalic.toggle()
        applyFormatting()
    }
    
    private func toggleUnderline() {
        isUnderline.toggle()
        applyFormatting()
    }
    
    private func applyFormatting() {
        guard selectedRange.length > 0 else { return }
        
        let mutableAttrString = NSMutableAttributedString(attributedString: attributedText)
        
        var traits: UIFontDescriptor.SymbolicTraits = []
        if isBold { traits.insert(.traitBold) }
        if isItalic { traits.insert(.traitItalic) }
        
        let baseFont = UIFont.systemFont(ofSize: 16)
        if let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) {
            let font = UIFont(descriptor: descriptor, size: 16)
            mutableAttrString.addAttribute(.font, value: font, range: selectedRange)
        }
        
        if isUnderline {
            mutableAttrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        } else {
            mutableAttrString.removeAttribute(.underlineStyle, range: selectedRange)
        }
        
        attributedText = mutableAttrString
    }
    
    private func applyBlockStyle(_ style: TextBlockStyle) {
        currentStyle = style
        
        // For now, we'll handle block styles through the plain text
        // A full implementation would modify the attributed string
        switch style {
        case .bulletList:
            insertPrefix("• ")
        case .numberedList:
            insertPrefix("1. ")
        case .quote:
            insertPrefix("> ")
        case .heading:
            insertPrefix("# ")
        case .body:
            break
        }
    }
    
    private func insertPrefix(_ prefix: String) {
        // Find the start of the current line
        let lines = text.components(separatedBy: .newlines)
        var currentPosition = 0
        
        for (index, line) in lines.enumerated() {
            let lineEnd = currentPosition + line.count
            
            if selectedRange.location >= currentPosition && selectedRange.location <= lineEnd {
                // Insert prefix at the start of this line
                var newLines = lines
                if !line.hasPrefix(prefix) {
                    newLines[index] = prefix + line
                }
                text = newLines.joined(separator: "\n")
                break
            }
            
            currentPosition = lineEnd + 1 // +1 for newline
        }
    }
}

// MARK: - UITextView Representable

struct RichTextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    @Binding var isBold: Bool
    @Binding var isItalic: Bool
    @Binding var isUnderline: Bool
    
    let textColor: UIColor
    let backgroundColor: UIColor
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.allowsEditingTextAttributes = true
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        
        // Set initial text
        if attributedText.length > 0 {
            textView.attributedText = attributedText
        } else {
            textView.text = text
        }
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Only update if the text has changed externally
        if textView.text != text && !context.coordinator.isEditing {
            if attributedText.length > 0 {
                textView.attributedText = attributedText
            } else {
                textView.text = text
            }
        }
        
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorRepresentable
        var isEditing = false
        
        init(_ parent: RichTextEditorRepresentable) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            isEditing = true
            parent.text = textView.text
            parent.attributedText = textView.attributedText
            isEditing = false
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            // Defer state update to avoid modifying state during view update
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.selectedRange = textView.selectedRange
                
                // Update formatting state based on selection
                if textView.selectedRange.length > 0 {
                    self.updateFormattingState(from: textView)
                }
            }
        }
        
        private func updateFormattingState(from textView: UITextView) {
            guard textView.selectedRange.length > 0 else { return }
            
            let attributes = textView.attributedText.attributes(at: textView.selectedRange.location, effectiveRange: nil)
            
            if let font = attributes[.font] as? UIFont {
                parent.isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                parent.isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            }
            
            parent.isUnderline = attributes[.underlineStyle] != nil
        }
    }
}

// MARK: - Simple Markdown Renderer

/// Renders simple markdown-style text
struct MarkdownRenderer {
    
    /// Convert markdown-style text to AttributedString
    static func render(_ text: String, textColor: Color, accentColor: Color) -> AttributedString {
        var result = AttributedString(text)
        
        // Process line by line for block elements
        let lines = text.components(separatedBy: .newlines)
        var processedText = ""
        
        for line in lines {
            var processedLine = line
            
            // Headings
            if line.hasPrefix("# ") {
                processedLine = String(line.dropFirst(2))
                // Mark for heading style
            }
            // Quotes
            else if line.hasPrefix("> ") {
                processedLine = String(line.dropFirst(2))
                // Mark for quote style
            }
            // Bullet lists
            else if line.hasPrefix("• ") || line.hasPrefix("- ") {
                processedLine = "• " + String(line.dropFirst(2))
            }
            
            processedText += processedLine + "\n"
        }
        
        result = AttributedString(processedText)
        result.foregroundColor = textColor
        
        return result
    }
    
    /// Apply inline formatting (bold, italic)
    static func applyInlineFormatting(to text: String) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(string: text)
        
        // Bold: **text**
        let boldPattern = "\\*\\*(.+?)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: boldPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let boldText = String(text[range])
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 16)
                    ]
                    mutableString.replaceCharacters(in: match.range, with: NSAttributedString(string: boldText, attributes: attrs))
                }
            }
        }
        
        // Italic: *text*
        let italicPattern = "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)"
        if let regex = try? NSRegularExpression(pattern: italicPattern, options: []) {
            let matches = regex.matches(in: mutableString.string, options: [], range: NSRange(location: 0, length: mutableString.length))
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: mutableString.string) {
                    let italicText = String(mutableString.string[range])
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.italicSystemFont(ofSize: 16)
                    ]
                    mutableString.replaceCharacters(in: match.range, with: NSAttributedString(string: italicText, attributes: attrs))
                }
            }
        }
        
        return mutableString
    }
}

// MARK: - Formatted Text View

/// Displays formatted journal content
struct FormattedTextView: View {
    let content: String
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseLines(), id: \.id) { line in
                lineView(for: line)
            }
        }
    }
    
    private func parseLines() -> [ParsedLine] {
        let lines = content.components(separatedBy: .newlines)
        return lines.enumerated().map { index, text in
            ParsedLine(id: index, text: text, style: detectStyle(for: text))
        }
    }
    
    private func detectStyle(for text: String) -> LineStyle {
        if text.hasPrefix("# ") {
            return .heading
        } else if text.hasPrefix("> ") {
            return .quote
        } else if text.hasPrefix("• ") || text.hasPrefix("- ") {
            return .bullet
        } else if let firstChar = text.first, firstChar.isNumber, text.contains(". ") {
            return .numbered
        }
        return .body
    }
    
    @ViewBuilder
    private func lineView(for line: ParsedLine) -> some View {
        switch line.style {
        case .heading:
            Text(line.text.dropFirst(2))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
            
        case .quote:
            HStack(alignment: .top, spacing: 8) {
                Rectangle()
                    .fill(themeManager.accentColor)
                    .frame(width: 3)
                
                Text(line.text.dropFirst(2))
                    .font(.body)
                    .italic()
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.vertical, 4)
            
        case .bullet:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundColor(themeManager.accentColor)
                Text(line.text.dropFirst(2))
                    .foregroundColor(themeManager.textColor)
            }
            
        case .numbered:
            HStack(alignment: .top, spacing: 8) {
                if let dotIndex = line.text.firstIndex(of: ".") {
                    Text(String(line.text[...dotIndex]))
                        .foregroundColor(themeManager.accentColor)
                    Text(String(line.text[line.text.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces))
                        .foregroundColor(themeManager.textColor)
                }
            }
            
        case .body:
            if !line.text.isEmpty {
                Text(line.text)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
            }
        }
    }
    
    struct ParsedLine: Identifiable {
        let id: Int
        let text: String
        let style: LineStyle
    }
    
    enum LineStyle {
        case body, heading, quote, bullet, numbered
    }
}

#Preview("Rich Text Editor") {
    RichTextEditor(
        text: .constant("This is some sample text"),
        attributedText: .constant(NSAttributedString())
    )
    .padding()
}

#Preview("Formatted Text View") {
    FormattedTextView(content: """
        # Morning Reflection
        
        Today I read from Psalm 23 and felt a deep sense of peace.
        
        > The Lord is my shepherd, I shall not want.
        
        Key takeaways:
        • God provides for all my needs
        • I can rest in His presence
        • He guides me on the right path
        
        1. First lesson learned
        2. Second lesson learned
        3. Third lesson learned
        """)
    .padding()
}




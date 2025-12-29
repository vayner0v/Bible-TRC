//
//  String+Extensions.swift
//  Bible v1
//
//  Advanced Bible Reader App
//

import Foundation
import UIKit

extension String {
    /// Trims whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if string is empty after trimming
    var isBlank: Bool {
        trimmed.isEmpty
    }
    
    /// Returns nil if string is blank
    var nilIfBlank: String? {
        isBlank ? nil : self
    }
    
    /// Capitalizes first letter only
    var capitalizedFirst: String {
        guard let first = first else { return self }
        return String(first).uppercased() + dropFirst()
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int, trailing: String = "…") -> String {
        if count > length {
            return String(prefix(length)) + trailing
        }
        return self
    }
    
    /// Removes HTML tags from string
    var strippingHTML: String {
        guard let data = data(using: .utf8) else { return self }
        
        guard let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) else { return self }
        
        return attributedString.string
    }
    
    /// Checks if string contains only digits
    var isNumeric: Bool {
        !isEmpty && allSatisfy { $0.isNumber }
    }
    
    /// Returns language display name for a language code
    var languageDisplayName: String {
        let locale = Locale(identifier: "en")
        return locale.localizedString(forLanguageCode: self) ?? self
    }
}

// MARK: - Localization

extension String {
    /// Returns localized string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns localized string with arguments
    func localized(_ arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

// MARK: - Search

extension String {
    /// Case-insensitive contains
    func containsIgnoringCase(_ other: String) -> Bool {
        range(of: other, options: .caseInsensitive) != nil
    }
    
    /// Returns ranges of all occurrences of substring
    func ranges(of substring: String, options: CompareOptions = .caseInsensitive) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var start = startIndex
        
        while start < endIndex,
              let range = self.range(of: substring, options: options, range: start..<endIndex) {
            ranges.append(range)
            start = range.upperBound
        }
        
        return ranges
    }
}


//
//  ReferenceParser.swift
//  Bible v1
//
//  TRC AI Bible Assistant - Enhanced Reference Parser
//

import Foundation

/// Enhanced parser for Bible references with validation and normalization
class ReferenceParser {
    static let shared = ReferenceParser()
    
    // MARK: - Book Name Mappings
    
    /// Maps various book name formats to standard OSIS IDs
    private let bookNameToOSIS: [String: String] = [
        // Old Testament
        "genesis": "GEN", "gen": "GEN", "ge": "GEN",
        "exodus": "EXO", "exod": "EXO", "ex": "EXO",
        "leviticus": "LEV", "lev": "LEV", "le": "LEV",
        "numbers": "NUM", "num": "NUM", "nu": "NUM",
        "deuteronomy": "DEU", "deut": "DEU", "de": "DEU", "dt": "DEU",
        "joshua": "JOS", "josh": "JOS", "jos": "JOS",
        "judges": "JDG", "judg": "JDG", "jdg": "JDG", "jg": "JDG",
        "ruth": "RUT", "ru": "RUT",
        "1 samuel": "1SA", "1samuel": "1SA", "1 sam": "1SA", "1sam": "1SA", "i samuel": "1SA", "i sam": "1SA",
        "2 samuel": "2SA", "2samuel": "2SA", "2 sam": "2SA", "2sam": "2SA", "ii samuel": "2SA", "ii sam": "2SA",
        "1 kings": "1KI", "1kings": "1KI", "1 kgs": "1KI", "1kgs": "1KI", "i kings": "1KI", "i kgs": "1KI",
        "2 kings": "2KI", "2kings": "2KI", "2 kgs": "2KI", "2kgs": "2KI", "ii kings": "2KI", "ii kgs": "2KI",
        "1 chronicles": "1CH", "1chronicles": "1CH", "1 chr": "1CH", "1chr": "1CH", "i chronicles": "1CH", "i chr": "1CH",
        "2 chronicles": "2CH", "2chronicles": "2CH", "2 chr": "2CH", "2chr": "2CH", "ii chronicles": "2CH", "ii chr": "2CH",
        "ezra": "EZR", "ezr": "EZR",
        "nehemiah": "NEH", "neh": "NEH", "ne": "NEH",
        "esther": "EST", "esth": "EST", "es": "EST",
        "job": "JOB", "jb": "JOB",
        "psalms": "PSA", "psalm": "PSA", "ps": "PSA", "psa": "PSA",
        "proverbs": "PRO", "prov": "PRO", "pr": "PRO",
        "ecclesiastes": "ECC", "eccl": "ECC", "eccles": "ECC", "ec": "ECC", "qoheleth": "ECC",
        "song of solomon": "SNG", "song of songs": "SNG", "song": "SNG", "sos": "SNG", "ss": "SNG", "canticles": "SNG",
        "isaiah": "ISA", "isa": "ISA", "is": "ISA",
        "jeremiah": "JER", "jer": "JER", "je": "JER",
        "lamentations": "LAM", "lam": "LAM", "la": "LAM",
        "ezekiel": "EZK", "ezek": "EZK", "eze": "EZK", "ez": "EZK",
        "daniel": "DAN", "dan": "DAN", "da": "DAN",
        "hosea": "HOS", "hos": "HOS", "ho": "HOS",
        "joel": "JOL", "joe": "JOL", "jl": "JOL",
        "amos": "AMO", "amo": "AMO", "am": "AMO",
        "obadiah": "OBA", "obad": "OBA", "ob": "OBA",
        "jonah": "JON", "jon": "JON", "jnh": "JON",
        "micah": "MIC", "mic": "MIC", "mi": "MIC",
        "nahum": "NAM", "nah": "NAM", "na": "NAM",
        "habakkuk": "HAB", "hab": "HAB", "hb": "HAB",
        "zephaniah": "ZEP", "zeph": "ZEP", "zep": "ZEP",
        "haggai": "HAG", "hag": "HAG", "hg": "HAG",
        "zechariah": "ZEC", "zech": "ZEC", "zec": "ZEC",
        "malachi": "MAL", "mal": "MAL", "ml": "MAL",
        
        // New Testament
        "matthew": "MAT", "matt": "MAT", "mat": "MAT", "mt": "MAT",
        "mark": "MRK", "mrk": "MRK", "mk": "MRK", "mar": "MRK",
        "luke": "LUK", "luk": "LUK", "lk": "LUK", "lu": "LUK",
        "john": "JHN", "jhn": "JHN", "jn": "JHN", "joh": "JHN",
        "acts": "ACT", "act": "ACT", "ac": "ACT", "acts of the apostles": "ACT",
        "romans": "ROM", "rom": "ROM", "ro": "ROM",
        "1 corinthians": "1CO", "1corinthians": "1CO", "1 cor": "1CO", "1cor": "1CO", "i corinthians": "1CO", "i cor": "1CO",
        "2 corinthians": "2CO", "2corinthians": "2CO", "2 cor": "2CO", "2cor": "2CO", "ii corinthians": "2CO", "ii cor": "2CO",
        "galatians": "GAL", "gal": "GAL", "ga": "GAL",
        "ephesians": "EPH", "eph": "EPH", "ep": "EPH",
        "philippians": "PHP", "phil": "PHP", "php": "PHP", "pp": "PHP",
        "colossians": "COL", "col": "COL", "co": "COL",
        "1 thessalonians": "1TH", "1thessalonians": "1TH", "1 thess": "1TH", "1thess": "1TH", "i thessalonians": "1TH", "i thess": "1TH",
        "2 thessalonians": "2TH", "2thessalonians": "2TH", "2 thess": "2TH", "2thess": "2TH", "ii thessalonians": "2TH", "ii thess": "2TH",
        "1 timothy": "1TI", "1timothy": "1TI", "1 tim": "1TI", "1tim": "1TI", "i timothy": "1TI", "i tim": "1TI",
        "2 timothy": "2TI", "2timothy": "2TI", "2 tim": "2TI", "2tim": "2TI", "ii timothy": "2TI", "ii tim": "2TI",
        "titus": "TIT", "tit": "TIT", "ti": "TIT",
        "philemon": "PHM", "phlm": "PHM", "phm": "PHM", "philem": "PHM",
        "hebrews": "HEB", "heb": "HEB", "he": "HEB",
        "james": "JAS", "jas": "JAS", "jm": "JAS", "jam": "JAS",
        "1 peter": "1PE", "1peter": "1PE", "1 pet": "1PE", "1pet": "1PE", "i peter": "1PE", "i pet": "1PE",
        "2 peter": "2PE", "2peter": "2PE", "2 pet": "2PE", "2pet": "2PE", "ii peter": "2PE", "ii pet": "2PE",
        "1 john": "1JN", "1john": "1JN", "1 jn": "1JN", "1jn": "1JN", "i john": "1JN", "i jn": "1JN",
        "2 john": "2JN", "2john": "2JN", "2 jn": "2JN", "2jn": "2JN", "ii john": "2JN", "ii jn": "2JN",
        "3 john": "3JN", "3john": "3JN", "3 jn": "3JN", "3jn": "3JN", "iii john": "3JN", "iii jn": "3JN",
        "jude": "JUD", "jud": "JUD", "jd": "JUD",
        "revelation": "REV", "rev": "REV", "re": "REV", "apocalypse": "REV"
    ]
    
    /// Maps OSIS IDs to canonical book names
    private let osisToDisplayName: [String: String] = [
        "GEN": "Genesis", "EXO": "Exodus", "LEV": "Leviticus", "NUM": "Numbers",
        "DEU": "Deuteronomy", "JOS": "Joshua", "JDG": "Judges", "RUT": "Ruth",
        "1SA": "1 Samuel", "2SA": "2 Samuel", "1KI": "1 Kings", "2KI": "2 Kings",
        "1CH": "1 Chronicles", "2CH": "2 Chronicles", "EZR": "Ezra", "NEH": "Nehemiah",
        "EST": "Esther", "JOB": "Job", "PSA": "Psalms", "PRO": "Proverbs",
        "ECC": "Ecclesiastes", "SNG": "Song of Solomon", "ISA": "Isaiah", "JER": "Jeremiah",
        "LAM": "Lamentations", "EZK": "Ezekiel", "DAN": "Daniel", "HOS": "Hosea",
        "JOL": "Joel", "AMO": "Amos", "OBA": "Obadiah", "JON": "Jonah",
        "MIC": "Micah", "NAM": "Nahum", "HAB": "Habakkuk", "ZEP": "Zephaniah",
        "HAG": "Haggai", "ZEC": "Zechariah", "MAL": "Malachi",
        "MAT": "Matthew", "MRK": "Mark", "LUK": "Luke", "JHN": "John",
        "ACT": "Acts", "ROM": "Romans", "1CO": "1 Corinthians", "2CO": "2 Corinthians",
        "GAL": "Galatians", "EPH": "Ephesians", "PHP": "Philippians", "COL": "Colossians",
        "1TH": "1 Thessalonians", "2TH": "2 Thessalonians", "1TI": "1 Timothy", "2TI": "2 Timothy",
        "TIT": "Titus", "PHM": "Philemon", "HEB": "Hebrews", "JAS": "James",
        "1PE": "1 Peter", "2PE": "2 Peter", "1JN": "1 John", "2JN": "2 John",
        "3JN": "3 John", "JUD": "Jude", "REV": "Revelation"
    ]
    
    // MARK: - Parsing
    
    /// Parse a reference string into a structured reference
    /// Supports formats: "John 3:16", "1 Corinthians 13:4-7", "Rom 8", "Genesis 1:1–3",
    /// "see John 3:16", "John chapter 3", "cf. Romans 8:28"
    func parse(_ input: String) -> EnhancedParsedReference? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Normalize dashes and spaces
        var normalized = trimmed
            .replacingOccurrences(of: "–", with: "-") // en-dash
            .replacingOccurrences(of: "—", with: "-") // em-dash
            .replacingOccurrences(of: "  ", with: " ")
        
        // Remove common prefixes like "see", "cf.", "compare"
        let prefixPatterns = [
            #"^(?:see|cf\.?|compare|read|also)\s+"#
        ]
        for prefixPattern in prefixPatterns {
            if let regex = try? NSRegularExpression(pattern: prefixPattern, options: .caseInsensitive) {
                normalized = regex.stringByReplacingMatches(
                    in: normalized,
                    range: NSRange(normalized.startIndex..., in: normalized),
                    withTemplate: ""
                )
            }
        }
        
        // Try multiple parsing patterns in order of specificity
        if let result = parseStandardReference(normalized, rawInput: input) {
            return result
        }
        
        if let result = parseChapterOnlyReference(normalized, rawInput: input) {
            return result
        }
        
        return nil
    }
    
    /// Parse standard format: "John 3:16", "1 John 3:16", "Genesis 1:1-5", "Psalm 23", "Rom 8"
    private func parseStandardReference(_ normalized: String, rawInput: String) -> EnhancedParsedReference? {
        // Pattern for book chapter:verse(-verse) with optional period-based abbreviations
        let pattern = #"^(\d?\s?[IViv]{0,3}\s?[A-Za-z]+\.?(?:\s+[A-Za-z]+\.?)?)\s+(\d+)(?:\s*[:\.]\s*(\d+)(?:\s*[-–—,]\s*(\d+))?)?$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) else {
            return nil
        }
        
        return extractReference(from: match, in: normalized, rawInput: rawInput)
    }
    
    /// Parse "chapter" keyword format: "John chapter 3", "Genesis chapter 1"
    private func parseChapterOnlyReference(_ normalized: String, rawInput: String) -> EnhancedParsedReference? {
        let pattern = #"^(\d?\s?[IViv]{0,3}\s?[A-Za-z]+\.?(?:\s+[A-Za-z]+\.?)?)\s+chapter\s+(\d+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) else {
            return nil
        }
        
        // Extract book name
        guard let bookRange = Range(match.range(at: 1), in: normalized) else { return nil }
        let rawBookName = String(normalized[bookRange])
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
        
        guard let osisId = normalizeBookName(rawBookName),
              let displayName = osisToDisplayName[osisId] else {
            return nil
        }
        
        // Extract chapter
        guard let chapterRange = Range(match.range(at: 2), in: normalized),
              let chapter = Int(normalized[chapterRange]) else { return nil }
        
        return EnhancedParsedReference(
            rawInput: rawInput,
            osisBookId: osisId,
            bookDisplayName: displayName,
            chapter: chapter,
            verseStart: nil,
            verseEnd: nil
        )
    }
    
    /// Extract reference components from a regex match
    private func extractReference(from match: NSTextCheckingResult, in normalized: String, rawInput: String) -> EnhancedParsedReference? {
        // Extract book name
        guard let bookRange = Range(match.range(at: 1), in: normalized) else { return nil }
        let rawBookName = String(normalized[bookRange])
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
        
        // Normalize and validate book name
        guard let osisId = normalizeBookName(rawBookName),
              let displayName = osisToDisplayName[osisId] else {
            return nil
        }
        
        // Extract chapter
        guard let chapterRange = Range(match.range(at: 2), in: normalized),
              let chapter = Int(normalized[chapterRange]) else { return nil }
        
        // Extract verse start (optional)
        var verseStart: Int? = nil
        if match.range(at: 3).location != NSNotFound,
           let verseRange = Range(match.range(at: 3), in: normalized) {
            verseStart = Int(normalized[verseRange])
        }
        
        // Extract verse end (optional)
        var verseEnd: Int? = nil
        if match.range(at: 4).location != NSNotFound,
           let endRange = Range(match.range(at: 4), in: normalized) {
            verseEnd = Int(normalized[endRange])
        }
        
        return EnhancedParsedReference(
            rawInput: rawInput,
            osisBookId: osisId,
            bookDisplayName: displayName,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }
    
    /// Parse multiple references from text (for extracting from user messages)
    func parseAll(from text: String) -> [EnhancedParsedReference] {
        var results: [EnhancedParsedReference] = []
        
        // Multiple patterns to find potential references in text
        let patterns = [
            // Standard format with optional verse: John 3:16, Rom 8:28, 1 Cor 13:4-7
            #"\b(\d?\s?[IViv]{0,3}\s?[A-Za-z]+\.?(?:\s+[A-Za-z]+\.?)?)\s+(\d+)(?:\s*[:\.]\s*(\d+)(?:\s*[-–—,]\s*(\d+))?)?"#,
            // With "see" or "cf." prefix: (see John 3:16), cf. Romans 8
            #"(?:see|cf\.?)\s+(\d?\s?[IViv]{0,3}\s?[A-Za-z]+\.?(?:\s+[A-Za-z]+\.?)?)\s+(\d+)(?:\s*[:\.]\s*(\d+)(?:\s*[-–—]\s*(\d+))?)?"#,
            // Chapter format: John chapter 3
            #"(\d?\s?[IViv]{0,3}\s?[A-Za-z]+\.?(?:\s+[A-Za-z]+\.?)?)\s+chapter\s+(\d+)"#,
            // Parenthetical format: (John 3:16)
            #"\((\d?\s?[IViv]{0,3}\s?[A-Za-z]+\.?(?:\s+[A-Za-z]+\.?)?)\s+(\d+)(?:\s*[:\.]\s*(\d+)(?:\s*[-–—]\s*(\d+))?)?\)"#
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let potentialRef = String(text[range])
                        .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                    if let parsed = parse(potentialRef) {
                        // Avoid duplicates
                        if !results.contains(where: { $0.canonicalReference == parsed.canonicalReference }) {
                            results.append(parsed)
                        }
                    }
                }
            }
        }
        
        return results
    }
    
    /// Normalize a book name to OSIS ID
    func normalizeBookName(_ input: String) -> String? {
        let normalized = input.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
        
        // Direct lookup
        if let osisId = bookNameToOSIS[normalized] {
            return osisId
        }
        
        // Try without spaces
        let noSpaces = normalized.replacingOccurrences(of: " ", with: "")
        if let osisId = bookNameToOSIS[noSpaces] {
            return osisId
        }
        
        // Fuzzy match - find best match
        for (key, value) in bookNameToOSIS {
            if key.hasPrefix(normalized) || normalized.hasPrefix(key) {
                return value
            }
        }
        
        return nil
    }
    
    /// Get display name for OSIS ID
    func getDisplayName(for osisId: String) -> String? {
        osisToDisplayName[osisId.uppercased()]
    }
    
    /// Chapter counts for each book (for validation)
    private let chapterCounts: [String: Int] = [
        // Old Testament
        "GEN": 50, "EXO": 40, "LEV": 27, "NUM": 36, "DEU": 34,
        "JOS": 24, "JDG": 21, "RUT": 4, "1SA": 31, "2SA": 24,
        "1KI": 22, "2KI": 25, "1CH": 29, "2CH": 36, "EZR": 10,
        "NEH": 13, "EST": 10, "JOB": 42, "PSA": 150, "PRO": 31,
        "ECC": 12, "SNG": 8, "ISA": 66, "JER": 52, "LAM": 5,
        "EZK": 48, "DAN": 12, "HOS": 14, "JOL": 3, "AMO": 9,
        "OBA": 1, "JON": 4, "MIC": 7, "NAM": 3, "HAB": 3,
        "ZEP": 3, "HAG": 2, "ZEC": 14, "MAL": 4,
        // New Testament
        "MAT": 28, "MRK": 16, "LUK": 24, "JHN": 21, "ACT": 28,
        "ROM": 16, "1CO": 16, "2CO": 13, "GAL": 6, "EPH": 6,
        "PHP": 4, "COL": 4, "1TH": 5, "2TH": 3, "1TI": 6,
        "2TI": 4, "TIT": 3, "PHM": 1, "HEB": 13, "JAS": 5,
        "1PE": 5, "2PE": 3, "1JN": 5, "2JN": 1, "3JN": 1,
        "JUD": 1, "REV": 22
    ]
    
    /// Validate a reference against known book/chapter/verse limits
    func validate(_ reference: EnhancedParsedReference) -> ReferenceValidationResult {
        // Check if book exists
        guard osisToDisplayName[reference.osisBookId] != nil else {
            return .invalid(reason: "Unknown book")
        }
        
        // Validate chapter against actual book limits
        if let maxChapters = chapterCounts[reference.osisBookId] {
            if reference.chapter < 1 || reference.chapter > maxChapters {
                return .invalid(reason: "Invalid chapter number. \(osisToDisplayName[reference.osisBookId] ?? reference.osisBookId) has \(maxChapters) chapters.")
            }
        } else if reference.chapter < 1 || reference.chapter > 150 {
            return .invalid(reason: "Invalid chapter number")
        }
        
        // Validate verse range
        if let start = reference.verseStart {
            // Most chapters don't exceed 176 verses (Psalm 119)
            if start < 1 || start > 180 {
                return .invalid(reason: "Invalid verse number")
            }
        }
        
        if let start = reference.verseStart, let end = reference.verseEnd {
            if end < start {
                return .invalid(reason: "End verse cannot be before start verse")
            }
            if end > 180 {
                return .invalid(reason: "Invalid verse range")
            }
        }
        
        return .valid
    }
    
    /// Validate a raw citation string
    func validateCitation(_ reference: String) -> ReferenceValidationResult {
        guard let parsed = parse(reference) else {
            return .invalid(reason: "Could not parse reference")
        }
        return validate(parsed)
    }
    
    /// Pre-verify citations and filter out likely hallucinations
    func verifyAndFilterCitations(_ references: [String]) -> [String] {
        return references.filter { ref in
            let result = validateCitation(ref)
            if case .invalid(let reason) = result {
                print("ReferenceParser: Filtering out invalid citation '\(ref)': \(reason)")
                return false
            }
            return true
        }
    }
}

// MARK: - Enhanced Parsed Reference

/// A fully parsed and normalized Bible reference
struct EnhancedParsedReference: Identifiable, Hashable {
    let id = UUID()
    let rawInput: String
    let osisBookId: String
    let bookDisplayName: String
    let chapter: Int
    let verseStart: Int?
    let verseEnd: Int?
    
    /// Whether this references a specific verse or just a chapter
    var isChapterOnly: Bool {
        verseStart == nil
    }
    
    /// Whether this is a verse range
    var isRange: Bool {
        if let start = verseStart, let end = verseEnd {
            return end > start
        }
        return false
    }
    
    /// Canonical reference string (e.g., "John 3:16" or "1 Corinthians 13:4-7")
    var canonicalReference: String {
        var ref = "\(bookDisplayName) \(chapter)"
        if let start = verseStart {
            ref += ":\(start)"
            if let end = verseEnd, end > start {
                ref += "-\(end)"
            }
        }
        return ref
    }
    
    /// Convert to AICitation
    func toCitation(translationId: String) -> AICitation {
        AICitation(
            reference: canonicalReference,
            translationId: translationId,
            bookId: osisBookId,
            bookName: bookDisplayName,
            chapter: chapter,
            verseStart: verseStart,
            verseEnd: verseEnd
        )
    }
}

// MARK: - Validation Result

enum ReferenceValidationResult {
    case valid
    case invalid(reason: String)
    
    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}



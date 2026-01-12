//
//  SermonNote.swift
//  Bible v1
//
//  Spiritual Hub - Sermon Notes Model
//

import Foundation

/// A sermon note entry
struct SermonNote: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var speaker: String
    var church: String
    var mainScripture: String
    var scriptureText: String?
    var mainPoints: [String]
    var personalNotes: String
    var applicationPoints: [String]
    var questions: [String]
    var prayerResponse: String?
    var tags: [String]
    let createdAt: Date
    var modifiedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String = "",
        date: Date = Date(),
        speaker: String = "",
        church: String = "",
        mainScripture: String = "",
        scriptureText: String? = nil,
        mainPoints: [String] = [""],
        personalNotes: String = "",
        applicationPoints: [String] = [""],
        questions: [String] = [],
        prayerResponse: String? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.speaker = speaker
        self.church = church
        self.mainScripture = mainScripture
        self.scriptureText = scriptureText
        self.mainPoints = mainPoints
        self.personalNotes = personalNotes
        self.applicationPoints = applicationPoints
        self.questions = questions
        self.prayerResponse = prayerResponse
        self.tags = tags
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// Add a main point
    mutating func addMainPoint(_ point: String) {
        if !point.isEmpty {
            mainPoints.append(point)
            modifiedAt = Date()
        }
    }
    
    /// Add an application point
    mutating func addApplicationPoint(_ point: String) {
        if !point.isEmpty {
            applicationPoints.append(point)
            modifiedAt = Date()
        }
    }
    
    /// Add a question
    mutating func addQuestion(_ question: String) {
        if !question.isEmpty {
            questions.append(question)
            modifiedAt = Date()
        }
    }
    
    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Check if note has meaningful content
    var hasContent: Bool {
        !title.isEmpty || !mainScripture.isEmpty || !personalNotes.isEmpty ||
        mainPoints.contains { !$0.isEmpty }
    }
    
    /// Word count for notes
    var wordCount: Int {
        let text = personalNotes + mainPoints.joined() + applicationPoints.joined()
        return text.split(separator: " ").count
    }
}

/// Sermon note template for quick start
struct SermonNoteTemplate: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let sections: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        sections: [String]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sections = sections
    }
    
    static let standard = SermonNoteTemplate(
        name: "Standard",
        description: "Classic sermon note format",
        sections: ["Title & Scripture", "Main Points", "Personal Notes", "Application"]
    )
    
    static let detailed = SermonNoteTemplate(
        name: "Detailed",
        description: "Comprehensive notes with questions",
        sections: ["Title & Scripture", "Speaker & Date", "Main Points", "Personal Notes", "Questions", "Application", "Prayer Response"]
    )
    
    static let simple = SermonNoteTemplate(
        name: "Simple",
        description: "Quick capture essentials",
        sections: ["Title", "Key Verse", "One Main Takeaway", "One Action Step"]
    )
    
    static let allTemplates: [SermonNoteTemplate] = [standard, detailed, simple]
}

/// Weekly sermon summary
struct WeeklySermonSummary: Identifiable {
    let id: UUID
    let weekStartDate: Date
    let notes: [SermonNote]
    
    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        notes: [SermonNote]
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.notes = notes
    }
    
    var notesCount: Int { notes.count }
    
    var allScriptures: [String] {
        notes.compactMap { $0.mainScripture.isEmpty ? nil : $0.mainScripture }
    }
    
    var allApplicationPoints: [String] {
        notes.flatMap { $0.applicationPoints.filter { !$0.isEmpty } }
    }
}









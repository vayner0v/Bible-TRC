//
//  MemorizeView.swift
//  Bible v1
//
//  Spiritual Hub - Verse Memorization Practice
//

import SwiftUI

struct MemorizeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storageService = HubStorageService.shared
    
    let verseReference: String
    let verseText: String
    
    @State private var session: MemorizationSession?
    @State private var mode: MemorizeMode = .read
    @State private var userInput = ""
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var hiddenWordIndices: Set<Int> = []
    @State private var revealedIndices: Set<Int> = []
    @State private var difficulty: Double = 0.3 // Start with 30% hidden
    
    enum MemorizeMode {
        case read
        case fillBlanks
        case typeFromMemory
        case flashcard
    }
    
    var words: [String] {
        verseText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Progress indicator
                if let session = session {
                    ProgressSection(session: session)
                }
                
                // Mode selector
                ModeSelectorView(selectedMode: $mode) {
                    resetPractice()
                }
                
                // Content based on mode
                Group {
                    switch mode {
                    case .read:
                        ReadModeView(verseText: verseText, verseReference: verseReference)
                    case .fillBlanks:
                        FillBlanksView(
                            words: words,
                            hiddenIndices: hiddenWordIndices,
                            revealedIndices: $revealedIndices,
                            verseReference: verseReference
                        )
                    case .typeFromMemory:
                        TypeFromMemoryView(
                            verseText: verseText,
                            verseReference: verseReference,
                            userInput: $userInput,
                            showResult: $showResult,
                            isCorrect: $isCorrect
                        )
                    case .flashcard:
                        FlashcardView(
                            verseText: verseText,
                            verseReference: verseReference
                        )
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Action buttons
                actionButtons
            }
            .padding()
            .navigationTitle("Memorize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                setupSession()
            }
        }
    }
    
    private func setupSession() {
        if let existing = storageService.getMemorizationSession(for: verseReference) {
            session = existing
        } else {
            session = storageService.startMemorization(verseReference: verseReference, verseText: verseText)
        }
        generateHiddenWords()
    }
    
    private func generateHiddenWords() {
        let numToHide = Int(Double(words.count) * difficulty)
        var indices = Set<Int>()
        while indices.count < numToHide {
            indices.insert(Int.random(in: 0..<words.count))
        }
        hiddenWordIndices = indices
        revealedIndices = []
    }
    
    private func resetPractice() {
        userInput = ""
        showResult = false
        isCorrect = false
        generateHiddenWords()
    }
    
    private func recordAttempt(correct: Bool) {
        guard let session = session else { return }
        storageService.recordMemorizationAttempt(sessionId: session.id, correct: correct)
        self.session = storageService.getMemorizationSession(for: verseReference)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            if mode == .fillBlanks {
                Button {
                    revealedIndices = hiddenWordIndices
                } label: {
                    Label("Reveal All", systemImage: "eye")
                }
                .buttonStyle(.bordered)
                .disabled(revealedIndices == hiddenWordIndices)
                
                Button {
                    // Increase difficulty
                    difficulty = min(0.8, difficulty + 0.1)
                    generateHiddenWords()
                } label: {
                    Label("Harder", systemImage: "arrow.up")
                }
                .buttonStyle(.bordered)
            } else if mode == .typeFromMemory && !showResult {
                Button {
                    checkAnswer()
                } label: {
                    Label("Check", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(userInput.isEmpty)
            } else if mode == .typeFromMemory && showResult {
                Button {
                    resetPractice()
                } label: {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func checkAnswer() {
        let normalizedInput = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedVerse = verseText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Calculate similarity
        let similarity = calculateSimilarity(normalizedInput, normalizedVerse)
        isCorrect = similarity >= 0.85 // 85% match required
        showResult = true
        recordAttempt(correct: isCorrect)
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = Set(str1.components(separatedBy: .whitespaces).filter { !$0.isEmpty })
        let words2 = Set(str2.components(separatedBy: .whitespaces).filter { !$0.isEmpty })
        
        guard !words2.isEmpty else { return 0 }
        
        let intersection = words1.intersection(words2)
        return Double(intersection.count) / Double(words2.count)
    }
}

// MARK: - Progress Section

struct ProgressSection: View {
    let session: MemorizationSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.attempts) attempts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(session.accuracy * 100))% accuracy")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            if session.mastered {
                Label("Mastered!", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            } else {
                ProgressView(value: session.accuracy)
                    .frame(width: 100)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Mode Selector

struct ModeSelectorView: View {
    @Binding var selectedMode: MemorizeView.MemorizeMode
    let onModeChange: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ModeButton(title: "Read", icon: "book", isSelected: selectedMode == .read) {
                    selectedMode = .read
                    onModeChange()
                }
                ModeButton(title: "Fill Blanks", icon: "textformat", isSelected: selectedMode == .fillBlanks) {
                    selectedMode = .fillBlanks
                    onModeChange()
                }
                ModeButton(title: "Type", icon: "keyboard", isSelected: selectedMode == .typeFromMemory) {
                    selectedMode = .typeFromMemory
                    onModeChange()
                }
                ModeButton(title: "Flashcard", icon: "rectangle.on.rectangle.angled", isSelected: selectedMode == .flashcard) {
                    selectedMode = .flashcard
                    onModeChange()
                }
            }
        }
    }
}

struct ModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Read Mode

struct ReadModeView: View {
    let verseText: String
    let verseReference: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Read and absorb the verse")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\"\(verseText)\"")
                .font(.title3)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            
            Text("— \(verseReference)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Fill Blanks Mode

struct FillBlanksView: View {
    let words: [String]
    let hiddenIndices: Set<Int>
    @Binding var revealedIndices: Set<Int>
    let verseReference: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tap the blanks to reveal words")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 6) {
                ForEach(words.indices, id: \.self) { index in
                    if hiddenIndices.contains(index) && !revealedIndices.contains(index) {
                        Button {
                            revealedIndices.insert(index)
                        } label: {
                            Text(String(repeating: "_", count: max(4, words[index].count)))
                                .font(.body)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    } else {
                        Text(words[index])
                            .font(.body)
                            .foregroundStyle(hiddenIndices.contains(index) ? .green : .primary)
                    }
                }
            }
            
            Text("— \(verseReference)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Type From Memory Mode

struct TypeFromMemoryView: View {
    let verseText: String
    let verseReference: String
    @Binding var userInput: String
    @Binding var showResult: Bool
    @Binding var isCorrect: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(verseReference)
                .font(.headline)
            
            if showResult {
                // Show result
                VStack(spacing: 16) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(isCorrect ? .green : .red)
                    
                    Text(isCorrect ? "Great job!" : "Keep practicing!")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if !isCorrect {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Correct verse:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(verseText)
                                .font(.body)
                                .italic()
                        }
                        .padding()
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                // Input area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type the verse from memory:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $userInput)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Flashcard Mode

struct FlashcardView: View {
    let verseText: String
    let verseReference: String
    @State private var showAnswer = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tap to flip")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ZStack {
                // Front - Reference
                VStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text(verseReference)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("What does this verse say?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(showAnswer ? 0 : 1)
                
                // Back - Verse
                Text("\"\(verseText)\"")
                    .font(.body)
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showAnswer ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                withAnimation(.spring()) {
                    showAnswer.toggle()
                }
            }
            
            HStack(spacing: 16) {
                Button {
                    showAnswer = false
                } label: {
                    Label("Show Question", systemImage: "arrow.uturn.left")
                }
                .buttonStyle(.bordered)
                .opacity(showAnswer ? 1 : 0.5)
                
                Button {
                    showAnswer = true
                } label: {
                    Label("Show Answer", systemImage: "arrow.uturn.right")
                }
                .buttonStyle(.bordered)
                .opacity(showAnswer ? 0.5 : 1)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MemorizeView(
        verseReference: "John 3:16",
        verseText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."
    )
}









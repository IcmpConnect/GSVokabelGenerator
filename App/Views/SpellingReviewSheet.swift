import SwiftUI
import AppKit

public struct SpellingReviewSheet: View {
    @Binding public var unit: VocabularyUnit
    public var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var ignoredWords: Set<String> = []

    public init(unit: Binding<VocabularyUnit>, onSave: @escaping () -> Void) {
        self._unit = unit
        self.onSave = onSave
    }

    private var spellingMap: [UUID: PairSpellingStatus] {
        return VocabularySpellChecker.shared.checkUnit(unit)
    }

    private var pairsWithIssues: [(VocabularyPair, PairSpellingStatus)] {
        return unit.pairs.compactMap { pair in
            if let status = spellingMap[pair.id], status.hasIssues {
                // Filtere lokal ignorierte Wörter heraus
                let filteredEng = status.englishIssues.filter { !ignoredWords.contains($0.word.lowercased()) }
                let filteredGer = status.germanIssues.filter { !ignoredWords.contains($0.word.lowercased()) }
                if !filteredEng.isEmpty || !filteredGer.isEmpty {
                    var newStatus = status
                    newStatus.englishIssues = filteredEng
                    newStatus.germanIssues = filteredGer
                    return (pair, newStatus)
                }
            }
            return nil
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info-Banner
                HStack(spacing: 12) {
                    Image(systemName: pairsWithIssues.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(pairsWithIssues.isEmpty ? .green : .orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pairsWithIssues.isEmpty ? "Keine Rechtschreibfehler gefunden!" : "\(pairsWithIssues.count) Vokabel(n) mit Hinweisen")
                            .font(.headline)
                        Text(pairsWithIssues.isEmpty ? "Alle englischen und deutschen Einträge entsprechen den Wörterbüchern." : "Prüfe die Schreibweise oder gleiche sie direkt mit Online-Wörterbüchern ab.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if !pairsWithIssues.isEmpty {
                        Button("Alle ersten Vorschläge anwenden") {
                            applyAllFirstSuggestions()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                if pairsWithIssues.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.green)
                        Text("Perfekt! Alle Wörter sind fehlerfrei.")
                            .font(.title2)
                        Text("Sowohl die englischen als auch die deutschen Schreibweisen wurden geprüft.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(pairsWithIssues, id: \.0.id) { pair, status in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pair.english)
                                            .font(.headline)
                                        Text(pair.german)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                // Englische Hinweise
                                ForEach(status.englishIssues) { issue in
                                    issueRow(issue: issue, pair: pair, isEnglish: true)
                                }

                                // Deutsche Hinweise
                                ForEach(status.germanIssues) { issue in
                                    issueRow(issue: issue, pair: pair, isEnglish: false)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.inset)
                }

                Divider()

                HStack {
                    Spacer()
                    Button("Schließen") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
            }
            .navigationTitle("Rechtschreibprüfung • Unit \(unit.cleanUnitNumber): \(unit.title)")
            .frame(minWidth: 700, minHeight: 520)
        }
    }

    @ViewBuilder
    private func issueRow(issue: SpellingIssue, pair: VocabularyPair, isEnglish: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Label("\(issue.language.displayName): '\(issue.word)' unbekannt / fraglich", systemImage: "text.badge.xmark")
                .font(.callout.bold())
                .foregroundColor(.orange)

            Spacer()

            if !issue.suggestions.isEmpty {
                Menu {
                    ForEach(issue.suggestions, id: \.self) { suggestion in
                        Button("Ersetzen durch '\(suggestion)'") {
                            applySuggestion(suggestion, for: issue, in: pair, isEnglish: isEnglish)
                        }
                    }
                } label: {
                    Text("Vorschlag: '\(issue.suggestions[0])'")
                }
                .buttonStyle(.bordered)
            }

            Menu {
                if isEnglish {
                    Button("In PONS nachschlagen") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: issue.word))
                    }
                    Button("In LEO nachschlagen") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.leoURL(for: issue.word))
                    }
                    Button("Cambridge Dictionary") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.cambridgeURL(for: issue.word))
                    }
                    Button("Wiktionary (Englisch)") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.wiktionaryURL(for: issue.word, language: .english))
                    }
                } else {
                    Button("In PONS nachschlagen") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: issue.word))
                    }
                    Button("In LEO nachschlagen") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.leoURL(for: issue.word))
                    }
                    Button("Im Duden nachschlagen") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.dudenURL(for: issue.word))
                    }
                    Button("Wiktionary (Deutsch)") {
                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.wiktionaryURL(for: issue.word, language: .german))
                    }
                }
            } label: {
                Label("Wörterbuch", systemImage: "book.pages")
            }
            .buttonStyle(.bordered)

            Button(action: {
                ignoredWords.insert(issue.word.lowercased())
                VocabularySpellChecker.shared.addIgnoredWord(issue.word)
            }) {
                Image(systemName: "checkmark")
                    .help("Dieses Wort ignorieren (als richtig ansehen)")
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(6)
    }

    private func applySuggestion(_ suggestion: String, for issue: SpellingIssue, in pair: VocabularyPair, isEnglish: Bool) {
        guard let index = unit.pairs.firstIndex(where: { $0.id == pair.id }) else { return }
        if isEnglish {
            let updated = VocabularySpellChecker.shared.replaceWord(
                in: unit.pairs[index].english,
                wordToReplace: issue.word,
                with: suggestion
            )
            unit.pairs[index].english = updated
        } else {
            let updated = VocabularySpellChecker.shared.replaceWord(
                in: unit.pairs[index].german,
                wordToReplace: issue.word,
                with: suggestion
            )
            unit.pairs[index].german = updated
        }
        onSave()
    }

    private func applyAllFirstSuggestions() {
        for (pair, status) in pairsWithIssues {
            guard let index = unit.pairs.firstIndex(where: { $0.id == pair.id }) else { continue }
            for issue in status.englishIssues {
                if let first = issue.suggestions.first {
                    unit.pairs[index].english = VocabularySpellChecker.shared.replaceWord(
                        in: unit.pairs[index].english,
                        wordToReplace: issue.word,
                        with: first
                    )
                }
            }
            for issue in status.germanIssues {
                if let first = issue.suggestions.first {
                    unit.pairs[index].german = VocabularySpellChecker.shared.replaceWord(
                        in: unit.pairs[index].german,
                        wordToReplace: issue.word,
                        with: first
                    )
                }
            }
        }
        onSave()
    }
}

import Foundation
import AppKit

public enum SpellingLanguage: String, CaseIterable, Identifiable {
    case english = "en_GB"
    case german = "de_DE"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .english: return "Englisch"
        case .german: return "Deutsch"
        }
    }
}

public struct SpellingIssue: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let word: String
    public let phrase: String
    public let range: NSRange
    public let suggestions: [String]
    public let language: SpellingLanguage

    public init(
        id: UUID = UUID(),
        word: String,
        phrase: String,
        range: NSRange,
        suggestions: [String],
        language: SpellingLanguage
    ) {
        self.id = id
        self.word = word
        self.phrase = phrase
        self.range = range
        self.suggestions = suggestions
        self.language = language
    }
}

public struct PairSpellingStatus: Equatable {
    public let pairId: UUID
    public var englishIssues: [SpellingIssue]
    public var germanIssues: [SpellingIssue]

    public var hasIssues: Bool {
        return !englishIssues.isEmpty || !germanIssues.isEmpty
    }

    public var totalIssueCount: Int {
        return englishIssues.count + germanIssues.count
    }

    public var allIssues: [SpellingIssue] {
        return englishIssues + germanIssues
    }
}

public final class VocabularySpellChecker {
    public static let shared = VocabularySpellChecker()

    private let spellChecker = NSSpellChecker.shared
    private var customIgnoredWords: Set<String> = [
        "budgie", "skaten", "schnorcheln", "part", "work", "homework"
    ]

    private init() {
        spellChecker.automaticallyIdentifiesLanguages = false
    }

    public func addIgnoredWord(_ word: String) {
        customIgnoredWords.insert(word.lowercased())
    }

    public func isIgnored(_ word: String) -> Bool {
        return customIgnoredWords.contains(word.lowercased())
    }

    /// Überprüft eine Vokabelzeile (z. B. "mouse / mice" oder "das Meerschweinchen") auf Rechtschreibfehler
    public func checkText(_ text: String, language: SpellingLanguage) -> [SpellingIssue] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var issues: [SpellingIssue] = []

        // Zerlege Ausdrücke mit Schrägstrichen oder Klammern in lesbare Segmente, behalte aber Wortgrenzen
        let segments = trimmed.components(separatedBy: CharacterSet(charactersIn: "/();,"))

        for segment in segments {
            let segTrimmed = segment.trimmingCharacters(in: .whitespaces)
            guard !segTrimmed.isEmpty else { return [] }
            let nsSegment = segTrimmed as NSString

            var offset = 0
            while offset < nsSegment.length {
                // Primäre Sprachprüfung
                let range = spellChecker.checkSpelling(
                    of: segTrimmed,
                    startingAt: offset,
                    language: language.rawValue,
                    wrap: false,
                    inSpellDocumentWithTag: 0,
                    wordCount: nil
                )

                if range.location == NSNotFound {
                    break
                }

                let misspelledWord = nsSegment.substring(with: range)
                    .trimmingCharacters(in: .punctuationCharacters)

                // Sonderzeichen, Zahlen oder ignorierte Wörter überspringen
                if !misspelledWord.isEmpty &&
                    !misspelledWord.allSatisfy({ $0.isNumber }) &&
                    !isIgnored(misspelledWord) {

                    // Bei Englisch: Auch en_US gegenprüfen, um gültige US/UK-Schreibweisen zu erlauben
                    var isMisspelledInBoth = true
                    if language == .english {
                        let usRange = spellChecker.checkSpelling(
                            of: segTrimmed,
                            startingAt: range.location,
                            language: "en_US",
                            wrap: false,
                            inSpellDocumentWithTag: 0,
                            wordCount: nil
                        )
                        if usRange.location != range.location {
                            isMisspelledInBoth = false
                        }
                    }

                    if isMisspelledInBoth {
                        var suggestions = spellChecker.guesses(
                            forWordRange: range,
                            in: segTrimmed,
                            language: language.rawValue,
                            inSpellDocumentWithTag: 0
                        ) ?? []

                        // Falls Englisch, ergänze ggf. Vorschläge aus en_US
                        if language == .english {
                            let usGuesses = spellChecker.guesses(
                                forWordRange: range,
                                in: segTrimmed,
                                language: "en_US",
                                inSpellDocumentWithTag: 0
                            ) ?? []
                            for guess in usGuesses where !suggestions.contains(guess) {
                                suggestions.append(guess)
                            }
                        }

                        issues.append(
                            SpellingIssue(
                                word: misspelledWord,
                                phrase: trimmed,
                                range: range,
                                suggestions: Array(suggestions.prefix(5)),
                                language: language
                            )
                        )
                    }
                }

                offset = range.location + max(range.length, 1)
            }
        }

        return issues
    }

    /// Überprüft ein einzelnes Vokabelpaar auf Englisch und Deutsch
    public func checkPair(_ pair: VocabularyPair) -> PairSpellingStatus {
        let engIssues = checkText(pair.english, language: .english)
        let gerIssues = checkText(pair.german, language: .german)
        return PairSpellingStatus(
            pairId: pair.id,
            englishIssues: engIssues,
            germanIssues: gerIssues
        )
    }

    /// Überprüft eine ganze Unit
    public func checkUnit(_ unit: VocabularyUnit) -> [UUID: PairSpellingStatus] {
        var result: [UUID: PairSpellingStatus] = [:]
        for pair in unit.pairs {
            result[pair.id] = checkPair(pair)
        }
        return result
    }

    /// Ersetzt ein fehlerhaftes Wort in einem String durch den Korrekturvorschlag
    public func replaceWord(in text: String, wordToReplace: String, with replacement: String) -> String {
        guard let range = text.range(of: wordToReplace) else { return text }
        return text.replacingCharacters(in: range, with: replacement)
    }
}

public struct OnlineDictionaryService {
    /// PONS Online-Wörterbuch (Englisch <-> Deutsch)
    public static func ponsURL(for query: String) -> URL? {
        let cleaned = cleanQuery(query)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        return URL(string: "https://de.pons.com/%C3%BCbersetzung/englisch-deutsch/\(encoded)")
    }

    /// LEO Online-Wörterbuch (Englisch <-> Deutsch)
    public static func leoURL(for query: String) -> URL? {
        let cleaned = cleanQuery(query)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleaned
        return URL(string: "https://dict.leo.org/englisch-deutsch/\(encoded)")
    }

    /// Cambridge Dictionary (Englisch)
    public static func cambridgeURL(for query: String) -> URL? {
        let cleaned = cleanQuery(query)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        return URL(string: "https://dictionary.cambridge.org/dictionary/english/\(encoded)")
    }

    /// Duden (Deutsch)
    public static func dudenURL(for query: String) -> URL? {
        let cleaned = cleanQuery(query)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        return URL(string: "https://www.duden.de/suchen/dudenonline/\(encoded)")
    }

    /// Wiktionary
    public static func wiktionaryURL(for query: String, language: SpellingLanguage) -> URL? {
        let cleaned = cleanQuery(query)
        let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cleaned
        let langPrefix = language == .english ? "en" : "de"
        return URL(string: "https://\(langPrefix).wiktionary.org/wiki/\(encoded)")
    }

    /// Öffnet die URL im Standard-Browser
    public static func openInBrowser(_ url: URL?) {
        guard let url = url else { return }
        NSWorkspace.shared.open(url)
    }

    private static func cleanQuery(_ query: String) -> String {
        return query
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: "(", with: " ")
            .replacingOccurrences(of: ")", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

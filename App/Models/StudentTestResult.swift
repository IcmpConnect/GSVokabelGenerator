import Foundation

public enum TestDirection: String, CaseIterable, Identifiable, Codable {
    case germanToEnglish = "Deutsch vorgegeben → Englisch eingeben"
    case englishToGerman = "Englisch vorgegeben → Deutsch eingeben"
    case alternating = "Abwechselnd (Gruppe A / gemischt)"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .germanToEnglish: return "DE → EN"
        case .englishToGerman: return "EN → DE"
        case .alternating: return "Gemischt"
        }
    }
}

public struct StudentAnswer: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var pairID: UUID
    public var prompt: String
    public var promptLanguage: String
    public var expectedAnswer: String
    public var studentAnswer: String
    public var isCorrect: Bool

    public init(
        id: UUID = UUID(),
        pairID: UUID,
        prompt: String,
        promptLanguage: String,
        expectedAnswer: String,
        studentAnswer: String,
        isCorrect: Bool
    ) {
        self.id = id
        self.pairID = pairID
        self.prompt = prompt
        self.promptLanguage = promptLanguage
        self.expectedAnswer = expectedAnswer
        self.studentAnswer = studentAnswer
        self.isCorrect = isCorrect
    }
}

public struct StudentTestResult: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var studentName: String
    public var submissionDate: Date
    public var score: Int
    public var maxScore: Int
    public var percentage: Double
    public var feedbackLevel: Int
    public var feedbackText: String
    public var answers: [StudentAnswer]

    public init(
        id: UUID = UUID(),
        studentName: String,
        submissionDate: Date = Date(),
        score: Int,
        maxScore: Int,
        percentage: Double,
        feedbackLevel: Int,
        feedbackText: String,
        answers: [StudentAnswer]
    ) {
        self.id = id
        self.studentName = studentName
        self.submissionDate = submissionDate
        self.score = score
        self.maxScore = maxScore
        self.percentage = percentage
        self.feedbackLevel = feedbackLevel
        self.feedbackText = feedbackText
        self.answers = answers
    }

    public var formattedScore: String {
        return "\(score) / \(maxScore)"
    }

    public var formattedPercentage: String {
        return "\(Int(round(percentage))) %"
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: submissionDate)
    }

    public var levelIcon: String {
        switch feedbackLevel {
        case 4: return "🌻"
        case 3: return "🪴"
        case 2: return "🌿"
        default: return "🌱"
        }
    }

    public var levelName: String {
        switch feedbackLevel {
        case 4: return "Stufe 4: Blüte"
        case 3: return "Stufe 3: Pflanze"
        case 2: return "Stufe 2: Keimling"
        default: return "Stufe 1: Samen"
        }
    }

    public var incorrectAnswers: [StudentAnswer] {
        return answers.filter { !$0.isCorrect }
    }
}

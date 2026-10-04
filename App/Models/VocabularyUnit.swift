import Foundation

public struct VocabularyUnit: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var classNumber: Int
    public var unitNumber: String
    public var title: String
    public var deadlineDay: String
    public var pairs: [VocabularyPair]

    public var workEnglish: String
    public var workGerman: String
    public var homeworkEnglish: String
    public var homeworkGerman: String

    public init(
        id: UUID = UUID(),
        classNumber: Int = 3,
        unitNumber: String = "1",
        title: String = "pets and other animals",
        deadlineDay: String = "Freitag",
        pairs: [VocabularyPair] = [],
        workEnglish: String = "Write the German and English words in your vocabulary booklet.\nYou have time until Friday.\nMake sure you write the words correctly.",
        workGerman: String = "Schreibe die deutschen und englischen Wörter in dein Vokabelheft.\nDu hast bis Freitag Zeit.\nAchte darauf, die Wörter richtig abzuschreiben.",
        homeworkEnglish: String = "Write the German and English words in your vocabulary booklet.\nYou have time until Friday.\nMake sure you write the words correctly.",
        homeworkGerman: String = "Schreibe die deutschen und englischen Wörter in dein Vokabelheft.\nDu hast bis Freitag Zeit.\nAchte darauf, die Wörter richtig abzuschreiben."
    ) {
        self.id = id
        self.classNumber = classNumber
        self.unitNumber = unitNumber
        self.title = title
        self.deadlineDay = deadlineDay
        self.pairs = pairs
        self.workEnglish = workEnglish
        self.workGerman = workGerman
        self.homeworkEnglish = homeworkEnglish
        self.homeworkGerman = homeworkGerman
    }

    public init(
        id: UUID = UUID(),
        classNumber: Int = 3,
        unitNumber: Int,
        title: String = "pets and other animals",
        deadlineDay: String = "Freitag",
        pairs: [VocabularyPair] = [],
        workEnglish: String = "Write the German and English words in your vocabulary booklet.\nYou have time until Friday.\nMake sure you write the words correctly.",
        workGerman: String = "Schreibe die deutschen und englischen Wörter in dein Vokabelheft.\nDu hast bis Freitag Zeit.\nAchte darauf, die Wörter richtig abzuschreiben.",
        homeworkEnglish: String = "Write the German and English words in your vocabulary booklet.\nYou have time until Friday.\nMake sure you write the words correctly.",
        homeworkGerman: String = "Schreibe die deutschen und englischen Wörter in dein Vokabelheft.\nDu hast bis Freitag Zeit.\nAchte darauf, die Wörter richtig abzuschreiben."
    ) {
        self.init(
            id: id,
            classNumber: classNumber,
            unitNumber: String(unitNumber),
            title: title,
            deadlineDay: deadlineDay,
            pairs: pairs,
            workEnglish: workEnglish,
            workGerman: workGerman,
            homeworkEnglish: homeworkEnglish,
            homeworkGerman: homeworkGerman
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, classNumber, unitNumber, title, deadlineDay, pairs
        case workEnglish, workGerman, homeworkEnglish, homeworkGerman
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        classNumber = try container.decodeIfPresent(Int.self, forKey: .classNumber) ?? 3
        if let str = try? container.decode(String.self, forKey: .unitNumber) {
            unitNumber = str
        } else if let intVal = try? container.decode(Int.self, forKey: .unitNumber) {
            unitNumber = String(intVal)
        } else if let dblVal = try? container.decode(Double.self, forKey: .unitNumber) {
            unitNumber = String(format: "%g", dblVal)
        } else {
            unitNumber = "1"
        }
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        deadlineDay = try container.decodeIfPresent(String.self, forKey: .deadlineDay) ?? "Freitag"
        pairs = try container.decodeIfPresent([VocabularyPair].self, forKey: .pairs) ?? []
        workEnglish = try container.decodeIfPresent(String.self, forKey: .workEnglish) ?? ""
        workGerman = try container.decodeIfPresent(String.self, forKey: .workGerman) ?? ""
        homeworkEnglish = try container.decodeIfPresent(String.self, forKey: .homeworkEnglish) ?? ""
        homeworkGerman = try container.decodeIfPresent(String.self, forKey: .homeworkGerman) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(classNumber, forKey: .classNumber)
        try container.encode(unitNumber, forKey: .unitNumber)
        try container.encode(title, forKey: .title)
        try container.encode(deadlineDay, forKey: .deadlineDay)
        try container.encode(pairs, forKey: .pairs)
        try container.encode(workEnglish, forKey: .workEnglish)
        try container.encode(workGerman, forKey: .workGerman)
        try container.encode(homeworkEnglish, forKey: .homeworkEnglish)
        try container.encode(homeworkGerman, forKey: .homeworkGerman)
    }

    public var cleanUnitNumber: String {
        let trimmed = unitNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("unit") {
            let stripped = trimmed.dropFirst(4).trimmingCharacters(in: .whitespacesAndNewlines)
            return stripped.isEmpty ? "1" : stripped
        }
        return trimmed.isEmpty ? "1" : trimmed
    }

    public var headerTitle: String {
        return "Unit \(cleanUnitNumber): \(title)"
    }

    public var displayIdentifier: String {
        return "Class \(classNumber) Unit \(cleanUnitNumber) \(title)"
    }
}

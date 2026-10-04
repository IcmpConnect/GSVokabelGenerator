import Foundation

public struct VocabularyPair: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var english: String
    public var german: String

    public init(id: UUID = UUID(), english: String, german: String) {
        self.id = id
        self.english = english
        self.german = german
    }
}

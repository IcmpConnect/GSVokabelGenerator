import Foundation

public struct CSVImporter {
    public static func parse(string: String) -> [VocabularyPair] {
        let lines = string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return [] }

        // Trennzeichen ermitteln: Häufigkeit von ';' vs ',' vs '\t' in den ersten Zeilen prüfen
        let sample = lines.prefix(5).joined(separator: "\n")
        let delimiter: Character
        let semicolonCount = sample.filter { $0 == ";" }.count
        let tabCount = sample.filter { $0 == "\t" }.count
        let commaCount = sample.filter { $0 == "," }.count

        if semicolonCount >= commaCount && semicolonCount >= tabCount && semicolonCount > 0 {
            delimiter = ";"
        } else if tabCount > commaCount && tabCount > 0 {
            delimiter = "\t"
        } else {
            delimiter = ","
        }

        var results: [VocabularyPair] = []

        for (index, line) in lines.enumerated() {
            let cols = splitCSVLine(line, delimiter: delimiter)
            guard cols.count >= 2 else { continue }

            let english = cols[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let german = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)

            // Header-Erkennung in erster Zeile
            if index == 0 {
                let lowerEng = english.lowercased()
                let lowerGer = german.lowercased()
                if (lowerEng.contains("engl") || lowerEng.contains("word") || lowerEng.contains("front")) &&
                   (lowerGer.contains("deut") || lowerGer.contains("german") || lowerGer.contains("back")) {
                    continue
                }
            }

            if !english.isEmpty && !german.isEmpty {
                results.append(VocabularyPair(english: english, german: german))
            }
        }

        return results
    }

    public static func parse(url: URL) throws -> [VocabularyPair] {
        let data = try Data(contentsOf: url)
        // Versuche UTF-8, Fallback auf ISO-Latin-1 / Windows CP1252
        if let string = String(data: data, encoding: .utf8) {
            return parse(string: string)
        } else if let string = String(data: data, encoding: .windowsCP1252) {
            return parse(string: string)
        } else if let string = String(data: data, encoding: .isoLatin1) {
            return parse(string: string)
        } else {
            let string = String(decoding: data, as: UTF8.self)
            return parse(string: string)
        }
    }

    private static func splitCSVLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        var iterator = line.makeIterator()
        while let char = iterator.next() {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == delimiter && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }
}

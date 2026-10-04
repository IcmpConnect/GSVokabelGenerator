import Foundation
import Combine
import AppKit

@MainActor
public class UnitStore: ObservableObject {
    @Published public var units: [VocabularyUnit] = []
    @Published public var selectedUnitID: UUID?

    private let saveURL: URL

    public init(saveURL: URL? = nil) {
        if let customURL = saveURL {
            self.saveURL = customURL
        } else {
            let fileManager = FileManager.default
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appFolder = appSupport.appendingPathComponent("GSVokabelGenerator", isDirectory: true)

            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
            self.saveURL = appFolder.appendingPathComponent("units.json")
        }

        loadUnits()

        if units.isEmpty || (units.count == 1 && units.first?.title == "pets and other animals") || units.allSatisfy({ $0.pairs.isEmpty }) {
            self.units = DefaultUnits.allUnits
            saveUnits()
        }
        if selectedUnitID == nil {
            selectedUnitID = units.first?.id
        }
    }

    public var selectedUnit: VocabularyUnit? {
        get {
            guard let id = selectedUnitID else { return units.first }
            return units.first { $0.id == id }
        }
        set {
            guard let newValue = newValue,
                  let index = units.firstIndex(where: { $0.id == newValue.id }) else { return }
            units[index] = newValue
            saveUnits()
        }
    }

    public func addUnit(_ unit: VocabularyUnit) {
        units.append(unit)
        selectedUnitID = unit.id
        saveUnits()
    }

    public func updateUnit(_ unit: VocabularyUnit) {
        if let idx = units.firstIndex(where: { $0.id == unit.id }) {
            units[idx] = unit
            saveUnits()
        }
    }

    public func deleteUnit(id: UUID) {
        units.removeAll { $0.id == id }
        if selectedUnitID == id {
            selectedUnitID = units.first?.id
        }
        saveUnits()
    }

    public func moveUnits(from source: IndexSet, to destination: Int) {
        var newUnits = units
        var targetDestination = destination
        let itemsToMove = source.map { units[$0] }
        for index in source.reversed() {
            newUnits.remove(at: index)
            if index < destination {
                targetDestination -= 1
            }
        }
        targetDestination = max(0, min(targetDestination, newUnits.count))
        newUnits.insert(contentsOf: itemsToMove, at: targetDestination)
        self.units = newUnits
        saveUnits()
    }

    public func canMoveUp(id: UUID) -> Bool {
        guard let index = units.firstIndex(where: { $0.id == id }) else { return false }
        return index > 0
    }

    public func canMoveDown(id: UUID) -> Bool {
        guard let index = units.firstIndex(where: { $0.id == id }) else { return false }
        return index < units.count - 1
    }

    public func moveUnitUp(id: UUID) {
        guard let index = units.firstIndex(where: { $0.id == id }), index > 0 else { return }
        units.swapAt(index, index - 1)
        saveUnits()
    }

    public func moveUnitDown(id: UUID) {
        guard let index = units.firstIndex(where: { $0.id == id }), index < units.count - 1 else { return }
        units.swapAt(index, index + 1)
        saveUnits()
    }

    public func moveUnit(fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0, fromIndex < units.count,
              toIndex >= 0, toIndex < units.count,
              fromIndex != toIndex else { return }
        let unit = units.remove(at: fromIndex)
        units.insert(unit, at: toIndex)
        saveUnits()
    }

    public func sortByUnitNumber() {
        units.sort { 
            if $0.classNumber != $1.classNumber {
                return $0.classNumber < $1.classNumber
            }
            return $0.unitNumber.localizedStandardCompare($1.unitNumber) == .orderedAscending
        }
        saveUnits()
    }

    public func sortByTitle() {
        units.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        saveUnits()
    }

    public func restoreAllDefaultUnits() {
        for defaultUnit in DefaultUnits.allUnits {
            if !units.contains(where: { $0.title == defaultUnit.title && $0.unitNumber == defaultUnit.unitNumber }) {
                units.append(defaultUnit)
            }
        }
        if selectedUnitID == nil {
            selectedUnitID = units.first?.id
        }
        saveUnits()
    }

    public func resetToAllDefaultUnits() {
        self.units = DefaultUnits.allUnits
        self.selectedUnitID = units.first?.id
        saveUnits()
    }

    // MARK: - Backup & Wiederherstellung

    public struct BackupMetadata: Codable {
        public var appVersion: String
        public var exportDate: Date
        public var totalUnits: Int
        public var totalVocabularyPairs: Int
        public var units: [VocabularyUnit]

        public init(appVersion: String = "1.0", exportDate: Date = Date(), totalUnits: Int, totalVocabularyPairs: Int, units: [VocabularyUnit]) {
            self.appVersion = appVersion
            self.exportDate = exportDate
            self.totalUnits = totalUnits
            self.totalVocabularyPairs = totalVocabularyPairs
            self.units = units
        }
    }

    public enum RestoreMode {
        case replace
        case merge
    }

    public var backupsDirectory: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let backupFolder = appSupport.appendingPathComponent("GSVokabelGenerator/Backups", isDirectory: true)
        try? fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        return backupFolder
    }

    public func exportBackup(to destinationURL: URL) throws {
        let meta = BackupMetadata(
            appVersion: "1.0",
            exportDate: Date(),
            totalUnits: units.count,
            totalVocabularyPairs: units.reduce(0) { $0 + $1.pairs.count },
            units: units
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(meta)
        try data.write(to: destinationURL, options: .atomic)
    }

    public func restoreBackup(from sourceURL: URL, mode: RestoreMode) throws -> (unitCount: Int, pairCount: Int) {
        let data = try Data(contentsOf: sourceURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var importedUnits: [VocabularyUnit] = []
        if let meta = try? decoder.decode(BackupMetadata.self, from: data) {
            importedUnits = meta.units
        } else if let rawUnits = try? decoder.decode([VocabularyUnit].self, from: data) {
            importedUnits = rawUnits
        } else {
            throw NSError(
                domain: "GSVokabelGenerator",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Die ausgewählte Datei enthält kein gültiges Backup von Lerneinheiten."]
            )
        }

        guard !importedUnits.isEmpty else {
            throw NSError(
                domain: "GSVokabelGenerator",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Die Sicherungsdatei enthält keine Lerneinheiten."]
            )
        }

        switch mode {
        case .replace:
            self.units = importedUnits
            self.selectedUnitID = importedUnits.first?.id
        case .merge:
            var addedCount = 0
            for newUnit in importedUnits {
                if !units.contains(where: { $0.title == newUnit.title && $0.cleanUnitNumber == newUnit.cleanUnitNumber }) {
                    units.append(newUnit)
                    addedCount += 1
                }
            }
            if selectedUnitID == nil {
                selectedUnitID = units.first?.id
            }
        }

        saveUnits()
        let totalPairs = units.reduce(0) { $0 + $1.pairs.count }
        return (unitCount: importedUnits.count, pairCount: totalPairs)
    }

    public func performAutoBackup() {
        guard !units.isEmpty else { return }
        let dir = backupsDirectory
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileURL = dir.appendingPathComponent("backup_\(timestamp).json")

        try? exportBackup(to: fileURL)
        cleanupOldAutoBackups(maxKeep: 10)
    }

    private func cleanupOldAutoBackups(maxKeep: Int) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        let autoBackups = files.filter { $0.lastPathComponent.hasPrefix("backup_") && $0.pathExtension == "json" }
        if autoBackups.count > maxKeep {
            let sorted = autoBackups.sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return d1 < d2
            }
            let toRemove = sorted.prefix(sorted.count - maxKeep)
            for file in toRemove {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    public func openBackupsFolderInFinder() {
        let url = backupsDirectory
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }

    public func loadUnits() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            let decoded = try JSONDecoder().decode([VocabularyUnit].self, from: data)
            self.units = decoded
        } catch {
            print("Fehler beim Laden von units.json: \(error)")
        }
    }

    public func saveUnits() {
        do {
            let data = try JSONEncoder().encode(units)
            try data.write(to: saveURL, options: .atomic)
            performAutoBackup()
        } catch {
            print("Fehler beim Speichern von units.json: \(error)")
        }
    }

    private func createSampleUnit() {
        let samplePairs = [
            VocabularyPair(english: "hamster", german: "der Hamster"),
            VocabularyPair(english: "cat", german: "die Katze"),
            VocabularyPair(english: "fish", german: "der Fisch"),
            VocabularyPair(english: "dog", german: "der Hund"),
            VocabularyPair(english: "guinea pig", german: "das Meerschweinchen"),
            VocabularyPair(english: "rabbit", german: "der Hase"),
            VocabularyPair(english: "tortoise", german: "die Schildkröte"),
            VocabularyPair(english: "mouse / mice", german: "die Maus / die Mäuse"),
            VocabularyPair(english: "snake", german: "die Schlange"),
            VocabularyPair(english: "budgie", german: "der Wellensittich"),
            VocabularyPair(english: "rats", german: "die Ratten"),
            VocabularyPair(english: "pony", german: "das Pony"),
            VocabularyPair(english: "spider", german: "die Spinne")
        ]

        let unit = VocabularyUnit(
            classNumber: 3,
            unitNumber: 1,
            title: "pets and other animals",
            deadlineDay: "Freitag",
            pairs: samplePairs
        )
        self.units = [unit]
        self.selectedUnitID = unit.id
        saveUnits()
    }
}

import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject private var store = UnitStore()

    @Binding var showingHelp: Bool
    @Binding var showingAbout: Bool

    @State private var unitToDelete: VocabularyUnit? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var onlineTestUnit: VocabularyUnit? = nil
    @StateObject private var onlineTestServer = OnlineTestServer()

    @State private var backupAlertTitle: String = ""
    @State private var backupAlertMessage: String = ""
    @State private var showBackupAlert: Bool = false
    @State private var restoreURLToConfirm: URL? = nil
    @State private var showRestoreChoiceDialog: Bool = false

    public init(showingHelp: Binding<Bool> = .constant(false), showingAbout: Binding<Bool> = .constant(false)) {
        self._showingHelp = showingHelp
        self._showingAbout = showingAbout
    }

    public var body: some View {
        NavigationSplitView {
            // Sidebar: Liste aller Units
            List(selection: $store.selectedUnitID) {
                Section("Lerneinheiten (Units)") {
                    ForEach(store.units) { unit in
                        NavigationLink(value: unit.id) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Class \(unit.classNumber) Unit \(unit.cleanUnitNumber)")
                                        .font(.headline)
                                    Text(unit.title)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("\(unit.pairs.count) Vokabeln • Frist: \(unit.deadlineDay)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary.opacity(0.35))
                                    .font(.caption)
                                    .help("Reihenfolge per Drag & Drop verändern")
                            }
                            .padding(.vertical, 2)
                            .contextMenu {
                                Button {
                                    store.moveUnitUp(id: unit.id)
                                } label: {
                                    Label("Nach oben verschieben", systemImage: "arrow.up")
                                }
                                .disabled(!store.canMoveUp(id: unit.id))

                                Button {
                                    store.moveUnitDown(id: unit.id)
                                } label: {
                                    Label("Nach unten verschieben", systemImage: "arrow.down")
                                }
                                .disabled(!store.canMoveDown(id: unit.id))

                                Divider()

                                Button {
                                    onlineTestUnit = unit
                                } label: {
                                    Label("Online-Test (iPad)...", systemImage: "ipad.and.iphone")
                                }

                                Button("Duplizieren") {
                                    duplicateUnit(unit)
                                }
                                Button {
                                    exportSingleUnitCSV(unit)
                                } label: {
                                    Label("Als CSV exportieren...", systemImage: "square.and.arrow.down")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    unitToDelete = unit
                                    showDeleteAlert = true
                                } label: {
                                    Label("Lerneinheit löschen...", systemImage: "trash")
                                }
                            }
                        }
                        .draggable(unit.id.uuidString)
                        .dropDestination(for: String.self) { items, _ in
                            guard let draggedIDString = items.first,
                                  let draggedID = UUID(uuidString: draggedIDString),
                                  let fromIndex = store.units.firstIndex(where: { $0.id == draggedID }),
                                  let toIndex = store.units.firstIndex(where: { $0.id == unit.id }),
                                  fromIndex != toIndex else {
                                return false
                            }
                            withAnimation {
                                store.moveUnit(fromIndex: fromIndex, toIndex: toIndex)
                            }
                            return true
                        }
                    }
                    .onMove(perform: moveUnits)
                    .onDelete(perform: deleteUnits)
                }
            }
            .navigationTitle("Vokabel-Einheiten")
            .toolbar {
                ToolbarItemGroup {
                    Button(action: createNewUnit) {
                        Label("Neue Unit", systemImage: "plus")
                    }
                    Button(action: importNewUnitFromCSV) {
                        Label("CSV importieren", systemImage: "doc.badge.plus")
                    }
                    Menu {
                        Button(action: exportAllUnitsBackup) {
                            Label("Alle Lerneinheiten sichern (Backup)...", systemImage: "square.and.arrow.down")
                        }
                        Button(action: importUnitsBackup) {
                            Label("Backup wiederherstellen...", systemImage: "square.and.arrow.up")
                        }
                        Divider()
                        Button(action: {
                            store.openBackupsFolderInFinder()
                        }) {
                            Label("Automatische Sicherungen im Finder öffnen...", systemImage: "folder")
                        }
                    } label: {
                        Label("Sichern", systemImage: "shield.lefthalf.filled")
                    }
                    .help("Lerneinheiten als Datei sichern oder aus einem Backup wiederherstellen")

                    Menu {
                        Button("Alle 15 Vorlagen-Units ergänzen") {
                            store.restoreAllDefaultUnits()
                        }
                        Button("Auf alle 15 Vorlagen zurücksetzen", role: .destructive) {
                            store.resetToAllDefaultUnits()
                        }
                    } label: {
                        Label("Vorlagen", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .help("Vorlagen-Units aus den Dokumenten laden oder zurücksetzen")

                    Divider()

                    // Reihenfolge ändern
                    Button(action: {
                        if let selectedID = store.selectedUnitID {
                            withAnimation {
                                store.moveUnitUp(id: selectedID)
                            }
                        }
                    }) {
                        Label("Nach oben", systemImage: "arrow.up")
                    }
                    .disabled(store.selectedUnitID == nil || !store.canMoveUp(id: store.selectedUnitID ?? UUID()))
                    .help("Ausgewählte Lerneinheit in der Liste nach oben verschieben (⌥↑)")
                    .keyboardShortcut(.upArrow, modifiers: .option)

                    Button(action: {
                        if let selectedID = store.selectedUnitID {
                            withAnimation {
                                store.moveUnitDown(id: selectedID)
                            }
                        }
                    }) {
                        Label("Nach unten", systemImage: "arrow.down")
                    }
                    .disabled(store.selectedUnitID == nil || !store.canMoveDown(id: store.selectedUnitID ?? UUID()))
                    .help("Ausgewählte Lerneinheit in der Liste nach unten verschieben (⌥↓)")
                    .keyboardShortcut(.downArrow, modifiers: .option)

                    Menu {
                        Button("Nach Klasse & Unit-Nummer sortieren") {
                            withAnimation {
                                store.sortByUnitNumber()
                            }
                        }
                        Button("Alphabetisch nach Thema sortieren") {
                            withAnimation {
                                store.sortByTitle()
                            }
                        }
                    } label: {
                        Label("Sortieren", systemImage: "arrow.up.arrow.down")
                    }
                    .help("Reihenfolge der Lerneinheiten sortieren")

                    Divider()

                    Button(role: .destructive, action: {
                        if let selectedID = store.selectedUnitID,
                           let unit = store.units.first(where: { $0.id == selectedID }) {
                            unitToDelete = unit
                            showDeleteAlert = true
                        }
                    }) {
                        Label("Ausgewählte Unit löschen", systemImage: "trash")
                    }
                    .disabled(store.selectedUnitID == nil)
                    .help("Ausgewählte Lerneinheit löschen")

                    Button(action: { showingHelp = true }) {
                        Label("Hilfe", systemImage: "questionmark.circle")
                    }
                    .help("Hilfe & Dokumentation öffnen (⌘?)")
                }
            }
            .alert("Lerneinheit löschen?", isPresented: $showDeleteAlert, presenting: unitToDelete) { unit in
                Button("Löschen", role: .destructive) {
                    store.deleteUnit(id: unit.id)
                }
                Button("Abbrechen", role: .cancel) {}
            } message: { unit in
                Text("Möchtest du die Lerneinheit „Class \(unit.classNumber) Unit \(unit.cleanUnitNumber): \(unit.title)“ wirklich unwiderruflich löschen?")
            }
        } detail: {
            if let selectedID = store.selectedUnitID,
               let index = store.units.firstIndex(where: { $0.id == selectedID }) {
                UnitDetailView(
                    unit: $store.units[index],
                    onSave: {
                        store.saveUnits()
                    },
                    onDeleteUnit: {
                        unitToDelete = store.units[index]
                        showDeleteAlert = true
                    }
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Wähle eine Lerneinheit aus der Seitenleiste")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(item: $onlineTestUnit) { unit in
            OnlineTestView(server: onlineTestServer, unit: unit)
        }
        .alert(backupAlertTitle, isPresented: $showBackupAlert) {
            Button("OK") {}
        } message: {
            Text(backupAlertMessage)
        }
        .confirmationDialog(
            "Backup wiederherstellen",
            isPresented: $showRestoreChoiceDialog,
            titleVisibility: .visible,
            presenting: restoreURLToConfirm
        ) { url in
            Button("Mit vorhandenen zusammenführen (empfohlen)") {
                executeRestore(from: url, mode: .merge)
            }
            Button("Alle vorhandenen Einheiten ersetzen", role: .destructive) {
                executeRestore(from: url, mode: .replace)
            }
            Button("Abbrechen", role: .cancel) {
                restoreURLToConfirm = nil
            }
        } message: { _ in
            Text("Möchtest du die Lerneinheiten aus dem Backup zu deiner Liste hinzufügen oder alle vorhandenen Lerneinheiten durch das Backup ersetzen?")
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportBackupRequested)) { _ in
            exportAllUnitsBackup()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importBackupRequested)) { _ in
            importUnitsBackup()
        }
    }

    private func createNewUnit() {
        let intNumbers = store.units.compactMap { Int($0.cleanUnitNumber) }
        let nextNumber = "\((intNumbers.max() ?? store.units.count) + 1)"
        let newUnit = VocabularyUnit(
            classNumber: 3,
            unitNumber: nextNumber,
            title: "Neues Thema",
            deadlineDay: "Freitag",
            pairs: []
        )
        store.addUnit(newUnit)
    }

    private func duplicateUnit(_ unit: VocabularyUnit) {
        var copy = unit
        copy.id = UUID()
        copy.title = "\(unit.title) (Kopie)"
        let baseNumber = unit.cleanUnitNumber
        if let intVal = Int(baseNumber) {
            copy.unitNumber = "\(intVal).1"
        } else if let dotRange = baseNumber.range(of: ".", options: .backwards),
                  let subNum = Int(baseNumber[dotRange.upperBound...]) {
            let prefix = baseNumber[..<dotRange.lowerBound]
            copy.unitNumber = "\(prefix).\(subNum + 1)"
        } else {
            let intNumbers = store.units.compactMap { Int($0.cleanUnitNumber) }
            copy.unitNumber = "\((intNumbers.max() ?? 0) + 1)"
        }
        copy.pairs = unit.pairs.map { VocabularyPair(id: UUID(), english: $0.english, german: $0.german) }
        store.addUnit(copy)
    }

    private func deleteUnits(at offsets: IndexSet) {
        for index in offsets {
            let unit = store.units[index]
            store.deleteUnit(id: unit.id)
        }
    }

    private func moveUnits(from source: IndexSet, to destination: Int) {
        withAnimation {
            store.moveUnits(from: source, to: destination)
        }
    }

    private func importNewUnitFromCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText, UTType.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let pairs = try? CSVImporter.parse(url: url) {
                let filename = url.deletingPathExtension().lastPathComponent
                let intNumbers = store.units.compactMap { Int($0.cleanUnitNumber) }
                let nextNumber = "\((intNumbers.max() ?? store.units.count) + 1)"
                let newUnit = VocabularyUnit(
                    classNumber: 3,
                    unitNumber: nextNumber,
                    title: filename,
                    deadlineDay: "Freitag",
                    pairs: pairs
                )
                store.addUnit(newUnit)
            }
        }
    }

    private func exportAllUnitsBackup() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        panel.nameFieldStringValue = "GSVokabel_Backup_\(df.string(from: Date())).json"
        panel.title = "Alle Lerneinheiten sichern"
        panel.message = "Wähle einen Speicherort für das Backup deiner Lerneinheiten."

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try store.exportBackup(to: url)
                backupAlertTitle = "Backup erfolgreich gesichert"
                let totalWords = store.units.reduce(0) { $0 + $1.pairs.count }
                backupAlertMessage = "\(store.units.count) Lerneinheiten mit insgesamt \(totalWords) Vokabeln wurden in „\(url.lastPathComponent)“ gesichert."
                showBackupAlert = true
            } catch {
                backupAlertTitle = "Fehler beim Sichern"
                backupAlertMessage = error.localizedDescription
                showBackupAlert = true
            }
        }
    }

    private func importUnitsBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Backup-Datei auswählen"
        panel.message = "Wähle eine gesicherte Backup-Datei (.json) aus."

        if panel.runModal() == .OK, let url = panel.url {
            restoreURLToConfirm = url
            showRestoreChoiceDialog = true
        }
    }

    private func executeRestore(from url: URL, mode: UnitStore.RestoreMode) {
        do {
            let result = try store.restoreBackup(from: url, mode: mode)
            backupAlertTitle = "Backup wiederhergestellt"
            if mode == .merge {
                backupAlertMessage = "Die Einheiten aus „\(url.lastPathComponent)“ wurden erfolgreich mit deinen Lerneinheiten zusammengeführt. (Aktuell: \(store.units.count) Einheiten)."
            } else {
                backupAlertMessage = "Alle vorhandenen Einheiten wurden durch die \(result.unitCount) Lerneinheiten aus „\(url.lastPathComponent)“ ersetzt."
            }
            showBackupAlert = true
        } catch {
            backupAlertTitle = "Fehler bei der Wiederherstellung"
            backupAlertMessage = error.localizedDescription
            showBackupAlert = true
        }
        restoreURLToConfirm = nil
    }

    private func exportSingleUnitCSV(_ unit: VocabularyUnit) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        let cleanName = unit.title.replacingOccurrences(of: "/", with: "-")
        panel.nameFieldStringValue = "Class \(unit.classNumber) Unit \(unit.cleanUnitNumber) \(cleanName).csv"
        panel.title = "Lerneinheit als CSV exportieren"

        if panel.runModal() == .OK, let url = panel.url {
            var csv = "English,German\n"
            for pair in unit.pairs {
                let eng = pair.english.contains(",") ? "\"\(pair.english)\"" : pair.english
                let ger = pair.german.contains(",") ? "\"\(pair.german)\"" : pair.german
                csv += "\(eng),\(ger)\n"
            }
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                backupAlertTitle = "CSV exportiert"
                backupAlertMessage = "Die Lerneinheit „\(unit.title)“ (\(unit.pairs.count) Vokabeln) wurde erfolgreich als CSV-Datei gespeichert."
                showBackupAlert = true
            } catch {
                backupAlertTitle = "Fehler beim Exportieren"
                backupAlertMessage = error.localizedDescription
                showBackupAlert = true
            }
        }
    }
}

extension Notification.Name {
    public static let exportBackupRequested = Notification.Name("exportBackupRequested")
    public static let importBackupRequested = Notification.Name("importBackupRequested")
}

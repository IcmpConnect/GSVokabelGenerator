import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct UnitDetailView: View {
    @Binding public var unit: VocabularyUnit
    public var onSave: () -> Void
    public var onDeleteUnit: () -> Void

    @State private var showingPreview: Bool = false
    @State private var previewTitle: String = ""
    @State private var previewData: Data = Data()

    @State private var showingSpellingSheet: Bool = false
    @State private var showingAutoTranslateSheet: Bool = false
    @State private var showingOnlineTestSheet: Bool = false
    @StateObject private var onlineTestServer = OnlineTestServer()
    @State private var isQuickTranslating: Bool = false
    @State private var newEnglish: String = ""
    @State private var newGerman: String = ""

    public init(unit: Binding<VocabularyUnit>, onSave: @escaping () -> Void, onDeleteUnit: @escaping () -> Void = {}) {
        self._unit = unit
        self.onSave = onSave
        self.onDeleteUnit = onDeleteUnit
    }

    private var incompletePairCount: Int {
        unit.pairs.filter {
            let e = $0.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let g = $0.german.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return (e && !g) || (!e && g)
        }.count
    }

    private var spellingStatusMap: [UUID: PairSpellingStatus] {
        return VocabularySpellChecker.shared.checkUnit(unit)
    }

    private var totalIssueCount: Int {
        return spellingStatusMap.values.reduce(0) { $0 + $1.totalIssueCount }
    }

    private var newEnglishIssues: [SpellingIssue] {
        VocabularySpellChecker.shared.checkText(newEnglish, language: .english)
    }

    private var newGermanIssues: [SpellingIssue] {
        VocabularySpellChecker.shared.checkText(newGerman, language: .german)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Oberer Konfigurationsbereich
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Klasse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Klasse", value: $unit.classNumber, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("z. B. 1 oder 2.1", text: $unit.unitNumber)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thema / Titel")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Thema", text: $unit.title)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 200)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Frist / Abgabetag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Tag", text: $unit.deadlineDay)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(" ")
                            .font(.caption)
                        Button(role: .destructive, action: onDeleteUnit) {
                            Label("Unit löschen...", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .help("Diese Lerneinheit löschen")
                    }
                }

                // Notenskalen-Infoanzeige
                HStack(spacing: 8) {
                    let grading = GradingScale(totalPoints: unit.pairs.count)
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.accentColor)
                    Text("Bewertungsskala für \(unit.pairs.count) Vokabeln:")
                        .font(.caption.bold())
                    ForEach(grading.thresholds, id: \.level) { th in
                        Text("Stufe \(th.level): \(th.rangeString) Pkt.")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Vokabelliste & Tabellen-Toolbar
            HStack(spacing: 12) {
                Text("Vokabeln (\(unit.pairs.count))")
                    .font(.headline)

                Spacer()

                // Rechtschreibprüfungs-Button mit Badge
                Button(action: {
                    showingSpellingSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: totalIssueCount == 0 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(totalIssueCount == 0 ? .green : .orange)
                        Text(totalIssueCount == 0 ? "Rechtschreibung OK" : "\(totalIssueCount) Schreibhinweis(e)")
                    }
                }
                .buttonStyle(.bordered)
                .help("Klicken zur detaillierten Rechtschreibprüfung und Online-Wörterbuchabgleich")

                // Auto-Übersetzungs-Button mit Statusanzeige
                Button(action: {
                    showingAutoTranslateSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(incompletePairCount > 0 ? .orange : .accentColor)
                        if incompletePairCount > 0 {
                            Text("\(incompletePairCount) Übersetzung(en) suchen")
                        } else {
                            Text("Auto-Übersetzen...")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .help("Fehlende Vokabeln automatisch im Grundschulwörterbuch oder Internet suchen und einbauen")

                Button(action: importCSV) {
                    Label("CSV importieren...", systemImage: "square.and.arrow.down")
                }

                Menu {
                    Button("Lernblatt (Schule & Hausaufgabe)") {
                        openPreview(title: "Lernblatt - \(unit.displayIdentifier)", mode: .learningSheetBothPages)
                    }
                    Button("Lernblatt (nur Schule / Work)") {
                        openPreview(title: "Lernblatt Schule - \(unit.displayIdentifier)", mode: .learningSheet(isHomework: false))
                    }
                    Button("Lernblatt (nur Hausaufgabe)") {
                        openPreview(title: "Lernblatt Hausaufgabe - \(unit.displayIdentifier)", mode: .learningSheet(isHomework: true))
                    }
                } label: {
                    Label("Lernblatt...", systemImage: "doc.text")
                }

                Menu {
                    Section("Vokabeltest (Gruppe A & B)") {
                        Button("Abwechselnd (Gruppe A & B invers)") {
                            openPreview(title: "Vokabeltest (Abwechselnd) - \(unit.displayIdentifier)", mode: .vocabularyTest(promptMode: .alternating, includeBothGroups: true))
                        }
                        Button("Nur Deutsch vorgegeben (Englisch abgefragt)") {
                            openPreview(title: "Vokabeltest (Nur Deutsch) - \(unit.displayIdentifier)", mode: .vocabularyTest(promptMode: .germanOnly, includeBothGroups: true))
                        }
                        Button("Nur Englisch vorgegeben (Deutsch abgefragt)") {
                            openPreview(title: "Vokabeltest (Nur Englisch) - \(unit.displayIdentifier)", mode: .vocabularyTest(promptMode: .englishOnly, includeBothGroups: true))
                        }
                    }

                    Section("Einzelseite (nur Gruppe A)") {
                        Button("Abwechselnd (Gruppe A)") {
                            openPreview(title: "Vokabeltest Gruppe A (Abwechselnd) - \(unit.displayIdentifier)", mode: .vocabularyTest(promptMode: .alternating, includeBothGroups: false))
                        }
                        Button("Nur Deutsch vorgegeben (Gruppe A)") {
                            openPreview(title: "Vokabeltest Gruppe A (Nur Deutsch) - \(unit.displayIdentifier)", mode: .vocabularyTest(promptMode: .germanOnly, includeBothGroups: false))
                        }
                        Button("Nur Englisch vorgegeben (Gruppe A)") {
                            openPreview(title: "Vokabeltest Gruppe A (Nur Englisch) - \(unit.displayIdentifier)", mode: .vocabularyTest(promptMode: .englishOnly, includeBothGroups: false))
                        }
                    }
                } label: {
                    Label("Vokabeltest drucken...", systemImage: "printer.fill")
                }
                .menuStyle(.borderedButton)

                Button(action: {
                    showingOnlineTestSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "ipad.and.iphone")
                            .foregroundColor(.accentColor)
                        Text("Online-Test (iPad)...")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(.borderedProminent)
                .help("Startet den Online-Test auf dem MacBook mit QR-Code für Schüler-iPads")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Tabelle mit Vokabeln (direkt bearbeitbar)
            Table(unit.pairs) {
                TableColumn("Englisch") { pair in
                    let issues = spellingStatusMap[pair.id]?.englishIssues ?? []
                    HStack(spacing: 6) {
                        TextField("Englisch", text: Binding(
                            get: { pair.english },
                            set: { newValue in
                                if let idx = unit.pairs.firstIndex(where: { $0.id == pair.id }) {
                                    unit.pairs[idx].english = newValue
                                    onSave()
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))

                        if pair.english.trimmingCharacters(in: .whitespaces).isEmpty && !pair.german.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button(action: {
                                translateSinglePair(pair, toLanguage: .english)
                            }) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .help("Englische Übersetzung für '\(pair.german)' automatisch suchen")
                        }

                        if !issues.isEmpty {
                            Menu {
                                Section("Möglicher Tippfehler im Englischen") {
                                    ForEach(issues) { issue in
                                        ForEach(issue.suggestions, id: \.self) { suggestion in
                                            Button("Ersetzen durch '\(suggestion)'") {
                                                applyCorrection(pair: pair, word: issue.word, replacement: suggestion, isEnglish: true)
                                            }
                                        }
                                    }
                                }
                                Section("Online-Wörterbuch") {
                                    Button("In PONS nachschlagen") {
                                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: pair.english))
                                    }
                                    Button("In LEO nachschlagen") {
                                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.leoURL(for: pair.english))
                                    }
                                    Button("Cambridge Dictionary") {
                                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.cambridgeURL(for: pair.english))
                                    }
                                }
                            } label: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }

                TableColumn("Deutsch") { pair in
                    let issues = spellingStatusMap[pair.id]?.germanIssues ?? []
                    HStack(spacing: 6) {
                        TextField("Deutsch", text: Binding(
                            get: { pair.german },
                            set: { newValue in
                                if let idx = unit.pairs.firstIndex(where: { $0.id == pair.id }) {
                                    unit.pairs[idx].german = newValue
                                    onSave()
                                }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .rounded))

                        if pair.german.trimmingCharacters(in: .whitespaces).isEmpty && !pair.english.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button(action: {
                                translateSinglePair(pair, toLanguage: .german)
                            }) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .help("Deutsche Übersetzung für '\(pair.english)' automatisch suchen")
                        }

                        if !issues.isEmpty {
                            Menu {
                                Section("Möglicher Tippfehler im Deutschen") {
                                    ForEach(issues) { issue in
                                        ForEach(issue.suggestions, id: \.self) { suggestion in
                                            Button("Ersetzen durch '\(suggestion)'") {
                                                applyCorrection(pair: pair, word: issue.word, replacement: suggestion, isEnglish: false)
                                            }
                                        }
                                    }
                                }
                                Section("Online-Wörterbuch") {
                                    Button("In PONS nachschlagen") {
                                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: pair.german))
                                    }
                                    Button("In LEO nachschlagen") {
                                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.leoURL(for: pair.german))
                                    }
                                    Button("Im Duden nachschlagen") {
                                        OnlineDictionaryService.openInBrowser(OnlineDictionaryService.dudenURL(for: pair.german))
                                    }
                                }
                            } label: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }

                TableColumn("Wörterbuch") { pair in
                    Menu {
                        Button("In PONS nachschlagen") {
                            OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: pair.english))
                        }
                        Button("In LEO nachschlagen") {
                            OnlineDictionaryService.openInBrowser(OnlineDictionaryService.leoURL(for: pair.english))
                        }
                        Button("Cambridge Dictionary (EN)") {
                            OnlineDictionaryService.openInBrowser(OnlineDictionaryService.cambridgeURL(for: pair.english))
                        }
                        Button("Duden (DE)") {
                            OnlineDictionaryService.openInBrowser(OnlineDictionaryService.dudenURL(for: pair.german))
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .help("Im Online-Wörterbuch nachschlagen")
                }
                .width(40)

                TableColumn("Löschen") { pair in
                    Button(action: {
                        unit.pairs.removeAll { $0.id == pair.id }
                        onSave()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .width(40)
            }

            Divider()

            // Schnell-Eingabezeile für neue Vokabel mit Live-Rechtschreibprüfung
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    TextField("Englische Vokabel...", text: $newEnglish)
                        .textFieldStyle(.roundedBorder)

                    Button(action: translateQuickEntry) {
                        if isQuickTranslating {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "sparkles")
                        }
                    }
                    .buttonStyle(.bordered)
                    .help("Automatisch übersetzen (Internet / Wörterbuch)")
                    .disabled(isQuickTranslating || (newEnglish.trimmingCharacters(in: .whitespaces).isEmpty && newGerman.trimmingCharacters(in: .whitespaces).isEmpty))

                    TextField("Deutsche Übersetzung...", text: $newGerman)
                        .textFieldStyle(.roundedBorder)

                    Button(action: addVocabularyPair) {
                        Label("Hinzufügen", systemImage: "plus")
                    }
                    .disabled((newEnglish.trimmingCharacters(in: .whitespaces).isEmpty && newGerman.trimmingCharacters(in: .whitespaces).isEmpty) || isQuickTranslating)
                    .keyboardShortcut(.defaultAction)
                }

                // Live-Vorschläge während des Tippens zur Fehlervermeidung
                if !newEnglishIssues.isEmpty || !newGermanIssues.isEmpty {
                    HStack(spacing: 12) {
                        if let engIssue = newEnglishIssues.first {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Englisch '\(engIssue.word)':")
                                    .font(.caption.bold())
                                if let sug = engIssue.suggestions.first {
                                    Button("Korrektur '\(sug)'") {
                                        newEnglish = VocabularySpellChecker.shared.replaceWord(
                                            in: newEnglish,
                                            wordToReplace: engIssue.word,
                                            with: sug
                                        )
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                }
                                Button("In PONS prüfen") {
                                    OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: engIssue.word))
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }

                        if let gerIssue = newGermanIssues.first {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("Deutsch '\(gerIssue.word)':")
                                    .font(.caption.bold())
                                if let sug = gerIssue.suggestions.first {
                                    Button("Korrektur '\(sug)'") {
                                        newGerman = VocabularySpellChecker.shared.replaceWord(
                                            in: newGerman,
                                            wordToReplace: gerIssue.word,
                                            with: sug
                                        )
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                                }
                                Button("Im Duden prüfen") {
                                    OnlineDictionaryService.openInBrowser(OnlineDictionaryService.dudenURL(for: gerIssue.word))
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .sheet(isPresented: $showingPreview) {
            PDFPreviewSheet(title: previewTitle, pdfData: previewData)
        }
        .sheet(isPresented: $showingSpellingSheet) {
            SpellingReviewSheet(unit: $unit, onSave: onSave)
        }
        .sheet(isPresented: $showingAutoTranslateSheet) {
            AutoTranslateSheet(unit: $unit, onSave: onSave)
        }
        .sheet(isPresented: $showingOnlineTestSheet) {
            OnlineTestView(server: onlineTestServer, unit: unit)
        }
    }

    private func translateQuickEntry() {
        let eng = newEnglish.trimmingCharacters(in: .whitespaces)
        let ger = newGerman.trimmingCharacters(in: .whitespaces)

        isQuickTranslating = true
        Task {
            if !eng.isEmpty && ger.isEmpty {
                let res = await VocabularyTranslationService.shared.translate(text: eng, from: .english)
                await MainActor.run {
                    newGerman = res.primary
                    isQuickTranslating = false
                }
            } else if eng.isEmpty && !ger.isEmpty {
                let res = await VocabularyTranslationService.shared.translate(text: ger, from: .german)
                await MainActor.run {
                    newEnglish = res.primary
                    isQuickTranslating = false
                }
            } else if !eng.isEmpty && !ger.isEmpty {
                // Bei beidseitiger Eingabe neu übersetzen (Englisch als Basis)
                let res = await VocabularyTranslationService.shared.translate(text: eng, from: .english)
                await MainActor.run {
                    newGerman = res.primary
                    isQuickTranslating = false
                }
            } else {
                await MainActor.run {
                    isQuickTranslating = false
                }
            }
        }
    }

    private func translateSinglePair(_ pair: VocabularyPair, toLanguage: SpellingLanguage) {
        guard let idx = unit.pairs.firstIndex(where: { $0.id == pair.id }) else { return }
        let fromLang: SpellingLanguage = (toLanguage == .english) ? .german : .english
        let query = (toLanguage == .english) ? pair.german : pair.english

        Task {
            let res = await VocabularyTranslationService.shared.translate(text: query, from: fromLang)
            await MainActor.run {
                if toLanguage == .english {
                    unit.pairs[idx].english = res.primary
                } else {
                    unit.pairs[idx].german = res.primary
                }
                onSave()
            }
        }
    }

    private func addVocabularyPair() {
        let eng = newEnglish.trimmingCharacters(in: .whitespaces)
        let ger = newGerman.trimmingCharacters(in: .whitespaces)
        guard !eng.isEmpty || !ger.isEmpty else { return }

        if !eng.isEmpty && !ger.isEmpty {
            unit.pairs.append(VocabularyPair(english: eng, german: ger))
            newEnglish = ""
            newGerman = ""
            onSave()
        } else {
            // Eine Seite fehlt -> automatisch im Hintergrund übersetzen und direkt einbauen!
            isQuickTranslating = true
            Task {
                if !eng.isEmpty && ger.isEmpty {
                    let res = await VocabularyTranslationService.shared.translate(text: eng, from: .english)
                    await MainActor.run {
                        unit.pairs.append(VocabularyPair(english: eng, german: res.primary))
                        newEnglish = ""
                        newGerman = ""
                        isQuickTranslating = false
                        onSave()
                    }
                } else if eng.isEmpty && !ger.isEmpty {
                    let res = await VocabularyTranslationService.shared.translate(text: ger, from: .german)
                    await MainActor.run {
                        unit.pairs.append(VocabularyPair(english: res.primary, german: ger))
                        newEnglish = ""
                        newGerman = ""
                        isQuickTranslating = false
                        onSave()
                    }
                }
            }
        }
    }

    private func applyCorrection(pair: VocabularyPair, word: String, replacement: String, isEnglish: Bool) {
        guard let index = unit.pairs.firstIndex(where: { $0.id == pair.id }) else { return }
        if isEnglish {
            unit.pairs[index].english = VocabularySpellChecker.shared.replaceWord(
                in: unit.pairs[index].english,
                wordToReplace: word,
                with: replacement
            )
        } else {
            unit.pairs[index].german = VocabularySpellChecker.shared.replaceWord(
                in: unit.pairs[index].german,
                wordToReplace: word,
                with: replacement
            )
        }
        onSave()
    }

    private func importCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText, UTType.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            if let pairs = try? CSVImporter.parse(url: url), !pairs.isEmpty {
                unit.pairs = pairs
                onSave()
            }
        }
    }

    private func openPreview(title: String, mode: PDFPrintMode) {
        let data = PDFGenerator.generatePDF(for: unit, mode: mode)
        self.previewTitle = title
        self.previewData = data
        self.showingPreview = true
    }
}

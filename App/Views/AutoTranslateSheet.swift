import SwiftUI

public struct PendingTranslationItem: Identifiable {
    public let id: UUID
    public let originalPair: VocabularyPair
    public let isEnglishMissing: Bool
    public let knownWord: String
    public var suggestedTranslation: String
    public var alternatives: [String]
    public var source: TranslationSource
    public var isLoading: Bool

    public init(
        pair: VocabularyPair,
        isEnglishMissing: Bool,
        knownWord: String,
        suggestedTranslation: String = "",
        alternatives: [String] = [],
        source: TranslationSource = .fallback,
        isLoading: Bool = true
    ) {
        self.id = pair.id
        self.originalPair = pair
        self.isEnglishMissing = isEnglishMissing
        self.knownWord = knownWord
        self.suggestedTranslation = suggestedTranslation
        self.alternatives = alternatives
        self.source = source
        self.isLoading = isLoading
    }
}

public struct AutoTranslateSheet: View {
    @Binding public var unit: VocabularyUnit
    public var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var items: [PendingTranslationItem] = []
    @State private var isProcessing: Bool = false
    @State private var quickWord: String = ""
    @State private var quickLanguage: SpellingLanguage = .german
    @State private var quickSearching: Bool = false

    public init(unit: Binding<VocabularyUnit>, onSave: @escaping () -> Void) {
        self._unit = unit
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Automatische Vokabelsuche")
                        .font(.headline)
                    Text("Fehlende Übersetzungen aus Wörterbuch und Internet ergänzen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Schließen") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Inhalt
            if items.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Alle Vokabeln sind vollständig!")
                        .font(.title3.bold())
                    Text("In dieser Lerneinheit gibt es keine leeren Vokabelfelder.")
                        .foregroundColor(.secondary)
                        .font(.callout)

                    Divider()
                        .frame(maxWidth: 300)
                        .padding(.vertical, 8)

                    // Schnell-Übersetzung für eine neue Vokabel anbieten
                    VStack(spacing: 10) {
                        Text("Möchtest du eine neue Vokabel übersetzen und hinzufügen?")
                            .font(.subheadline.bold())

                        HStack(spacing: 8) {
                            Picker("", selection: $quickLanguage) {
                                Text("Deutsch vorgegeben").tag(SpellingLanguage.german)
                                Text("Englisch vorgegeben").tag(SpellingLanguage.english)
                            }
                            .frame(width: 170)

                            TextField(quickLanguage == .german ? "z. B. der Schmetterling..." : "z. B. butterfly...", text: $quickWord)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 220)

                            Button(action: addQuickTranslatedWord) {
                                if quickSearching {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Label("Suchen & Einfügen", systemImage: "plus.circle.fill")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(quickWord.trimmingCharacters(in: .whitespaces).isEmpty || quickSearching)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)

                    Spacer()
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(items.count) unvollständige Vokabel(n) gefunden:")
                            .font(.subheadline.bold())
                        Spacer()
                        if isProcessing {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Suche Übersetzungen...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    List {
                        ForEach($items) { $item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    // Bekanntes Wort
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.isEnglishMissing ? "Vorgegeben (Deutsch):" : "Vorgegeben (Englisch):")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text(item.knownWord)
                                            .font(.body.bold())
                                    }
                                    .frame(minWidth: 160, alignment: .leading)

                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)

                                    // Gefundene Übersetzung (bearbeitbar)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(item.isEnglishMissing ? "Gesucht (Englisch):" : "Gesucht (Deutsch):")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)

                                            if item.isLoading {
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            } else {
                                                Text(item.source.rawValue)
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 1)
                                                    .background(item.source == .localDictionary ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                                                    .foregroundColor(item.source == .localDictionary ? .green : .blue)
                                                    .cornerRadius(3)
                                            }
                                        }

                                        TextField("Übersetzung...", text: $item.suggestedTranslation)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    .frame(minWidth: 200)

                                    // Wörterbuch-Link
                                    Menu {
                                        Button("In PONS prüfen") {
                                            OnlineDictionaryService.openInBrowser(OnlineDictionaryService.ponsURL(for: item.knownWord))
                                        }
                                        Button("In LEO prüfen") {
                                            OnlineDictionaryService.openInBrowser(OnlineDictionaryService.leoURL(for: item.knownWord))
                                        }
                                    } label: {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.secondary)
                                    }
                                    .menuStyle(.borderlessButton)
                                    .help("Im Wörterbuch nachschlagen")
                                }

                                // Alternative Treffer als Klick-Chips
                                if !item.alternatives.isEmpty {
                                    HStack(spacing: 6) {
                                        Text("Alternativen:")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        ForEach(item.alternatives, id: \.self) { alt in
                                            Button(alt) {
                                                item.suggestedTranslation = alt
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.mini)
                                        }
                                    }
                                    .padding(.leading, 180)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }

                Divider()

                // Footer Actions
                HStack {
                    Button("Abbrechen") {
                        dismiss()
                    }

                    Spacer()

                    Button(action: applyAllTranslations) {
                        Label("Alle Übersetzungen übernehmen", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing || items.isEmpty)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(minWidth: 620, minHeight: 450)
        .onAppear {
            loadIncompletePairs()
        }
    }

    private func loadIncompletePairs() {
        var found: [PendingTranslationItem] = []
        for pair in unit.pairs {
            let eng = pair.english.trimmingCharacters(in: .whitespacesAndNewlines)
            let ger = pair.german.trimmingCharacters(in: .whitespacesAndNewlines)

            if eng.isEmpty && !ger.isEmpty {
                found.append(PendingTranslationItem(pair: pair, isEnglishMissing: true, knownWord: ger))
            } else if !eng.isEmpty && ger.isEmpty {
                found.append(PendingTranslationItem(pair: pair, isEnglishMissing: false, knownWord: eng))
            }
        }
        self.items = found

        if !items.isEmpty {
            startTranslationProcess()
        }
    }

    private func startTranslationProcess() {
        isProcessing = true
        Task {
            for i in 0..<items.count {
                let item = items[i]
                let sourceLang: SpellingLanguage = item.isEnglishMissing ? .german : .english
                let res = await VocabularyTranslationService.shared.translate(text: item.knownWord, from: sourceLang)

                await MainActor.run {
                    items[i].suggestedTranslation = res.primary
                    items[i].alternatives = res.alternatives
                    items[i].source = res.source
                    items[i].isLoading = false
                }
            }
            await MainActor.run {
                isProcessing = false
            }
        }
    }

    private func applyAllTranslations() {
        for item in items {
            guard let idx = unit.pairs.firstIndex(where: { $0.id == item.id }) else { continue }
            let finalTranslation = item.suggestedTranslation.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalTranslation.isEmpty {
                if item.isEnglishMissing {
                    unit.pairs[idx].english = finalTranslation
                } else {
                    unit.pairs[idx].german = finalTranslation
                }
            }
        }
        onSave()
        dismiss()
    }

    private func addQuickTranslatedWord() {
        let word = quickWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !word.isEmpty else { return }

        quickSearching = true
        Task {
            let res = await VocabularyTranslationService.shared.translate(text: word, from: quickLanguage)
            await MainActor.run {
                quickSearching = false
                if quickLanguage == .german {
                    unit.pairs.append(VocabularyPair(english: res.primary, german: word))
                } else {
                    unit.pairs.append(VocabularyPair(english: word, german: res.primary))
                }
                quickWord = ""
                onSave()
            }
        }
    }
}

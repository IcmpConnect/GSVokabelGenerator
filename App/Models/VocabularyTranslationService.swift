import Foundation

public enum TranslationSource: String {
    case localDictionary = "Wörterbuch"
    case onlineInternet = "Internet"
    case fallback = "Manuell"
}

public struct TranslationResult: Equatable {
    public let primary: String
    public let alternatives: [String]
    public let source: TranslationSource

    public init(primary: String, alternatives: [String] = [], source: TranslationSource) {
        self.primary = primary
        self.alternatives = alternatives
        self.source = source
    }
}

public final class VocabularyTranslationService {
    public static let shared = VocabularyTranslationService()

    private var localEnglishToGerman: [String: (primary: String, alternatives: [String])] = [:]
    private var localGermanToEnglish: [String: (primary: String, alternatives: [String])] = [:]

    private init() {
        buildLocalDictionary()
    }

    // MARK: - Hauptsuchfunktion

    /// Übersetzt einen Text abhängig von der Quellsprache (Englisch -> Deutsch oder Deutsch -> Englisch)
    public func translate(
        text: String,
        from sourceLang: SpellingLanguage
    ) async -> TranslationResult {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return TranslationResult(primary: "", source: .fallback)
        }

        // 1. Lokales Grundschul-Wörterbuch (blitzschnell & mit optimalen Artikeln)
        if let local = lookupLocal(text: cleaned, from: sourceLang) {
            return local
        }

        // 2. Online-Übersetzung über Internet (MyMemory API)
        if let online = await lookupOnline(text: cleaned, from: sourceLang) {
            return online
        }

        return TranslationResult(primary: cleaned, source: .fallback)
    }

    /// Ergänzt bei einem unvollständigen Vokabelpaar automatisch die fehlende Sprache
    public func completePair(_ pair: VocabularyPair) async -> VocabularyPair {
        var copy = pair
        let eng = copy.english.trimmingCharacters(in: .whitespacesAndNewlines)
        let ger = copy.german.trimmingCharacters(in: .whitespacesAndNewlines)

        if eng.isEmpty && !ger.isEmpty {
            let res = await translate(text: ger, from: .german)
            copy.english = res.primary
        } else if !eng.isEmpty && ger.isEmpty {
            let res = await translate(text: eng, from: .english)
            copy.german = res.primary
        }
        return copy
    }

    // MARK: - Lokale Suche

    private func lookupLocal(text: String, from sourceLang: SpellingLanguage) -> TranslationResult? {
        let norm = normalize(text)
        if sourceLang == .english {
            if let match = localEnglishToGerman[norm] {
                return TranslationResult(primary: match.primary, alternatives: match.alternatives, source: .localDictionary)
            }
            // Versuche ohne vorangestelltes 'to ' bei Verben
            if norm.hasPrefix("to ") {
                let stripped = String(norm.dropFirst(3))
                if let match = localEnglishToGerman[stripped] {
                    return TranslationResult(primary: match.primary, alternatives: match.alternatives, source: .localDictionary)
                }
            }
        } else {
            if let match = localGermanToEnglish[norm] {
                return TranslationResult(primary: match.primary, alternatives: match.alternatives, source: .localDictionary)
            }
            // Versuche ohne 'der ', 'die ', 'das '
            for article in ["der ", "die ", "das "] {
                if norm.hasPrefix(article) {
                    let stripped = String(norm.dropFirst(article.count))
                    if let match = localGermanToEnglish[stripped] {
                        return TranslationResult(primary: match.primary, alternatives: match.alternatives, source: .localDictionary)
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Online-Suche via Internet

    private func lookupOnline(text: String, from sourceLang: SpellingLanguage) async -> TranslationResult? {
        let sourceCode = (sourceLang == .english) ? "en" : "de"
        let targetCode = (sourceLang == .english) ? "de" : "en"

        // Deutsche Artikel vor der Online-Abfrage sauber abtrennen für bessere Treffer
        var query = text
        if sourceLang == .german {
            for art in ["der ", "die ", "das "] {
                if query.lowercased().hasPrefix(art) {
                    query = String(query.dropFirst(art.count))
                    break
                }
            }
        }

        var components = URLComponents(string: "https://api.mymemory.translated.net/get")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "langpair", value: "\(sourceCode)|\(targetCode)")
        ]

        guard let url = components?.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6.0
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let responseData = json["responseData"] as? [String: Any]
            else {
                return nil
            }

            var primaryText = cleanHTML(responseData["translatedText"] as? String ?? "")
            guard !primaryText.isEmpty else { return nil }

            var alternatives: [String] = []
            if let matches = json["matches"] as? [[String: Any]] {
                for m in matches {
                    if let trans = m["translation"] as? String {
                        let cleaned = cleanHTML(trans)
                        if !cleaned.isEmpty && cleaned.lowercased() != primaryText.lowercased() && !alternatives.contains(cleaned) {
                            alternatives.append(cleaned)
                        }
                    }
                }
            }

            // Post-Processing für Schulenglisch & Deutsch
            if sourceLang == .german {
                // Bei Übersetzung nach Englisch: Führendes "the " entfernen, wenn der Nutzer nur nach dem Nomen sucht
                if primaryText.lowercased().hasPrefix("the ") && !text.lowercased().hasPrefix("the ") {
                    let withoutThe = String(primaryText.dropFirst(4)).trimmingCharacters(in: .whitespaces)
                    if !withoutThe.isEmpty {
                        alternatives.insert(primaryText, at: 0)
                        primaryText = withoutThe
                    }
                }
                // Kleingeschriebenes Nomen im Englischen bevorzugen
                if primaryText.count > 1 && primaryText.first?.isUppercase == true && !text.contains(" ") {
                    let lower = primaryText.lowercased()
                    if !alternatives.contains(lower) {
                        alternatives.append(primaryText)
                        primaryText = lower
                    }
                }
            } else {
                // Bei Übersetzung nach Deutsch: Wenn ein Nomen ohne Artikel geliefert wurde,
                // prüfe ob eines der Matches einen Artikel ("der/die/das") hatte
                if !primaryText.contains(" ") {
                    if let withArticle = alternatives.first(where: {
                        let l = $0.lowercased()
                        return l.hasPrefix("der ") || l.hasPrefix("die ") || l.hasPrefix("das ")
                    }) {
                        alternatives.insert(primaryText, at: 0)
                        primaryText = withArticle
                    }
                }
            }

            return TranslationResult(
                primary: primaryText,
                alternatives: Array(alternatives.prefix(4)),
                source: .onlineInternet
            )
        } catch {
            return nil
        }
    }

    private func cleanHTML(_ str: String) -> String {
        var result = str
        if result.contains("%") {
            result = result.removingPercentEncoding ?? result
        }
        return result
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&auml;", with: "ä")
            .replacingOccurrences(of: "&ouml;", with: "ö")
            .replacingOccurrences(of: "&uuml;", with: "ü")
            .replacingOccurrences(of: "&szlig;", with: "ß")
            .replacingOccurrences(of: "&Auml;", with: "Ä")
            .replacingOccurrences(of: "&Ouml;", with: "Ö")
            .replacingOccurrences(of: "&Uuml;", with: "Ü")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalize(_ text: String) -> String {
        return text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Initialisierung des Grundschulwörterbuchs

    private func addEntry(en: String, de: String, altEn: [String] = [], altDe: [String] = []) {
        let normEn = normalize(en)
        let normDe = normalize(de)

        localEnglishToGerman[normEn] = (primary: de, alternatives: altDe)
        localGermanToEnglish[normDe] = (primary: en, alternatives: altEn)

        // Ohne Artikel indexieren
        for art in ["der ", "die ", "das "] {
            if normDe.hasPrefix(art) {
                let bareDe = String(normDe.dropFirst(art.count))
                if localGermanToEnglish[bareDe] == nil {
                    localGermanToEnglish[bareDe] = (primary: en, alternatives: altEn)
                }
            }
        }
    }

    private func buildLocalDictionary() {
        // 1. Alle Standard-Lerneinheiten aus dem Lehrplan automatisch importieren
        for unit in DefaultUnits.allUnits {
            for pair in unit.pairs {
                addEntry(en: pair.english, de: pair.german)
            }
        }

        // 2. Fundamentales Grundschul-Basisvokabular (Tiere, Schule, Farben, Zahlen, Essen, Familie, Kleidung, Freizeit)
        let coreList: [(en: String, de: String)] = [
            // Menschen, Familie & Körper
            ("girl", "das Mädchen"), ("boy", "der Junge"),
            ("mother", "die Mutter"), ("father", "der Vater"), ("mum", "die Mama"), ("dad", "der Papa"),
            ("brother", "der Bruder"), ("sister", "die Schwester"), ("baby", "das Baby"),
            ("head", "der Kopf"), ("eye", "das Auge"), ("ear", "das Ohr"), ("nose", "die Nase"),
            ("mouth", "der Mund"), ("hair", "die Haare"), ("hand", "die Hand"), ("foot", "der Fuß"),
            ("feet", "die Füße"), ("tooth", "der Zahn"), ("teeth", "die Zähne"),

            // Tiere & Natur
            ("cat", "die Katze"), ("dog", "der Hund"), ("hamster", "der Hamster"),
            ("fish", "der Fisch"), ("fish bone", "die Gräte"), ("fishbone", "die Gräte"),
            ("guinea pig", "das Meerschweinchen"), ("rabbit", "der Hase / das Kaninchen"),
            ("tortoise", "die Schildkröte"), ("mouse", "die Maus"), ("budgie", "der Wellensittich"),
            ("rat", "die Ratte"), ("pony", "das Pony"), ("spider", "die Spinne"),
            ("parrot", "der Papagei"), ("goldfish", "der Goldfisch"), ("horse", "das Pferd"),
            ("cow", "die Kuh"), ("pig", "das Schwein"), ("sheep", "das Schaf"),
            ("bird", "der Vogel"), ("birds", "die Vögel"), ("duck", "die Ente"),
            ("elephant", "der Elefant"), ("lion", "der Löwe"), ("tiger", "der Tiger"),
            ("monkey", "der Affe"), ("bear", "der Bär"), ("snake", "die Schlange"),
            ("frog", "der Frosch"), ("butterfly", "der Schmetterling"),
            ("tree", "der Baum"), ("trees", "die Bäume"), ("flower", "die Blume"),

            // Schule & Schulsachen
            ("school", "die Schule"), ("teacher", "die Lehrerin / der Lehrer"),
            ("classroom", "das Klassenzimmer"), ("desk", "der Schreibtisch / die Schulbank"),
            ("chair", "der Stuhl"), ("pencil", "der Bleistift"), ("pen", "der Stift / der Füller"),
            ("pencil case", "das Mäppchen / das Federmäppchen"), ("ruler", "das Lineal"),
            ("eraser", "der Radiergummi"), ("rubber", "der Radiergummi"),
            ("sharpener", "der Anspitzer"), ("scissors", "die Schere"), ("glue", "der Klebstoff"),
            ("book", "das Buch"), ("notebook", "das Heft"), ("bag", "die Tasche"),
            ("schoolbag", "die Schultasche / der Ranzen"), ("board", "die Tafel"),

            // Haus & Stadt
            ("house", "das Haus"), ("room", "das Zimmer"), ("kitchen", "die Küche"),
            ("door", "die Tür"), ("window", "das Fenster"), ("table", "der Tisch"),
            ("street", "die Straße"), ("town", "die Stadt"), ("car", "das Auto"),
            ("bus", "der Bus"), ("bike", "das Fahrrad"), ("train", "der Zug"),

            // Farben
            ("red", "rot"), ("blue", "blau"), ("green", "grün"), ("yellow", "gelb"),
            ("orange", "orange"), ("purple", "lila / violett"), ("pink", "rosa"),
            ("brown", "braun"), ("black", "schwarz"), ("white", "weiß"), ("grey", "grau"),

            // Zahlen 1-20
            ("one", "eins"), ("two", "zwei"), ("three", "drei"), ("four", "vier"),
            ("five", "fünf"), ("six", "sechs"), ("seven", "sieben"), ("eight", "acht"),
            ("nine", "neun"), ("ten", "zehn"), ("eleven", "elf"), ("twelve", "zwölf"),
            ("thirteen", "dreizehn"), ("fourteen", "vierzehn"), ("fifteen", "fünfzehn"),
            ("sixteen", "sechzehn"), ("seventeen", "siebzehn"), ("eighteen", "achtzehn"),
            ("nineteen", "neunzehn"), ("twenty", "zwanzig"),

            // Wochentage & Jahreszeiten
            ("Monday", "Montag"), ("Tuesday", "Dienstag"), ("Wednesday", "Mittwoch"),
            ("Thursday", "Donnerstag"), ("Friday", "Freitag"), ("Saturday", "Samstag"), ("Sunday", "Sonntag"),
            ("spring", "der Frühling"), ("summer", "der Sommer"), ("autumn", "der Herbst"), ("winter", "der Winter"),
            ("sunny", "sonnig"), ("rainy", "regnerisch"), ("windy", "windig"), ("cloudy", "bewölkt"),
            ("snowy", "verschneit"), ("hot", "heiß"), ("cold", "kalt"), ("warm", "warm"),

            // Essen & Trinken
            ("apple", "der Apfel"), ("apples", "die Äpfel"), ("banana", "die Banane"),
            ("orange", "die Orange"), ("grape", "die Traube"), ("grapes", "die Trauben"),
            ("bread", "das Brot"), ("butter", "die Butter"), ("cheese", "der Käse"),
            ("milk", "die Milch"), ("water", "das Wasser"), ("juice", "der Saft"),
            ("tea", "der Tee"), ("pizza", "die Pizza"), ("cake", "der Kuchen"),
            ("ice cream", "das Eis"), ("chocolate", "die Schokolade"), ("egg", "das Ei"),

            // Freizeit, Sport, Adjektive & Verben
            ("play", "spielen"), ("read", "lesen"), ("write", "schreiben"),
            ("sing", "singen"), ("swim", "schwimmen"), ("dance", "tanzen"),
            ("run", "laufen / rennen"), ("jump", "springen"), ("eat", "essen"), ("drink", "trinken"),
            ("sleep", "schlafen"), ("listen", "hören / zuhören"), ("speak", "sprechen"),
            ("football", "der Fußball"), ("music", "die Musik"),
            ("big", "groß"), ("small", "klein"), ("beautiful", "schön"), ("sweet", "süß")
        ]

        for item in coreList {
            addEntry(en: item.en, de: item.de)
        }
    }
}

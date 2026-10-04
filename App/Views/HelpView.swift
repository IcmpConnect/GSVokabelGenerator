import SwiftUI
import AppKit

public struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: HelpSection = .overview

    public enum HelpSection: String, CaseIterable, Identifiable {
        case overview = "Übersicht"
        case units = "Lerneinheiten"
        case editing = "Vokabeln bearbeiten"
        case spelling = "Rechtschreibprüfung"
        case printLearning = "Druck: Lernvorlage"
        case printTest = "Druck: Vokabeltest"
        case onlineTest = "Online-Test (iPad)"
        case networkHelp = "Netzwerk- & WLAN-Hilfe"
        case csv = "CSV-Import"
        case about = "Über & Lizenz"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .overview: return "star.fill"
            case .units: return "folder.fill"
            case .editing: return "pencil.line"
            case .spelling: return "text.badge.checkmark"
            case .printLearning: return "doc.text.fill"
            case .printTest: return "printer.fill"
            case .onlineTest: return "ipad.and.iphone"
            case .networkHelp: return "wifi.exclamationmark"
            case .csv: return "square.and.arrow.down.fill"
            case .about: return "info.circle.fill"
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(HelpSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.icon)
                }
            }
            .navigationTitle("Hilfe & Dokumentation")
            .frame(minWidth: 220)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    contentForSection(selectedSection)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .frame(minWidth: 780, minHeight: 560)
    }

    private var appIconImage: NSImage? {
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png", subdirectory: "Assets") {
            return NSImage(contentsOf: url)
        }
        if let direct = NSImage(contentsOfFile: "App/Resources/Assets/AppIcon.png") {
            return direct
        }
        return NSApp.applicationIconImage
    }

    @ViewBuilder
    private func contentForSection(_ section: HelpSection) -> some View {
        switch section {
        case .overview:
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 16) {
                    if let img = appIconImage {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "character.book.closed.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                    }
                    VStack(alignment: .leading) {
                        Text("GSVokabelGenerator")
                            .font(.title.bold())
                        Text("Version 1.0 • Grundschul-Vokabelverwaltung & Drucksystem")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                Text("Willkommen beim GSVokabelGenerator!")
                    .font(.title2.bold())

                Text("""
                Dieses Programm wurde speziell für Lehrkräfte an Grundschulen entwickelt, um Vokabeln für den Englischunterricht effizient zu organisieren, auf korrekte Rechtschreibung zu prüfen und didaktisch optimierte Arbeitsblätter und Vokabeltests im zweigeteilten DIN A4 Format (2x DIN A5) zu drucken.

                ### Hauptfunktionen im Überblick:
                * **10 vorinstallierte Standard-Lerneinheiten** (Class 3 & 4: Tiere, Stadt, Geburtstag, Jahreszeiten, Einkaufen, Freizeit, Gefühle, Zuhause).
                * **Direkte Bearbeitung:** Ändere jedes Wort direkt per Klick in der Tabelle.
                * **Rechtschreibprüfung in Echtzeit:** Automatische Erkennung englischer und deutscher Tippfehler inklusive Groß-/Kleinschreibung.
                * **Wörterbuch-Anbindung:** Direkter 1-Klick-Abgleich mit PONS, LEO, Cambridge Dictionary und Duden.
                * **Druckmodus 1 (Lernvorlage):** DIN A4 Querformat mit Buch-Illustration, Flaggen und Schul-/Hausaufgaben-Anweisungen.
                * **Druckmodus 2 (Vokabeltest):** Gruppe A und Gruppe B (abwechselnde Vorgaben), mit 4-stufiger Pflanzenskala (Samen bis Blüte).
                * **CSV-Import:** Flexibler Import bestehender Vokabellisten.
                """)
                .font(.body)
            }

        case .units:
            VStack(alignment: .leading, spacing: 14) {
                Text("Lerneinheiten (Units) verwalten")
                    .font(.title2.bold())

                Text("""
                Lerneinheiten fassen Vokabeln nach dem Schema `Class [Nr] Unit [Nr] [Thema]` zusammen (z. B. *Class 3 Unit 1 pets and other animals* oder unterteilte Einheiten wie *Unit 2.1* und *Unit 2.2*).

                ### Neue Unit anlegen:
                * Klicke in der Seitenleiste oben auf den **„+ Neue Unit“**-Button.
                * Passe Klasse, Unit-Nummer (auch Unterteilungen wie `2.1`, `2.2`), Thema und Abgabetag in den Feldern an.

                ### Unit duplizieren:
                * Mache einen **Rechtsklick** auf eine Unit in der Seitenleiste und wähle **„Duplizieren“**.
                * Eine vollständige Kopie aller Vokabeln wird angelegt.

                ### Unit löschen:
                Du hast drei sichere Möglichkeiten, eine Unit zu entfernen:
                1. **Rechtsklick** auf die Unit in der Seitenleiste → **„Lerneinheit löschen...“**.
                2. Klick auf den **Papierkorb-Button** in der Seitenleisten-Toolbar.
                3. Klick auf den Button **„Unit löschen...“** oben rechts in der Detailansicht.
                *Vor dem Löschen wird immer ein Bestätigungsdialog angezeigt.*

                ### Reihenfolge verändern:
                Die Reihenfolge der Lerneinheiten kann auf vier bequeme Arten verändert werden:
                1. **Drag & Drop:** Klicke eine Lerneinheit in der Seitenleiste an und ziehe sie an die gewünschte Position.
                2. **Pfeiltasten in der Toolbar:** Wähle eine Unit aus und klicke auf **„▲ Nach oben“** (⌥↑) bzw. **„▼ Nach unten“** (⌥↓).
                3. **Kontextmenü (Rechtsklick):** Mache einen Rechtsklick auf eine Lerneinheit und wähle **„Nach oben verschieben“** oder **„Nach unten verschieben“**.
                4. **Sortieren-Menü:** Klicke in der Toolbar auf das Symbol **„Sortieren“ (⇅)**, um alle Units automatisch *nach Klasse & Unit-Nummer* oder *alphabetisch nach Thema* zu ordnen.

                ### Vorlagen wiederherstellen:
                * Über das **Vorlagen-Symbol (↺)** in der Toolbar kannst du jederzeit alle 15 Original-Units ergänzen oder das Programm auf den Auslieferungszustand zurücksetzen.

                ### Lerneinheiten sichern & Backups erstellen:
                * **Sichern-Menü (Schild-Symbol):** Klicke in der Toolbar auf **„Sichern“** → **„Alle Lerneinheiten sichern (Backup)...“** (oder Tastenkürzel ⇧⌘S).
                * Wähle einen Speicherort (z. B. Schreibtisch oder USB-Stick). Eine vollständige Backup-Datei aller Units wird angelegt.
                * **Backup wiederherstellen:** Über **„Backup wiederherstellen...“** (⇧⌘O) kannst du eine gesicherte Datei laden und wählen, ob du sie mit deinen vorhandenen Units zusammenführen oder vorhandene Units ersetzen möchtest.
                * **Automatische Sicherheitskopien:** Bei jeder Änderung erstellt das Programm im Hintergrund rollierende Sicherungen. Über **„Automatische Sicherungen im Finder öffnen...“** hast du direkten Zugriff darauf.
                * **Einzelne Unit exportieren:** Mache einen Rechtsklick auf eine beliebige Unit in der Seitenleiste und wähle **„Als CSV exportieren...“**.
                """)
                .font(.body)
            }

        case .editing:
            VStack(alignment: .leading, spacing: 14) {
                Text("Vokabeln eingeben, bearbeiten & automatisch übersetzen")
                    .font(.title2.bold())

                Text("""
                ### Bestehende Vokabeln direkt in der Tabelle bearbeiten:
                * Jede Zelle in den Spalten **Englisch** und **Deutsch** ist direkt anklickbar.
                * Klicke einfach auf das gewünschte Wort und tippe deine Korrektur ein.
                * Mit der **Tab-Taste** springst du schnell von Spalte zu Spalte und Zeile zu Zeile.
                * Änderungen werden beim Tippen **sofort automatisch gespeichert**.
                * Ist eine Zelle leer, erscheint ein Zauberstab-Symbol (`✨`), mit dem du die Übersetzung sofort nachschlagen kannst!

                ### Neue Vokabeln hinzufügen & automatisch übersetzen lassen:
                * Trage unten in der Eingabeleiste die englische Vokabel oder die deutsche Übersetzung ein.
                * Wenn du nur **eine** Sprache eingibst, sucht das Programm über das Zauberstab-Symbol (`✨`) oder direkt beim Drücken von **Enter** die passende Übersetzung im Grundschulwörterbuch bzw. Internet und fügt das fertige Paar automatisch ein!

                ### Fehlende Vokabeln gesammelt suchen („Auto-Übersetzen...“):
                * Hast du eine Lerneinheit mit unvollständigen Vokabeln (z. B. aus einer CSV-Liste ohne deutsche Übersetzung), klicke oben in der Leiste auf **„Auto-Übersetzen...“**.
                * Das Programm sucht alle fehlenden Übersetzungen, zeigt dir Alternativen an und ergänzt alle Zeilen gesammelt mit einem Klick.

                ### Vokabel löschen:
                * Klicke auf das rote Papierkorb-Symbol ganz rechts in der jeweiligen Tabellenzeile.
                """)
                .font(.body)
            }

        case .spelling:
            VStack(alignment: .leading, spacing: 14) {
                Text("Rechtschreibprüfung & Wörterbuchabgleich")
                    .font(.title2.bold())

                Text("""
                Um Tippfehler auf Arbeitsblättern zuverlässig zu verhindern, verfügt die App über ein integriertes Prüfsystem:

                ### 1. Natives macOS-Wörterbuch (NSSpellChecker):
                * Prüft sowohl **britisches und amerikanisches Englisch** als auch **Deutsch**.
                * Erkennt auch fehlerhafte Kleinschreibung bei deutschen Substantiven (z. B. *„katze“* → Vorschlag: *„Katze“*).
                * Funktioniert komplett offline und ohne Wartezeiten.

                ### 2. Hinweise in der Tabelle:
                * Bei erkannten Auffälligkeiten erscheint in der Tabelle ein **⚠️-Symbol**.
                * Ein Klick auf das Symbol zeigt passende Korrekturvorschläge, die per Klick übernommen werden können.

                ### 3. Toolbar-Button „Rechtschreibung prüfen“:
                * Zeigt den aktuellen Status: `Rechtschreibung OK` oder `X Schreibhinweis(e)`.
                * Öffnet ein Sammelfenster, in dem alle Vorschläge mit einem Klick (**„Alle ersten Vorschläge anwenden“**) übernommen oder einzelne Fachbegriffe dauerhaft ignoriert werden können.

                ### 4. Direkter Online-Wörterbuchabgleich:
                * Über das Lupen-Symbol in der Spalte *„Wörterbuch“* oder in den Hinweismenüs kannst du das Wort direkt in **PONS**, **LEO**, **Cambridge Dictionary** oder dem **Duden** öffnen.
                """)
                .font(.body)
            }

        case .printLearning:
            VStack(alignment: .leading, spacing: 14) {
                Text("Druckmodus 1: Lernvorlage (DIN A4 Querformat)")
                    .font(.title2.bold())

                Text("""
                Die Lernvorlage bereitet die Vokabeln für das Vokabelheft und das Üben zu Hause vor:

                * **Format:** Exakt DIN A4 Querformat (842 × 595 pt), geteilt in zwei DIN A5 Hochformat-Hälften (421 × 595 pt).
                * **Mittelmarke:** Gestrichelte Falz- und Schneidelinie in der Blattmitte.
                * **Kopfzeile:** Buch-Illustration, Titel *„Vocabulary training“*, Klassen- und Unit-Angabe sowie Thema.
                * **Tabelle:** Großzügige, kindgerechte Zeilenhöhe mit abgerundeter Typografie.
                * **Fußbereich:** UK- und Deutschland-Flagge mit Anweisungsboxen (*Work* und *Aufgabe* bzw. *Homework* und *Hausaufgabe*).

                ### Druckoptionen:
                * **Lernblatt (Schule & Hausaufgabe):** Erzeugt 2 Seiten (Seite 1 = Unterricht, Seite 2 = Hausaufgabe).
                * **Nur Schule / Nur Hausaufgabe:** Druckt gezielt nur die gewünschte Variante mit jeweils zwei identischen A5-Hälften zum Teilen.
                """)
                .font(.body)
            }

        case .printTest:
            VStack(alignment: .leading, spacing: 14) {
                Text("Druckmodus 2: Vokabeltest (DIN A4 Hochformat)")
                    .font(.title2.bold())

                Text("""
                Der Vokabeltest dient der Leistungsüberprüfung und verhindert das Abschreiben beim Nachbarkind:

                * **Format:** DIN A4 Hochformat (595 × 842 pt), geteilt in zwei Hälften (obere und untere Hälfte für Nachbarkinder).
                * **Zwei Versionen (Gruppe A & Gruppe B):**
                  * **Gruppe A (Seite 1):** Zeile 1 Deutsch vorgegeben (Englisch zu ergänzen), Zeile 2 Englisch vorgegeben (Deutsch zu ergänzen), abwechselnd.
                  * **Gruppe B (Seite 2):** Exakt invers zu Gruppe A.
                * **Kopfbereich:** Namenszeile, Datumszeile, Unit-Titel und Gruppenbuchstabe.
                * **4-stufige Pflanzenskala (Didaktische Vorlage CHS-2):**
                  * **Stufe 1 (Samen):** *„Ich kann es noch nicht...“* (0 bis ca. 49 % der Punkte)
                  * **Stufe 2 (Keimling):** *„Einiges habe ich schon verstanden...“* (50 % bis ca. 72 %)
                  * **Stufe 3 (Pflanze):** *„Ich kann schon sehr viel...“* (73 % bis ca. 89 %)
                  * **Stufe 4 (Blüte):** *„Ich habe alles verstanden...“* (ab ca. 90 % bis 100 %)
                * **Unterschriftenzeile:** *„Ich habe ___ von N Punkten. Unterschrift: ____________“*
                """)
                .font(.body)
            }

        case .onlineTest:
            VStack(alignment: .leading, spacing: 14) {
                Text("Interaktiver Online-Test für Schüler-iPads")
                    .font(.title2.bold())

                Text("""
                Mit dem Online-Test können Schülerinnen und Schüler einen Vokabeltest direkt auf ihren iPads durchführen – ganz ohne App-Installation oder Cloud-Anbindung!

                ### So funktioniert es:
                1. **Test starten:**
                   * Wähle die gewünschte Lerneinheit aus.
                   * Klicke in der oberen Leiste auf **„Online-Test (iPad)...“** (oder per Rechtsklick auf die Unit in der Seitenleiste).
                   * Das Test-Fenster öffnet sich und startet den lokalen Server auf deinem Mac.

                2. **QR-Code anzeigen:**
                   * Auf dem Bildschirm wird ein großer QR-Code mit der lokalen Adresse deines Macbooks angezeigt.
                   * Klicke auf **„Beamer-Modus (Großbild)“**, um den QR-Code und eine kindgerechte Schritt-für-Schritt-Anleitung riesig an die Wand / das Smartboard zu projizieren.

                3. **Auf dem iPad scannen:**
                   * Die Kinder öffnen einfach die normale **Kamera-App** auf ihren iPads und scannen den QR-Code.
                   * Mit einem Fingertipp auf den gelben Safari-Hinweis öffnet sich die kinderfreundliche Test-Webseite.
                   * Die Kinder geben ihren Namen (z. B. *„Leon, 3a“*) ein und tippen auf **„Test starten 🚀“**.

                4. **Durchführung & Sofort-Auswertung:**
                   * Die Kinder beantworten Vokabel für Vokabel in großen, übersichtlichen Eingabefeldern (mit Enter zum Weiterspringen).
                   * Nach dem Absenden sehen die Kinder sofort ihr persönliches Pflanzensymbol (🌱 Samen, 🌿 Keimling, 🪴 Pflanze, 🌻 Blüte nach CHS-2), die erreichte Punktzahl und eine genaue Fehlerübersicht mit den richtigen Lösungen.

                5. **Live-Dashboard auf der Lehrerseite:**
                   * Auf deinem MacBook siehst du in Echtzeit, wer abgegeben hat, wie viele Punkte erreicht wurden und welche Vokabeln falsch waren.
                   * Über **„Ergebnisse exportieren (CSV)“** kannst du alle Resultate für Notenlisten oder Tabellenkalkulationen sichern.

                ### Begriffe mit mehreren richtigen Lösungen (/):
                * Manche Vokabeln besitzen alternative Übersetzungen oder Einzahl/Mehrzahl-Formen (z. B. `das Fest / die Party` oder `mouse / mice`).
                * **Hinweis bei der Frage auf dem iPad:** Bei solchen Begriffen wird den Kindern automatisch ein gelber Tipp angezeigt: *„💡 Für diesen Begriff gibt es mehrere richtige Lösungen. Du musst nur eine davon eingeben!“*.
                * **Tolerante & gerechte Bewertung:** Das System erkennt jede einzelne Variante als 100 % richtig an – egal ob das Kind nur eine Lösung (mit oder ohne Artikel), beide mit Schrägstrich, mit Komma oder mit „oder“ eingibt.
                * **In der Auswertung:** Hat das Kind eine der Varianten gewählt, wird die Aufgabe als richtig gewertet und die weiteren Möglichkeiten werden ermutigend als Übersicht angezeigt.

                > **Datenschutz & Netzwerk:**
                > Der Server läuft zu 100 % lokal auf deinem MacBook. Es werden keinerlei Schülerdaten ins Internet übertragen (vollständig DSGVO-konform). Wichtig: Das MacBook und die iPads müssen im selben WLAN (z. B. Schulnetz) angemeldet sein.
                """)
                .font(.body)
            }

        case .networkHelp:
            VStack(alignment: .leading, spacing: 14) {
                Text("Netzwerk- & WLAN-Hilfe (Schulnetzwerk-Troubleshooting)")
                    .font(.title2.bold())

                Text("""
                Wenn Schüler-iPads den QR-Code scannen und Safari meldet: *„Seite kann nicht geöffnet werden, da der Server nicht antwortet“*, liegt dies fast immer an den Sicherheitsregeln moderner Schul-WLANs.

                ---

                ### 1. Das Hauptproblem: „Client Isolation“ im Schul-WLAN
                * **Was ist das?** In 95 % aller Schulnetzwerke (IServ, BayernWLAN, Unifi, Lancom, Aruba) ist „Client Isolation“ aktiv. Das bedeutet: Ein iPad darf ins weltweite Internet, darf aber **unter keinen Umständen Daten mit dem MacBook daneben im selben Raum austauschen**.
                * **Wie erkenne ich das?** Klicken Sie im Online-Test-Fenster auf **„Verbindungshilfe & Troubleshooting“** und dann auf **„Auf diesem Mac im Browser testen ↗“**. Wenn die Testseite auf Ihrem Mac sofort lädt, arbeitet das Programm einwandfrei – die Schul-Firewall blockiert lediglich den Weg vom iPad zum Mac.

                ### 2. Die besten Sofortlösungen im Klassenzimmer
                * **Lösung A: Persönlicher Hotspot am Smartphone (1 Minute)**
                  * Aktivieren Sie kurz den persönlichen Hotspot auf Ihrem iPhone/Smartphone.
                  * Verbinden Sie Ihr MacBook und die Schüler-iPads mit diesem Hotspot.
                  * Da private Hotspots keine Client-Isolation besitzen, klappt die Verbindung sofort!
                * **Lösung B: Der 25 € Mini-Klassenrouter (Die dauerhafte Profi-Lösung)**
                  * Stecken Sie einen kleinen Reiserouter (z. B. *TP-Link Nano* oder *GL.iNet Mango*) in eine Steckdose im Klassenraum.
                  * Er benötigt kein Internet – er spannt einfach ein privates Klassen-WLAN auf.
                  * MacBook und iPads verbinden sich damit, blitzschnell und völlig unabhängig von Schul-IT oder Netzausfällen.

                ### 3. Anderen Port ausprobieren
                * Manche Schul-Firewalls filtern gezielt den Port `8080`.
                * Wählen Sie im Online-Test im Menü **Netzwerk-Port** einfach **Port 8000**, **Port 8888** oder **Port 3000** aus.
                * Der Server startet sofort neu und aktualisiert den QR-Code.

                ### 4. Getrennte Netze prüfen (Lehrer- vs. Schüler-WLAN)
                * Befindet sich Ihr MacBook im Netz *„Lehrer-WLAN“* und die iPads im *„Schüler-WLAN“*?
                * Die Firewall zwischen beiden Netzen blockiert meist jeglichen internen Datenverkehr.
                * **Lösung:** Beide Geräte müssen mit dem exakt selben WLAN-Namen verbunden sein.

                ### 5. macOS Berechtigung (Lokales Netzwerk)
                * Unter macOS 15 (Sequoia) muss der App die Berechtigung erteilt werden:
                * **Systemeinstellungen → Datenschutz & Sicherheit → Lokales Netzwerk → GSVokabelGenerator: Ein**.
                """)
                .font(.body)
            }

        case .csv:
            VStack(alignment: .leading, spacing: 14) {
                Text("CSV-Import & Dateiformat")
                    .font(.title2.bold())

                Text("""
                ### Vokabeln per CSV importieren:
                * Klicke auf **„CSV importieren...“** in der Toolbar.
                * Das Programm erkennt automatisch das Trennzeichen (Semikolon `;`, Komma `,` oder Tabulator `\\t`).
                * Kodierungen in UTF-8, Windows CP1252 und ISO-Latin-1 werden unterstützt.

                ### CSV-Aufbau:
                ```csv
                Englisch;Deutsch
                cat;die Katze
                dog;der Hund
                guinea pig;das Meerschweinchen
                ```

                ### Vorgefertigte Vorlagen:
                Alle 10 Standard-Units liegen als CSV-Dateien im Verzeichnis `Reference-Templates/Units-CSV/` bereit.
                """)
                .font(.body)
            }

        case .about:
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GSVokabelGenerator")
                            .font(.title.bold())
                        Text("Version 1.0 (Build 1)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Open Source • MIT License")
                            .font(.subheadline.bold())
                            .foregroundColor(.accentColor)
                    }
                }

                Divider()

                Text("""
                **GSVokabelGenerator** ist eine native macOS-Anwendung zur Erstellung und Verwaltung von Grundschul-Vokabelblättern und Vokabeltests nach pädagogischen Richtlinien.

                * **Entwickler & Autor:** Jens Schneider ([IcmpConnect](https://github.com/IcmpConnect))
                * **GitHub Repository:** [github.com/IcmpConnect/GSVokabelGenerator](https://github.com/IcmpConnect/GSVokabelGenerator)
                * **Systemanforderungen:** macOS 13.0 (Ventura) oder neuer (Universal Binary für Apple Silicon & Intel).
                * **Druckausgabe:** Vektorbasiertes PDF via CoreGraphics & PDFKit.
                * **Rechtschreibung:** macOS NSSpellChecker & Wörterbuchintegration.
                * **Datenschutz:** 100 % lokal & DSGVO-konform.

                ---

                ### Open Source Lizenz (MIT License)

                ```text
                MIT License

                Copyright (c) 2026 Jens Schneider (IcmpConnect)

                Permission is hereby granted, free of charge, to any person obtaining a copy
                of this software and associated documentation files (the "Software"), to deal
                in the Software without restriction, including without limitation the rights
                to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                copies of the Software, and to permit persons to whom the Software is
                furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all
                copies or substantial portions of the Software.

                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                SOFTWARE.
                ```
                """)
                .font(.body)

                HStack(spacing: 12) {
                    Button(action: {
                        if let url = URL(string: "https://github.com/IcmpConnect/GSVokabelGenerator") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("GitHub Repository öffnen ↗", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 4)
            }
        }
    }
}

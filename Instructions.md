# Projekt: GSVokabelGenerator (macOS SwiftUI / AppKit)

## Ziel
Erstelle eine native macOS-App zur Verwaltung von Grundschul-Vokabeln und zum Drucken von zweigeteilten DIN A4 Querformat-Seiten (2x DIN A5 nebeneinander).

## Vorlagen & Assets
Im Verzeichnis `Reference-Templates/` und `App/Resources/Assets/` liegen:
1. `Original-Lernvorlage.pdf` (Referenz für das Lernblatt) sowie `Original-Lernvorlage.png`
2. `CHS-2.pdf` (Pflanzensymbole für die Bewertung im Test) sowie extrahierte PNG-Seiten
3. `Beispieldaten.csv`

## Maße & Layout-Vorgaben
- **Seitengröße:** DIN A4 Querformat = 842 × 595 pt
- **Zweiteilung:** 2x DIN A5 Hochformat (jeweils 421 × 595 pt) nebeneinander mit vertikaler Trennlinie / Falz- bzw. Schnittmarke.
- **Typografie:** Kindgerechte, klare Schrift (z. B. Comic Sans MS, Chalkboard SE, Noteworthy oder SF Pro Rounded).
- **Tabellenlayout:** Zweispaltig (Englisch links, Deutsch rechts), abwechselnde oder klare Zeilenführung mit ausreichend Zeilenhöhe für Grundschüler-Handschrift.

## Anforderungen

1. **Datenmodell & Import:**
   - Verwaltung nach Schema: `Class [Nr] Unit [Nr] [Thema]` (z. B. "Class 3 Unit 1 pets and other animals").
   - CSV-Import (Spalten: Englisch, Deutsch) sowie manuelle Bearbeitung / Hinzufügen / Löschen im UI.
   - Lokale Speicherung der Units (z. B. JSON im Application Support Ordner).

2. **Druckmodus 1 – Lernvorlage (DIN A4 Querformat):**
   - Teilt das Blatt exakt in zwei DIN A5 Hälften (links und rechts identisch oder Seite 1 / Seite 2 wählbar).
   - Oben: Kopfzeile mit Illustration (Buch), Titel ("Vocabulary training"), Unit-Nummer und Thema.
   - Mitte: Zweispaltige Vokabelliste (Englisch / Deutsch).
   - Unten: Flaggen- und Anweisungskästchen (Work / Aufgabe bzw. Homework / Hausaufgabe) wie in `Original-Lernvorlage.pdf`.

3. **Druckmodus 2 – Vokabeltest (DIN A4 Querformat):**
   - Der untere Bereich (Flaggen) wird durch die Pflanzensymbolik aus `CHS-2.pdf` ersetzt.
   - Dynamisches Bewertungsschema basierend auf Gesamtanzahl N der Vokabeln (1 Punkt pro Vokabel, transparente Schwellenwerte).
   - Blatt 1 (Gruppe A): Zeile 1 = Deutsch vorgegeben (Englisch fehlt), Zeile 2 = Englisch vorgegeben (Deutsch fehlt), abwechselnd.
   - Blatt 2 (Gruppe B): Exakt invers zu Gruppe A.
   - Auch hier jeweils 2x A5 pro A4-Seite zum Teilen für Nachbarkinder.

4. **Mathematische Punkte- & Notenskala für N Vokabeln:**
   Basierend auf der didaktischen Vorlage aus `CHS-2.pdf` (4 Stufen: Samen, Keimling, Pflanze, Blüte):
   - **Stufe 1 (Samen – „Ich kann es noch nicht...“):** `0` bis `(N - 1) / 2` Punkte (ca. 0 – 49 %)
   - **Stufe 2 (Keimling – „Einiges habe ich schon verstanden...“):** `N / 2` bis ca. `72 %` der Gesamtpunkte
   - **Stufe 3 (Pflanze – „Ich kann schon sehr viel...“):** ca. `73 %` bis `89 %` der Gesamtpunkte
   - **Stufe 4 (Blüte – „Ich habe alles verstanden...“):** ab ca. `90 %` bis `N` Punkte
   - Punkteangabe: „Ich habe ___ von N Punkten. Unterschrift: ____________“

5. **PDF-Generierung:**
   - Nutze `PDFKit` und CoreGraphics zur Erzeugung einer druckfähigen Vektor-PDF mit exakt 842 x 595 pt pro Seite.

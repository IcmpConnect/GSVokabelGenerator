# GSVokabelGenerator

<p align="center">
  <b>Native macOS Desktop-Applikation zur didaktischen Vokabelverwaltung, Erstellung von Druckvorlagen (Lernblätter & Tests) und Durchführung interaktiver iPad-Online-Tests an Grundschulen.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013.0%2B-blue?style=flat-square&logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Language-Swift%205.9%2B-orange?style=flat-square&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%7C%20AppKit-cyan?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline%20%2F%20DSGVO-success?style=flat-square" alt="DSGVO-konform">
</p>

---

## 🌟 Highlights & Funktionen

Der **GSVokabelGenerator** wurde speziell für Lehrkräfte an Grundschulen im Fach Englisch entwickelt. Er kombiniert ein strukturiertes Vokabel-Management mit automatischer Fehlerkontrolle, professioneller Druckausgabe im zweigeteilten DIN A4-Format und einem kinderleichten iPad-Klassenzimmer-Test.

### 1. 🖨️ Druckmodus 1: Lernvorlage (DIN A4 Querformat)
* **Zweigeteilt:** Exakt in der Mitte mit gestrichelter Schneidelinie für **2× DIN A5 Hochformat** nebeneinander.
* **Layout:** Buch-Illustration, Titel *„Vocabulary training“*, Klasse, Unit-Nummer und Fristangabe.
* **Vokabelliste:** Zweispaltig (Englisch / Deutsch) mit optimaler Zeilenhöhe für Grundschüler-Handschrift.
* **Aufgabenkästchen:** Mit UK- und Deutschland-Flaggen für Unterrichtsaufgaben (*Work*) und Hausaufgaben (*Homework*).
* **Optionen:** Wahlweise als 2-seitiges Blatt (Schule & Hausaufgabe) oder 1 Seite mit 2 identischen A5-Hälften zum Teilen.

### 2. 📝 Druckmodus 2: Vokabeltest (DIN A4 Hochformat)
* **Gruppe A & Gruppe B:** Verhindert das Abschreiben beim Nachbarkind.
  * *Gruppe A:* Zeile 1 Deutsch vorgegeben (Englisch ergänzen), Zeile 2 Englisch vorgegeben (Deutsch ergänzen), abwechselnd.
  * *Gruppe B:* Exakt invers zu Gruppe A.
* **Pflanzensymbol-Bewertung (Pädagogische Vorlage CHS-2):**
  Dynamische Punkte- und Notenskala für jede beliebige Vokabelanzahl *N*:
  * 🌱 **Stufe 1 (Samen):** *„Ich kann es noch nicht...“* (0 bis ca. 49 % der Punkte)
  * 🌿 **Stufe 2 (Keimling):** *„Einiges habe ich schon verstanden...“* (50 % bis ca. 72 %)
  * 🪴 **Stufe 3 (Pflanze):** *„Ich kann schon sehr viel...“* (73 % bis ca. 89 %)
  * 🌻 **Stufe 4 (Blüte):** *„Ich habe alles verstanden...“* (ab ca. 90 % bis 100 %)
  * Unterschriften- und Punktezeile: *„Ich habe ___ von N Punkten. Unterschrift: ____________“*

### 3. 📱 Interaktiver Online-Test für Schüler-iPads
* **Ohne App-Installation & Ohne Internet:** Das MacBook fungiert als lokaler Webserver im Klassenzimmer.
* **QR-Code & Beamer-Modus:** Großbild-Projektion des QR-Codes inklusive kinderfreundlicher Anleitung für Beamer / Smartboard.
* **Einfache Teilnahme:** Schüler scannen den QR-Code mit der normalen iPad-Kamera und Safari öffnet sofort den Test.
* **Kindgerechte Oberfläche:** Große Eingabefelder, automatische Fokussierung, Enter-Weiterspringen und motivierende Icons.
* **Tolerante Auswertung bei Mehrfachlösungen (`/`):** Erkennt Synonyme oder Einzahl/Mehrzahl (z. B. `das Fest / die Party`) zuverlässig an.
* **Live-Lehrer-Dashboard:** Zeigt in Echtzeit eingehende Abgaben, Durchschnittswerte, erreichte Punkte und Fehlereinzelsichten.
* **CSV-Export:** Vollständiger Excel-kompatibler Export aller Testergebnisse.
* **Schulnetzwerk-Troubleshooting:** Integriertes Hilfesystem mit Schnelltest, Port-Umschaltung (8000, 8080, 8888, 3000) und Client-Isolation-Ratgeber.

### 4. ✨ Smarte Vokabel-Eingabe & Rechtschreibprüfung
* **Echtzeit-Korrekturprüfung (`NSSpellChecker`):** Prüft britisches/amerikanisches Englisch und Deutsch (inkl. Groß-/Kleinschreibung und Umlauten).
* **Auto-Übersetzung:** Erkennt eingegebene Wörter und schlägt automatisch die passende deutsche oder englische Übersetzung vor.
* **Wörterbuchabgleich:** 1-Klick-Suche in PONS, LEO, Cambridge Dictionary und Duden.

### 5. 📂 Datenverwaltung & Vorlagen
* **10 vorinstallierte Einheiten:** Passend zum Grundschullehrplan Klasse 3 und 4 (*Animals, In town, Birthday, The year, Shopping, Free time, Feelings, At home* etc.).
* **CSV-Import & Export:** Flexible Erkennung von Trennzeichen (`;`, `,`, Tabulator) und Zeichensätzen.
* **Lokale Sicherung:** Automatische Speicherung im macOS Application Support Verzeichnis.

---

## 🔒 Datenschutz & Sicherheit (100 % DSGVO-konform)

* **Kein Cloud-Zwang:** Das Programm läuft vollständig lokal auf Ihrem Mac.
* **Keine Schülerdaten im Web:** Beim iPad-Test werden alle Daten ausschließlich im lokalen Netzwerk zwischen Schüler-iPad und Lehrer-MacBook übertragen.
* **Kein Tracking:** Keine Analyse-Dienste, keine Werbe-Tracker, keine Benutzerkonten.

---

## 💻 Systemanforderungen

* **Betriebssystem:** macOS 13.0 (Ventura) oder neuer (inkl. macOS 14 Sonoma und macOS 15 Sequoia).
* **Hardware:** Native Unterstützung für Apple Silicon (M1, M2, M3, M4) sowie Intel-Prozessoren (Universal Binary).

---

## 🚀 Installation & Start

1. Laden Sie die aktuelle Version unter [Releases](https://github.com/IcmpConnect/GSVokabelGenerator/releases) herunter (`GSVokabelGenerator-1.0.dmg`).
2. Öffnen Sie die `.dmg`-Datei per Doppelklick.
3. Ziehen Sie das Symbol **GSVokabelGenerator** in Ihren Ordner **Programme**.
4. Starten Sie das Programm.

### Aus dem Quellcode kompilieren (für Entwickler):

```bash
# Repository klonen
git clone https://github.com/IcmpConnect/GSVokabelGenerator.git
cd GSVokabelGenerator

# Im Debug-Modus bauen & ausführen
swift run

# Release-App erzeugen
bash scripts/package_release.sh
```

---

## 📄 Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert. Weitere Details finden Sie in der Datei [LICENSE](LICENSE).

Copyright © 2026 Jens Schneider ([IcmpConnect](https://github.com/IcmpConnect)). Alle Rechte vorbehalten.

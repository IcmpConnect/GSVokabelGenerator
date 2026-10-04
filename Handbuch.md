# GSVokabelGenerator • Benutzerhandbuch & Dokumentation

**Version:** 1.0 (Build 1)  
**Copyright:** © 2026 Jens Schneider. Alle Rechte vorbehalten.  
**Plattform:** macOS 13.0 (Ventura) oder neuer (Apple Silicon & Intel)

---

## Inhaltsverzeichnis
1. [Über das Programm](#1-über-das-programm)
2. [Installation & Erste Schritte](#2-installation--erste-schritte)
3. [Lerneinheiten (Units) verwalten](#3-lerneinheiten-units-verwalten)
4. [Vokabeln eingeben & direkt bearbeiten](#4-vokabeln-eingeben--direkt-bearbeiten)
5. [Rechtschreibprüfung & Wörterbuchabgleich](#5-rechtschreibprüfung--wörterbuchabgleich)
6. [Druckmodus 1: Lernvorlage (DIN A4 Querformat)](#6-druckmodus-1-lernvorlage-din-a4-querformat)
7. [Druckmodus 2: Vokabeltest (DIN A4 Hochformat)](#7-druckmodus-2-vokabeltest-din-a4-hochformat)
8. [Interaktiver Online-Test für Schüler-iPads](#8-interaktiver-online-test-für-schüler-ipads)
9. [CSV-Import & Datenablage](#9-csv-import--datenablage)
10. [Lizenz & Copyright](#10-lizenz--copyright)

---

## 1. Über das Programm

Der **GSVokabelGenerator** ist eine maßgeschneiderte, native macOS-Applikation für Lehrkräfte an Grundschulen. Sie unterstützt Sie bei der Organisation von Vokabeln im Fach Englisch, verhindert Rechtschreib- und Grammatikfehler durch eine mehrstufige Echtzeitprüfung und erzeugt druckoptimierte Vektor-PDF-Dokumente im geteilten DIN A4 Format (2x DIN A5).

---

## 2. Installation & Erste Schritte

### Auf einem neuen Mac installieren:
1. Öffnen Sie die Datei **`GSVokabelGenerator-1.0.dmg`** per Doppelklick.
2. Ziehen Sie das Programmsymbol **GSVokabelGenerator** einfach in den daneben angezeigten Ordner **Programme** (*Applications*).
3. Starten Sie das Programm anschließend aus Ihrem Programme-Ordner oder über Spotlight / Launchpad.

---

## 3. Lerneinheiten (Units) verwalten

Die linke Seitenleiste listet alle vorhandenen Lerneinheiten nach Klasse, Unit-Nummer und Thema auf.

* **10 vorinstallierte Einheiten:**
  * Class 3 Unit 1: pets and other animals
  * Class 3 Unit 2: In town (part 1)
  * Class 3 Unit 2: In town (part 2)
  * Class 3 Unit 3: Birthday
  * Class 4 Unit 3: The year
  * Class 4 Unit 4: Shopping
  * Class 3 Unit 5: Free time (part 1)
  * Class 3 Unit 5: Free time (part 2)
  * Class 3 Unit 6: Feelings
  * Class 3 Unit 8: At home

* **Neue Lerneinheit anlegen:**
  Klicken Sie oben in der Seitenleiste auf **`+ Neue Unit`**.
* **Lerneinheit duplizieren:**
  Rechtsklick auf die gewünschte Einheit in der Seitenleiste → **`Duplizieren`**.
* **Lerneinheit löschen:**
  * Per Rechtsklick auf die Einheit → **`Lerneinheit löschen...`**
  * Oder über das rote Papierkorb-Symbol in der Symbolleiste bzw. oben rechts im Kopfbereich der Unit.
  * Eine Sicherheitsabfrage verhindert versehentliches Löschen.
* **Reihenfolge der Lerneinheiten anpassen:**
  * **Drag & Drop:** Klicken Sie eine Lerneinheit in der Seitenleiste an und ziehen Sie sie mit der Maus an die gewünschte Stelle.
  * **Pfeil-Buttons:** Wählen Sie eine Lerneinheit aus und klicken Sie in der Symbolleiste auf **`▲ Nach oben`** (Tastenkürzel: `⌥↑`) oder **`▼ Nach unten`** (`⌥↓`).
  * **Kontextmenü (Rechtsklick):** Über einen Rechtsklick auf eine Einheit kann diese direkt um eine Position nach oben oder unten verschoben werden.
  * **Sortierfunktion:** Über das Symbol **`⇅ Sortieren`** in der Symbolleiste können alle Einheiten automatisch *nach Klasse & Unit-Nummer* oder *alphabetisch nach Thema* geordnet werden.
* **Vorlagen wiederherstellen:**
  Über das Symbol **`↺`** in der Symbolleiste können alle 10 Vorlagen-Einheiten jederzeit neu geladen oder ergänzt werden.

---

## 4. Vokabeln eingeben, bearbeiten & automatisch übersetzen lassen

* **Bestehende Vokabeln bearbeiten:**
  Klicken Sie einfach in die gewünschte Tabellenzelle in der Spalte **Englisch** oder **Deutsch**. Die Zelle ist direkt editierbar. Mit der **Tab-Taste** springen Sie bequem zur nächsten Zelle. Alle Änderungen werden sofort gespeichert.
* **Neue Vokabel hinzufügen (mit Auto-Übersetzung):**
  * Geben Sie am unteren Rand das englische oder deutsche Wort ein.
  * Wenn Sie nur **eine** Sprache eingeben (z. B. nur das deutsche oder englische Wort), sucht das Programm über das Zauberstab-Symbol (`✨`) oder direkt beim Drücken von **Enter / Hinzufügen** die fehlende Übersetzung im Grundschulwörterbuch bzw. Internet und trägt sie automatisch ein!
* **Fehlende Vokabeln gesammelt suchen (`Auto-Übersetzen...`):**
  * Haben Sie eine Vokabelliste mit Lücken (z. B. per CSV importiert oder unvollständig eingegeben), klicken Sie in der Leiste oben auf **`Auto-Übersetzen...`**.
  * Das Programm durchsucht das Grundschulvokabular und Online-Quellen (MyMemory), zeigt Ihnen gefundene Übersetzungen und Alternativen in einer Übersicht an und übernimmt alle fehlenden Einträge mit einem Klick.
* **Vokabel löschen:**
  Klicken Sie auf den roten Papierkorb ganz rechts in der Tabellenzeile.

---

## 5. Rechtschreibprüfung & Wörterbuchabgleich

Um Schreibfehler auf Lern- und Testbögen zuverlässig auszuschließen, prüft das Programm alle Eingaben kontinuierlich:

* **Natives macOS Wörterbuch (`NSSpellChecker`):**
  Prüft britisches und amerikanisches Englisch sowie Deutsch (inklusive Groß-/Kleinschreibung bei Nomen und Umlauten).
* **Live-Hinweise bei der Eingabe:**
  Wird während des Tippens ein unbekanntes oder falsch geschriebenes Wort erkannt, erscheint darunter sofort ein Korrekturhinweis mit einem Klick zur Übernahme.
* **Warnsymbol `⚠️` in der Tabelle:**
  Zeigt Auffälligkeiten pro Zeile. Ein Klick darauf bietet sofortige Korrekturvorschläge.
* **Sammelprüfung (`Rechtschreibung prüfen`):**
  Der Button in der Toolbar öffnet das Prüffenster mit der Möglichkeit, alle ersten Vorschläge gesammelt zu übernehmen oder schulinterne Begriffe dauerhaft zu ignorieren.
* **Direktabgleich mit Online-Wörterbüchern:**
  Über das Lupen-Symbol können Wörter direkt in **PONS**, **LEO**, **Cambridge Dictionary** oder dem **Duden** aufgerufen werden.

---

## 6. Druckmodus 1: Lernvorlage (DIN A4 Querformat)

* **Layout:** DIN A4 Querformat (842 × 595 pt), exakt in der Mitte durch eine gestrichelte Schneidelinie in zwei identische DIN A5 Hochformat-Hälften (421 × 595 pt) getrennt.
* **Inhalt:**
  * Oben: Buch-Illustration, Titel *„Vocabulary training“*, Klasse, Unit und Frist.
  * Mitte: Großzügige, zweispaltige Vokabelliste.
  * Unten: UK- und Deutschland-Flaggen mit den Aufgabenboxen (*Work / Aufgabe* für den Unterricht bzw. *Homework / Hausaufgabe*).
* **Optionen:**
  * *Lernblatt (Schule & Hausaufgabe)*: Erzeugt ein 2-seitiges PDF.
  * *Lernblatt (nur Schule / nur Hausaufgabe)*: Erzeugt 1 Seite mit 2 identischen A5-Hälften zum Teilen.

---

## 7. Druckmodus 2: Vokabeltest (DIN A4 Hochformat)

* **Layout:** DIN A4 Hochformat (595 × 842 pt), zweigeteilt für Nachbarkinder.
* **Versionen (Gruppe A & Gruppe B):**
  * **Gruppe A (Seite 1):** Zeile 1 Deutsch vorgegeben (Englisch ergänzen), Zeile 2 Englisch vorgegeben (Deutsch ergänzen), abwechselnd.
  * **Gruppe B (Seite 2):** Exakt invers zu Gruppe A.
* **Pflanzensymbol-Bewertung (Vorlage CHS-2):**
  Dynamische Punkte- und Notenskala für die Gesamtzahl *N* der Vokabeln:
  * **Stufe 1 (Samen):** *„Ich kann es noch nicht...“* (0 bis ca. 49 % der Punkte)
  * **Stufe 2 (Keimling):** *„Einiges habe ich schon verstanden...“* (50 % bis ca. 72 %)
  * **Stufe 3 (Pflanze):** *„Ich kann schon sehr viel...“* (73 % bis ca. 89 %)
  * **Stufe 4 (Blüte):** *„Ich habe alles verstanden...“* (ab ca. 90 % bis 100 %)
  * Unterschrift- und Punktezeile: *„Ich habe ___ von N Punkten. Unterschrift: ____________“*

---

## 8. Interaktiver Online-Test für Schüler-iPads

Mit dem Online-Test können Schülerinnen und Schüler einen Vokabeltest direkt auf ihren iPads durchführen – ganz ohne App-Installation oder Cloud-Anbindung! Ihr MacBook fungiert dabei als lokaler Server im Klassenzimmer.

### Ablauf Schritt für Schritt:
1. **Online-Test starten:**
   * Wählen Sie die gewünschte Lerneinheit aus.
   * Klicken Sie oben auf den Button **`Online-Test (iPad)...`** (oder per Rechtsklick auf die Unit in der linken Liste).
   * Das Übersichtsfenster öffnet sich und der integrierte, sichere Server startet automatisch auf Ihrem Mac.
2. **Großen QR-Code anzeigen (Beamer-Modus):**
   * Auf Ihrem Bildschirm wird ein QR-Code mit der lokalen Adresse Ihres MacBooks angezeigt.
   * Klicken Sie auf **`Beamer-Modus (Großbild)`**, um den QR-Code zusammen mit einer großen Schritt-für-Schritt-Anleitung für die Klasse über den Beamer oder das Smartboard anzuzeigen.
3. **Auf dem iPad scannen & durchführen:**
   * Die Kinder öffnen einfach die vorinstallierte **Kamera-App** auf ihren iPads und richten sie auf den QR-Code.
   * Mit einem Fingertipp auf den gelben Safari-Hinweis öffnet sich die kinderfreundliche Test-Seite.
   * Schüler geben ihren Namen ein (z. B. *„Leon, 3a“*) und tippen auf **„Test starten 🚀“**.
   * Die Vokabeln werden nacheinander in großen Eingabefeldern abgefragt (bequemes Weiterspringen mit Enter).
4. **Sofortige Schülerauswertung:**
   * Direkt nach dem Absenden sehen die Kinder ihr individuelles Pflanzensymbol (🌱 Samen, 🌿 Keimling, 🪴 Pflanze, 🌻 Blüte nach Vorlage CHS-2), die erreichte Punktzahl und eine übersichtliche Fehlerauswertung mit den richtigen Lösungen.
5. **Live-Lehrer-Dashboard & CSV-Export:**
   * Auf Ihrem MacBook laufen alle eingereichten Tests in Echtzeit ein.
   * Sie sehen auf einen Blick den Durchschnitt, die erreichten Punkte jedes Kindes und können jede Abgabe aufklappen, um gezielte Tippfehler einzusehen.
   * Mit einem Klick auf **`Ergebnisse exportieren (CSV)`** sichern Sie die gesamte Auswertung als Excel-kompatible Datei.

> **Datenschutz & Netzwerk-Hinweis:**
> Der Test läuft zu 100 % lokal auf Ihrem MacBook. Es werden zu keinem Zeitpunkt Daten ins Internet übertragen (DSGVO-konform). Das MacBook und die Schüler-iPads müssen sich lediglich im selben lokalen Netzwerk (z. B. Schul-WLAN oder persönlicher Hotspot) befinden.

---

## 9. CSV-Import & Datenablage

* **CSV-Import:** Über den Button **`CSV importieren...`** können bestehende Tabellen mit Semikolon (`;`), Komma (`,`) oder Tabulator (`\t`) eingelesen werden.
* **Automatische Speicherung:** Alle Lerneinheiten werden automatisch im geschützten Benutzerverzeichnis abgelegt:  
  `~/Library/Application Support/GSVokabelGenerator/units.json`

---

## 10. Lizenz & Open Source

**GSVokabelGenerator • Version 1.0**  
Lizenziert unter der **MIT-Lizenz**.  
Copyright © 2026 Jens Schneider ([IcmpConnect](https://github.com/IcmpConnect)). Alle Rechte vorbehalten.  

GitHub Repository: [https://github.com/IcmpConnect/GSVokabelGenerator](https://github.com/IcmpConnect/GSVokabelGenerator)

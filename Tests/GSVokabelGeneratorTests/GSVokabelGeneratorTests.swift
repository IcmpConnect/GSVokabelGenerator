import XCTest
import PDFKit
@testable import GSVokabelGenerator

final class GSVokabelGeneratorTests: XCTestCase {

    func testGradingScaleCalculation() {
        let scale15 = GradingScale(totalPoints: 15)
        XCTAssertEqual(scale15.thresholds.count, 4)
        XCTAssertEqual(scale15.thresholds[0].rangeString, "0-7")
        XCTAssertEqual(scale15.thresholds[1].rangeString, "7,5-11")
        XCTAssertEqual(scale15.thresholds[2].rangeString, "11,5-13")
        XCTAssertEqual(scale15.thresholds[3].rangeString, "13,5-15")

        let scale9 = GradingScale(totalPoints: 9)
        XCTAssertEqual(scale9.thresholds[0].rangeString, "0-4")
        XCTAssertEqual(scale9.thresholds[1].rangeString, "4,5-6")
        XCTAssertEqual(scale9.thresholds[2].rangeString, "6,5-8")
        XCTAssertEqual(scale9.thresholds[3].rangeString, "8,5-9")
    }

    func testCSVImporter() {
        let sampleCSV = """
        Englisch;Deutsch
        cat;die Katze
        dog;der Hund
        fish;der Fisch
        """
        let pairs = CSVImporter.parse(string: sampleCSV)
        XCTAssertEqual(pairs.count, 3)
        XCTAssertEqual(pairs[0].english, "cat")
        XCTAssertEqual(pairs[0].german, "die Katze")
        XCTAssertEqual(pairs[1].english, "dog")
        XCTAssertEqual(pairs[1].german, "der Hund")
    }

    func testPDFGenerationDimensionsAndPages() {
        let pairs = [
            VocabularyPair(english: "cat", german: "die Katze"),
            VocabularyPair(english: "dog", german: "der Hund")
        ]
        let unit = VocabularyUnit(
            classNumber: 3,
            unitNumber: 1,
            title: "Test Unit",
            pairs: pairs
        )

        // 1. Lernvorlage (DIN A4 Querformat: 842 x 595)
        let learnData = PDFGenerator.generatePDF(for: unit, mode: .learningSheetBothPages)
        XCTAssertFalse(learnData.isEmpty)
        let learnDoc = PDFDocument(data: learnData)
        XCTAssertNotNil(learnDoc)
        XCTAssertEqual(learnDoc?.pageCount, 2)
        if let p = learnDoc?.page(at: 0) {
            let box = p.bounds(for: .mediaBox)
            XCTAssertEqual(box.width, 842.0)
            XCTAssertEqual(box.height, 595.0)
        }

        // 2. Vokabeltest (DIN A4 Hochformat: 595 x 842 pt, 2 Seiten: Seite 1 = Version A, Seite 2 = Version B)
        let testData = PDFGenerator.generatePDF(for: unit, mode: .vocabularyTest(promptMode: .alternating, includeBothGroups: true))
        XCTAssertFalse(testData.isEmpty)
        let testDoc = PDFDocument(data: testData)
        XCTAssertNotNil(testDoc)
        XCTAssertEqual(testDoc?.pageCount, 2)
        if let p1 = testDoc?.page(at: 0) {
            let box1 = p1.bounds(for: .mediaBox)
            XCTAssertEqual(box1.width, 595.0)
            XCTAssertEqual(box1.height, 842.0)
        }
        if let p2 = testDoc?.page(at: 1) {
            let box2 = p2.bounds(for: .mediaBox)
            XCTAssertEqual(box2.width, 595.0)
            XCTAssertEqual(box2.height, 842.0)
        }

        // 3. Vokabeltest nur Deutsch vorgegeben
        let gerData = PDFGenerator.generatePDF(for: unit, mode: .vocabularyTest(promptMode: .germanOnly, includeBothGroups: true))
        XCTAssertFalse(gerData.isEmpty)
        let gerDoc = PDFDocument(data: gerData)
        XCTAssertEqual(gerDoc?.pageCount, 2)

        // 4. Vokabeltest nur Englisch vorgegeben
        let engData = PDFGenerator.generatePDF(for: unit, mode: .vocabularyTest(promptMode: .englishOnly, includeBothGroups: false))
        XCTAssertFalse(engData.isEmpty)
        let engDoc = PDFDocument(data: engData)
        XCTAssertEqual(engDoc?.pageCount, 1)
    }

    func testDefaultUnitsLoaded() {
        let units = DefaultUnits.allUnits
        XCTAssertEqual(units.count, 10)
        let titles = units.map(\.title)
        XCTAssertTrue(titles.contains("pets and other animals"))
        XCTAssertTrue(titles.contains("In town (part 1)"))
        XCTAssertTrue(titles.contains("In town (part 2)"))
        XCTAssertTrue(titles.contains("Birthday"))
        XCTAssertTrue(titles.contains("The year"))
        XCTAssertTrue(titles.contains("Shopping"))
        XCTAssertTrue(titles.contains("Free time (part 1)"))
        XCTAssertTrue(titles.contains("Free time (part 2)"))
        XCTAssertTrue(titles.contains("Feelings"))
        XCTAssertTrue(titles.contains("At home"))

        for unit in units {
            XCTAssertFalse(unit.pairs.isEmpty)
        }
    }

    func testSpellingCheckerDetectionAndSuggestions() {
        let checker = VocabularySpellChecker.shared

        // 1. Englischer Tippfehler
        let engIssues = checker.checkText("autum", language: .english)
        XCTAssertFalse(engIssues.isEmpty)
        XCTAssertEqual(engIssues.first?.word, "autum")
        XCTAssertTrue(engIssues.first?.suggestions.contains("autumn") ?? false)

        // 2. Gültiges Englisch
        let engValid = checker.checkText("autumn", language: .english)
        XCTAssertTrue(engValid.isEmpty)

        // 3. Deutsches Substantiv kleingeschrieben
        let gerIssues = checker.checkText("katze", language: .german)
        XCTAssertFalse(gerIssues.isEmpty)
        XCTAssertEqual(gerIssues.first?.word, "katze")
        XCTAssertTrue(gerIssues.first?.suggestions.contains("Katze") ?? false)

        // 4. Gültiges Deutsch mit Umlauten
        let gerValid = checker.checkText("das Meerschweinchen", language: .german)
        XCTAssertTrue(gerValid.isEmpty)

        // 5. Wort-Ersetzung
        let replaced = checker.replaceWord(in: "autum and summer", wordToReplace: "autum", with: "autumn")
        XCTAssertEqual(replaced, "autumn and summer")
    }

    func testOnlineDictionaryURLs() {
        let pons = OnlineDictionaryService.ponsURL(for: "hamster")
        XCTAssertNotNil(pons)
        XCTAssertTrue(pons!.absoluteString.contains("pons.com"))

        let leo = OnlineDictionaryService.leoURL(for: "dog")
        XCTAssertNotNil(leo)
        XCTAssertTrue(leo!.absoluteString.contains("dict.leo.org"))

        let duden = OnlineDictionaryService.dudenURL(for: "Katze")
        XCTAssertNotNil(duden)
        XCTAssertTrue(duden!.absoluteString.contains("duden.de"))
    }

    func testVocabularyTranslationService() async {
        let service = VocabularyTranslationService.shared

        // 1. Lokales Wörterbuch: English -> Deutsch
        let resDog = await service.translate(text: "dog", from: .english)
        XCTAssertEqual(resDog.primary, "der Hund")
        XCTAssertEqual(resDog.source, .localDictionary)

        // 2. Lokales Wörterbuch: Deutsch -> English
        let resCat = await service.translate(text: "die Katze", from: .german)
        XCTAssertEqual(resCat.primary.lowercased(), "cat")
        XCTAssertEqual(resCat.source, .localDictionary)

        // 3. Unvollständiges Vokabelpaar ergänzen
        let incompletePair = VocabularyPair(english: "apple", german: "")
        let completed = await service.completePair(incompletePair)
        XCTAssertEqual(completed.english, "apple")
        XCTAssertEqual(completed.german, "der Apfel")
    }

    @MainActor
    func testUnitReorderingAndSorting() {
        let store = UnitStore()
        
        let unitA = VocabularyUnit(classNumber: 4, unitNumber: 2, title: "Zebra", deadlineDay: "Montag", pairs: [])
        let unitB = VocabularyUnit(classNumber: 3, unitNumber: 1, title: "Apple", deadlineDay: "Dienstag", pairs: [])
        let unitC = VocabularyUnit(classNumber: 3, unitNumber: 2, title: "Banana", deadlineDay: "Mittwoch", pairs: [])
        
        store.units = [unitA, unitB, unitC]
        XCTAssertEqual(store.units.map(\.title), ["Zebra", "Apple", "Banana"])
        
        // 1. Move Down
        XCTAssertTrue(store.canMoveDown(id: unitA.id))
        XCTAssertFalse(store.canMoveUp(id: unitA.id))
        store.moveUnitDown(id: unitA.id)
        XCTAssertEqual(store.units.map(\.title), ["Apple", "Zebra", "Banana"])
        
        // 2. Move Up
        XCTAssertTrue(store.canMoveUp(id: unitA.id))
        store.moveUnitUp(id: unitA.id)
        XCTAssertEqual(store.units.map(\.title), ["Zebra", "Apple", "Banana"])
        
        // 3. Move from index to index
        store.moveUnit(fromIndex: 0, toIndex: 2)
        XCTAssertEqual(store.units.map(\.title), ["Apple", "Banana", "Zebra"])
        
        // 4. Sort by Unit Number (Class 3 first, then Class 4)
        store.units = [unitA, unitC, unitB]
        store.sortByUnitNumber()
        XCTAssertEqual(store.units.map(\.title), ["Apple", "Banana", "Zebra"])
        XCTAssertEqual(store.units.map(\.unitNumber), [1, 2, 2])
        XCTAssertEqual(store.units.map(\.classNumber), [3, 3, 4])
        
        // 5. Sort by Title
        store.units = [unitC, unitA, unitB]
        store.sortByTitle()
        XCTAssertEqual(store.units.map(\.title), ["Apple", "Banana", "Zebra"])
    }
}

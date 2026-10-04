import Foundation
import AppKit
import PDFKit
import CoreGraphics

public enum TestPromptMode: String, CaseIterable, Identifiable {
    case alternating = "Abwechselnd (Gruppe A & B invers)"
    case germanOnly = "Nur Deutsch vorgegeben (Englisch fehlt)"
    case englishOnly = "Nur Englisch vorgegeben (Deutsch fehlt)"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .alternating: return "Abwechselnd"
        case .germanOnly: return "Nur Deutsch"
        case .englishOnly: return "Nur Englisch"
        }
    }
}

public enum PDFPrintMode {
    case learningSheet(isHomework: Bool)
    case learningSheetBothPages
    case vocabularyTest(promptMode: TestPromptMode = .alternating, includeBothGroups: Bool = true)
}

public enum VocabularyTestGroup {
    case groupA
    case groupB
}

public class PDFGenerator {

    public static func generatePDF(for unit: VocabularyUnit, mode: PDFPrintMode) -> Data {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return Data()
        }

        switch mode {
        case .learningSheet(let isHomework):
            var mediaBox = CGRect(x: 0, y: 0, width: PDFLayoutConfig.landscapeWidth, height: PDFLayoutConfig.landscapeHeight)
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }
            renderLandscapePage(context: context, unit: unit, isHomework: isHomework)
            context.closePDF()

        case .learningSheetBothPages:
            var mediaBox = CGRect(x: 0, y: 0, width: PDFLayoutConfig.landscapeWidth, height: PDFLayoutConfig.landscapeHeight)
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }
            // Seite 1: Work / Unterricht
            renderLandscapePage(context: context, unit: unit, isHomework: false)
            // Seite 2: Homework / Hausaufgabe
            renderLandscapePage(context: context, unit: unit, isHomework: true)
            context.closePDF()

        case .vocabularyTest(let promptMode, let includeBothGroups):
            // DIN A4 HOCHFORMAT (595 x 842 pt)
            var mediaBox = CGRect(x: 0, y: 0, width: PDFLayoutConfig.portraitWidth, height: PDFLayoutConfig.portraitHeight)
            guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return Data() }
            // Seite 1: Version A (vollständige DIN A4 Hochformat-Seite)
            renderPortraitTestPage(context: context, unit: unit, group: .groupA, promptMode: promptMode)
            if includeBothGroups {
                // Seite 2: Version B (vollständige DIN A4 Hochformat-Seite)
                renderPortraitTestPage(context: context, unit: unit, group: .groupB, promptMode: promptMode)
            }
            context.closePDF()
        }

        return pdfData as Data
    }

    // =========================================================================
    // MARK: - DIN A4 HOCHFORMAT: VOKABELTEST (SEITE 1: VERSION A, SEITE 2: VERSION B)
    // =========================================================================
    private static func renderPortraitTestPage(
        context: CGContext,
        unit: VocabularyUnit,
        group: VocabularyTestGroup,
        promptMode: TestPromptMode
    ) {
        var pageRect = CGRect(x: 0, y: 0, width: PDFLayoutConfig.portraitWidth, height: PDFLayoutConfig.portraitHeight)
        context.beginPage(mediaBox: &pageRect)

        let gc = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gc

        // Hintergrund: Weiß
        context.setFillColor(NSColor.white.cgColor)
        context.fill(pageRect)

        let marginX = PDFLayoutConfig.portraitMarginX
        let width = PDFLayoutConfig.portraitContentWidth
        let pageH = PDFLayoutConfig.portraitHeight

        func yFromTop(_ topY: CGFloat, _ height: CGFloat) -> CGFloat {
            return pageH - topY - height
        }

        // 1. KOPFZEILE (Top: 32 pt)
        let headerTop: CGFloat = 32.0

        // 1a. Buch-Icon
        let bookW: CGFloat = 46.0
        let bookH: CGFloat = 50.0
        let bookRect = CGRect(x: marginX, y: yFromTop(headerTop, bookH), width: bookW, height: bookH)
        if let bookImg = loadAssetImage(named: "BookIcon.png") {
            bookImg.draw(in: bookRect)
        } else {
            drawFallbackBookIcon(context: context, rect: bookRect)
        }

        // 1b. Titel "Vocabulary training"
        let titleText = "Vocabulary training"
        let titleFont = PDFLayoutConfig.childFont(size: 26, bold: true)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let titleX = marginX + bookW + 16.0
        let titleY = yFromTop(headerTop + 14.0, 32.0)
        (titleText as NSString).draw(at: CGPoint(x: titleX, y: titleY), withAttributes: titleAttrs)

        // 1c. Gruppen-Badge Kreis (A oder B)
        let badgeDiameter: CGFloat = 34.0
        let badgeX = marginX + width - badgeDiameter - 4.0
        let badgeY = yFromTop(headerTop + 8.0, badgeDiameter)
        let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeDiameter, height: badgeDiameter)

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.2)
        context.strokeEllipse(in: badgeRect)

        let groupLetter = (group == .groupA) ? "A" : "B"
        let badgeFont = PDFLayoutConfig.childFont(size: 19, bold: true)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: NSColor.black
        ]
        let bSize = (groupLetter as NSString).size(withAttributes: badgeAttrs)
        let textPos = CGPoint(
            x: badgeRect.midX - (bSize.width / 2.0),
            y: badgeRect.midY - (bSize.height / 2.0)
        )
        (groupLetter as NSString).draw(at: textPos, withAttributes: badgeAttrs)
        context.restoreGState()

        // 2. THEMENLEISTE / UNIT-PILLE (Top: 90 pt, Height: 28 pt)
        let pillTop: CGFloat = 90.0
        let pillH: CGFloat = 28.0
        let pillRect = CGRect(x: marginX, y: yFromTop(pillTop, pillH), width: width, height: pillH)

        context.saveGState()
        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 7, yRadius: 7)
        NSColor(calibratedRed: 0.86, green: 0.89, blue: 0.92, alpha: 1.0).setFill()
        pillPath.fill()
        NSColor.black.setStroke()
        pillPath.lineWidth = 1.0
        pillPath.stroke()

        let modeSubtitle: String
        switch promptMode {
        case .alternating:
            modeSubtitle = "Gruppe \(groupLetter)"
        case .germanOnly:
            modeSubtitle = "Gruppe \(groupLetter) • Nur Deutsch vorgegeben"
        case .englishOnly:
            modeSubtitle = "Gruppe \(groupLetter) • Nur Englisch vorgegeben"
        }

        let pillText = "Unit \(unit.cleanUnitNumber): \(unit.title) (\(modeSubtitle))"
        let pillFont = PDFLayoutConfig.childFont(size: 14, bold: true)
        let pillAttrs: [NSAttributedString.Key: Any] = [
            .font: pillFont,
            .foregroundColor: NSColor.black
        ]
        let pillSize = (pillText as NSString).size(withAttributes: pillAttrs)
        let pillTextPt = CGPoint(
            x: pillRect.midX - (pillSize.width / 2.0),
            y: pillRect.midY - (pillSize.height / 2.0)
        )
        (pillText as NSString).draw(at: pillTextPt, withAttributes: pillAttrs)
        context.restoreGState()

        // 3. VOKABELTABELLE BERECHNUNG MIT HOHER, UNGEQUETSCHTER PFLANZENSCALE
        let tableTop: CGFloat = 126.0
        let bottomMargin: CGFloat = 22.0
        let totalPairs = unit.pairs.count
        let n = max(1, totalPairs)

        let plantAspect: CGFloat = 3464.0 / 1263.0 // ≈ 2.7427
        let naturalPlantH = width / plantAspect // ≈ 201.4 pt
        let scoreTableH: CGFloat = 24.0
        let footerH: CGFloat = 22.0
        let bottomFixedH = scoreTableH + footerH + 16.0 // 62 pt

        let availableForBoth = pageH - tableTop - bottomMargin - bottomFixedH - 12.0
        let desiredTableH = min(32.0 * CGFloat(n), max(22.0 * CGFloat(n), CGFloat(n) * 26.0))
        let plantH = min(naturalPlantH, availableForBoth - desiredTableH)
        let rowHeight = min(32.0, max(22.0, (availableForBoth - plantH) / CGFloat(n)))
        let actualTableH = rowHeight * CGFloat(n)

        let tableRect = CGRect(x: marginX, y: yFromTop(tableTop, actualTableH), width: width, height: actualTableH)
        let colWidth = width / 2.0

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.0)
        context.stroke(tableRect)

        // Mittellinie
        context.move(to: CGPoint(x: marginX + colWidth, y: tableRect.minY))
        context.addLine(to: CGPoint(x: marginX + colWidth, y: tableRect.maxY))
        context.strokePath()

        let vocabFont = PDFLayoutConfig.childFont(size: rowHeight > 26 ? 13.5 : 12.0, bold: false)
        let vocabAttrs: [NSAttributedString.Key: Any] = [
            .font: vocabFont,
            .foregroundColor: NSColor.black
        ]

        for i in 0..<n {
            let rowYFromTop = tableTop + (CGFloat(i) * rowHeight)
            let cellBottomY = yFromTop(rowYFromTop, rowHeight)

            if i > 0 {
                context.move(to: CGPoint(x: marginX, y: cellBottomY + rowHeight))
                context.addLine(to: CGPoint(x: marginX + width, y: cellBottomY + rowHeight))
                context.strokePath()
            }

            guard i < unit.pairs.count else { continue }
            let pair = unit.pairs[i]

            // Modus-Abhängiges Füllen für Gruppe A & B oder nur Deutsch / nur Englisch
            let showEnglish: Bool
            let showGerman: Bool

            switch promptMode {
            case .alternating:
                if group == .groupA {
                    showEnglish = (i % 2 != 0)
                    showGerman = (i % 2 == 0)
                } else {
                    showEnglish = (i % 2 == 0)
                    showGerman = (i % 2 != 0)
                }
            case .germanOnly:
                showEnglish = false
                showGerman = true
            case .englishOnly:
                showEnglish = true
                showGerman = false
            }

            let textOffsetY = (rowHeight - vocabFont.pointSize) / 2.0 - 2.0

            if showEnglish {
                let engPoint = CGPoint(x: marginX + 12.0, y: cellBottomY + textOffsetY)
                (pair.english as NSString).draw(at: engPoint, withAttributes: vocabAttrs)
            } else {
                // Gepunktete Schreiblinie für Schüler im Test
                drawDottedWritingLine(context: context, startX: marginX + 10.0, endX: marginX + colWidth - 10.0, y: cellBottomY + 7.0)
            }

            if showGerman {
                let gerPoint = CGPoint(x: marginX + colWidth + 12.0, y: cellBottomY + textOffsetY)
                (pair.german as NSString).draw(at: gerPoint, withAttributes: vocabAttrs)
            } else {
                // Gepunktete Schreiblinie für Schüler im Test
                drawDottedWritingLine(context: context, startX: marginX + colWidth + 10.0, endX: marginX + width - 10.0, y: cellBottomY + 7.0)
            }
        }
        context.restoreGState()

        // 4. UNTERER BEREICH: PFLANZENSYMBOLIK (NATÜRLICHE HÖHE) & DYNAMISCHE NOTENSKALA
        let plantW = min(width, plantH * plantAspect)
        let plantX = marginX + (width - plantW) / 2.0

        let bottomTop = pageH - bottomMargin - (plantH + scoreTableH + footerH + 10.0)
        let plantRect = CGRect(x: plantX, y: yFromTop(bottomTop, plantH), width: plantW, height: plantH)

        if let plantImg = loadAssetImage(named: "PlantFeedbackScale.png") {
            plantImg.draw(in: plantRect)
        } else {
            drawFallbackPlantStrip(context: context, rect: plantRect)
        }

        // 4b. Äußerer Rahmen für die Pflanzengrafik (garantiert geschlossene, gestochen scharfe Vektor-Rahmenlinie auch rechts)
        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.0)
        context.stroke(plantRect)
        context.restoreGState()

        // 4c. 4-Spalten Punktetabelle direkt unter der Pflanzengrafik
        let scoreTableTop = bottomTop + plantH - 1.0
        let scoreRect = CGRect(x: plantX, y: yFromTop(scoreTableTop, scoreTableH), width: plantW, height: scoreTableH)

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.0)
        context.stroke(scoreRect)

        let colW = plantW / 4.0
        let scoreFont = PDFLayoutConfig.childFont(size: 12, bold: true)
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: NSColor.black
        ]

        let grading = GradingScale(totalPoints: n)
        for i in 0..<4 {
            let colX = plantX + (CGFloat(i) * colW)
            if i > 0 {
                context.move(to: CGPoint(x: colX, y: scoreRect.minY))
                context.addLine(to: CGPoint(x: colX, y: scoreRect.maxY))
                context.strokePath()
            }

            let text = grading.thresholds[i].rangeString
            let sz = (text as NSString).size(withAttributes: scoreAttrs)
            let pt = CGPoint(
                x: colX + (colW - sz.width) / 2.0,
                y: scoreRect.midY - (sz.height / 2.0)
            )
            (text as NSString).draw(at: pt, withAttributes: scoreAttrs)
        }
        context.restoreGState()

        // 4c. Punkte- & Unterschriftenzeile
        let footerTop = scoreTableTop + scoreTableH + 10.0
        let footerFont = PDFLayoutConfig.childFont(size: 12.0, bold: false)
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: NSColor.black
        ]

        let pointsText = "Ich habe ____ von \(n) Punkten."
        let signText = "Unterschrift: ________________________"

        let footerY = yFromTop(footerTop, 18.0)
        (pointsText as NSString).draw(at: CGPoint(x: plantX + 4.0, y: footerY), withAttributes: footerAttrs)

        let signSz = (signText as NSString).size(withAttributes: footerAttrs)
        (signText as NSString).draw(at: CGPoint(x: plantX + plantW - signSz.width - 4.0, y: footerY), withAttributes: footerAttrs)

        NSGraphicsContext.restoreGraphicsState()
        context.endPage()
    }

    // =========================================================================
    // MARK: - DIN A4 QUERFORMAT: LERNVORLAGE (2x DIN A5 NEBENEINANDER)
    // =========================================================================
    private static func renderLandscapePage(
        context: CGContext,
        unit: VocabularyUnit,
        isHomework: Bool
    ) {
        var pageRect = CGRect(x: 0, y: 0, width: PDFLayoutConfig.landscapeWidth, height: PDFLayoutConfig.landscapeHeight)
        context.beginPage(mediaBox: &pageRect)

        let gc = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gc

        // Hintergrund: Weiß
        context.setFillColor(NSColor.white.cgColor)
        context.fill(pageRect)

        // Mittlere vertikale Schnitt-/Falzmarke (bei x = 421 pt)
        drawCenterDivider(context: context)

        // Linke DIN A5 Hälfte (x = 0...421)
        renderA5LandscapeHalf(
            context: context,
            originX: 0,
            unit: unit,
            isHomework: isHomework
        )

        // Rechte DIN A5 Hälfte (x = 421...842)
        renderA5LandscapeHalf(
            context: context,
            originX: PDFLayoutConfig.halfWidth,
            unit: unit,
            isHomework: isHomework
        )

        NSGraphicsContext.restoreGraphicsState()
        context.endPage()
    }

    private static func drawCenterDivider(context: CGContext) {
        context.saveGState()
        context.setStrokeColor(NSColor.lightGray.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(0.75)
        let lengths: [CGFloat] = [4, 4]
        context.setLineDash(phase: 0, lengths: lengths)

        context.move(to: CGPoint(x: PDFLayoutConfig.halfWidth, y: 15))
        context.addLine(to: CGPoint(x: PDFLayoutConfig.halfWidth, y: PDFLayoutConfig.landscapeHeight - 15))
        context.strokePath()

        // Schneidesymbol-Hinweis mittig oben/unten
        let scissorAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.gray
        ]
        let scissorStr = "✂" as NSString
        let sz = scissorStr.size(withAttributes: scissorAttrs)
        scissorStr.draw(at: CGPoint(x: PDFLayoutConfig.halfWidth - (sz.width / 2.0), y: PDFLayoutConfig.landscapeHeight - 14), withAttributes: scissorAttrs)
        scissorStr.draw(at: CGPoint(x: PDFLayoutConfig.halfWidth - (sz.width / 2.0), y: 4), withAttributes: scissorAttrs)

        context.restoreGState()
    }

    private static func renderA5LandscapeHalf(
        context: CGContext,
        originX: CGFloat,
        unit: VocabularyUnit,
        isHomework: Bool
    ) {
        context.saveGState()

        let marginX = originX + PDFLayoutConfig.landscapeMarginX
        let width = PDFLayoutConfig.landscapeContentWidth
        let pageH = PDFLayoutConfig.landscapeHeight

        func yFromTop(_ topY: CGFloat, _ height: CGFloat) -> CGFloat {
            return pageH - topY - height
        }

        // 1. KOPFZEILE (Top: 16 pt)
        let headerTop: CGFloat = 16.0

        // 1a. Buch-Icon
        let bookW: CGFloat = 38.0
        let bookH: CGFloat = 40.0
        let bookRect = CGRect(x: marginX, y: yFromTop(headerTop + 2, bookH), width: bookW, height: bookH)
        if let bookImg = loadAssetImage(named: "BookIcon.png") {
            bookImg.draw(in: bookRect)
        } else {
            drawFallbackBookIcon(context: context, rect: bookRect)
        }

        // 1b. Titel "Vocabulary training"
        let titleText = "Vocabulary training"
        let titleFont = PDFLayoutConfig.childFont(size: 21, bold: true)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.black
        ]
        let titleX = marginX + bookW + 12
        let titleY = yFromTop(headerTop + 14, 26)
        (titleText as NSString).draw(at: CGPoint(x: titleX, y: titleY), withAttributes: titleAttrs)

        // 1c. Unit-Badge
        let badgeDiameter: CGFloat = 28.0
        let badgeX = marginX + width - badgeDiameter - 2
        let badgeY = yFromTop(headerTop + 8, badgeDiameter)
        let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeDiameter, height: badgeDiameter)

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.0)
        context.strokeEllipse(in: badgeRect)

        let badgeStr = unit.cleanUnitNumber
        let badgeFontSize: CGFloat
        if badgeStr.count <= 2 {
            badgeFontSize = 15.0
        } else if badgeStr.count <= 4 {
            badgeFontSize = 11.5
        } else {
            badgeFontSize = 9.5
        }
        let badgeFont = PDFLayoutConfig.childFont(size: badgeFontSize, bold: true)
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: NSColor.black
        ]
        let bSize = (badgeStr as NSString).size(withAttributes: badgeAttrs)
        let textPos = CGPoint(
            x: badgeRect.midX - (bSize.width / 2.0),
            y: badgeRect.midY - (bSize.height / 2.0)
        )
        (badgeStr as NSString).draw(at: textPos, withAttributes: badgeAttrs)
        context.restoreGState()

        // 2. THEMENLEISTE / UNIT-PILLE (Top: 64 pt, Height: 24 pt)
        let pillTop: CGFloat = 64.0
        let pillH: CGFloat = 24.0
        let pillRect = CGRect(x: marginX, y: yFromTop(pillTop, pillH), width: width, height: pillH)

        context.saveGState()
        let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: 6, yRadius: 6)
        NSColor(calibratedRed: 0.86, green: 0.89, blue: 0.92, alpha: 1.0).setFill()
        pillPath.fill()
        NSColor.black.setStroke()
        pillPath.lineWidth = 1.0
        pillPath.stroke()

        let pillText = "Unit \(unit.cleanUnitNumber): \(unit.title)"
        let pillFont = PDFLayoutConfig.childFont(size: 13, bold: true)
        let pillAttrs: [NSAttributedString.Key: Any] = [
            .font: pillFont,
            .foregroundColor: NSColor.black
        ]
        let pillSize = (pillText as NSString).size(withAttributes: pillAttrs)
        let pillTextPt = CGPoint(
            x: pillRect.midX - (pillSize.width / 2.0),
            y: pillRect.midY - (pillSize.height / 2.0)
        )
        (pillText as NSString).draw(at: pillTextPt, withAttributes: pillAttrs)
        context.restoreGState()

        // 3. VOKABELTABELLE
        let tableTop: CGFloat = 93.0
        let bottomMargin: CGFloat = 18.0
        let totalPairs = unit.pairs.count
        let n = max(1, totalPairs)

        let bottomSectionHeight: CGFloat = 124.0
        let availableTableH = pageH - tableTop - bottomMargin - bottomSectionHeight - 6.0
        let rowHeight = min(25.0, max(17.5, availableTableH / CGFloat(n)))
        let actualTableH = rowHeight * CGFloat(n)

        let tableRect = CGRect(x: marginX, y: yFromTop(tableTop, actualTableH), width: width, height: actualTableH)
        let colWidth = width / 2.0

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1.0)
        context.stroke(tableRect)

        // Mittellinie
        context.move(to: CGPoint(x: marginX + colWidth, y: tableRect.minY))
        context.addLine(to: CGPoint(x: marginX + colWidth, y: tableRect.maxY))
        context.strokePath()

        let vocabFont = PDFLayoutConfig.childFont(size: rowHeight > 21 ? 12 : 11, bold: false)
        let vocabAttrs: [NSAttributedString.Key: Any] = [
            .font: vocabFont,
            .foregroundColor: NSColor.black
        ]

        for i in 0..<n {
            let rowYFromTop = tableTop + (CGFloat(i) * rowHeight)
            let cellBottomY = yFromTop(rowYFromTop, rowHeight)

            if i > 0 {
                context.move(to: CGPoint(x: marginX, y: cellBottomY + rowHeight))
                context.addLine(to: CGPoint(x: marginX + width, y: cellBottomY + rowHeight))
                context.strokePath()
            }

            guard i < unit.pairs.count else { continue }
            let pair = unit.pairs[i]

            let textOffsetY = (rowHeight - vocabFont.pointSize) / 2.0 - 2.0
            let engPoint = CGPoint(x: marginX + 8.0, y: cellBottomY + textOffsetY)
            (pair.english as NSString).draw(at: engPoint, withAttributes: vocabAttrs)

            let gerPoint = CGPoint(x: marginX + colWidth + 8.0, y: cellBottomY + textOffsetY)
            (pair.german as NSString).draw(at: gerPoint, withAttributes: vocabAttrs)
        }
        context.restoreGState()

        // 4. UNTERER BEREICH: FLAGGEN & ANWEISUNGSKÄSTEN
        let bottomTop = tableTop + actualTableH + 6.0
        renderInstructionBoxes(
            context: context,
            unit: unit,
            isHomework: isHomework,
            marginX: marginX,
            width: width,
            topY: bottomTop,
            height: bottomSectionHeight,
            yFromTop: yFromTop
        )

        context.restoreGState()
    }

    private static func drawDottedWritingLine(context: CGContext, startX: CGFloat, endX: CGFloat, y: CGFloat) {
        context.saveGState()
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.setLineWidth(0.8)
        let lengths: [CGFloat] = [2, 3]
        context.setLineDash(phase: 0, lengths: lengths)
        context.move(to: CGPoint(x: startX, y: y))
        context.addLine(to: CGPoint(x: endX, y: y))
        context.strokePath()
        context.restoreGState()
    }

    private static func renderInstructionBoxes(
        context: CGContext,
        unit: VocabularyUnit,
        isHomework: Bool,
        marginX: CGFloat,
        width: CGFloat,
        topY: CGFloat,
        height: CGFloat,
        yFromTop: (_ topY: CGFloat, _ height: CGFloat) -> CGFloat
    ) {
        let boxGap: CGFloat = 12.0
        let boxWidth = (width - boxGap) / 2.0
        let boxHeight = height - 14.0
        let boxTop = topY + 12.0

        let leftBoxRect = CGRect(x: marginX, y: yFromTop(boxTop, boxHeight), width: boxWidth, height: boxHeight)
        let rightBoxRect = CGRect(x: marginX + boxWidth + boxGap, y: yFromTop(boxTop, boxHeight), width: boxWidth, height: boxHeight)

        context.saveGState()
        NSColor.black.setStroke()
        let leftPath = NSBezierPath(roundedRect: leftBoxRect, xRadius: 6, yRadius: 6)
        leftPath.lineWidth = 1.0
        leftPath.stroke()

        let rightPath = NSBezierPath(roundedRect: rightBoxRect, xRadius: 6, yRadius: 6)
        rightPath.lineWidth = 1.0
        rightPath.stroke()
        context.restoreGState()

        let flagW: CGFloat = 34.0
        let flagH: CGFloat = 22.0
        let flagY = yFromTop(topY + 1, flagH)

        let ukFlagRect = CGRect(x: leftBoxRect.midX - (flagW / 2.0), y: flagY, width: flagW, height: flagH)
        let deFlagRect = CGRect(x: rightBoxRect.midX - (flagW / 2.0), y: flagY, width: flagW, height: flagH)

        if let ukImg = loadAssetImage(named: "UKFlag.png") {
            ukImg.draw(in: ukFlagRect)
        }
        if let deImg = loadAssetImage(named: "DEFlag.png") {
            deImg.draw(in: deFlagRect)
        }

        let titleFont = PDFLayoutConfig.childFont(size: 11, bold: true)
        let bodyFont = PDFLayoutConfig.childFont(size: 9.0, bold: false)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 1.0

        let engTitle = isHomework ? "Homework:" : "Work:"
        let engBody = isHomework ? unit.homeworkEnglish : unit.workEnglish

        let gerTitle = isHomework ? "Hausaufgabe:" : "Aufgabe:"
        let gerBody = isHomework ? unit.homeworkGerman : unit.workGerman

        let engFull = NSMutableAttributedString(string: "\(engTitle)\n", attributes: [
            .font: titleFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ])
        engFull.append(NSAttributedString(string: engBody, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]))

        let leftTextRect = leftBoxRect.insetBy(dx: 4, dy: 5)
        engFull.draw(in: leftTextRect)

        let gerFull = NSMutableAttributedString(string: "\(gerTitle)\n", attributes: [
            .font: titleFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ])
        gerFull.append(NSAttributedString(string: gerBody, attributes: [
            .font: bodyFont,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraphStyle
        ]))

        let rightTextRect = rightBoxRect.insetBy(dx: 4, dy: 5)
        gerFull.draw(in: rightTextRect)
    }

    private static func loadAssetImage(named name: String) -> NSImage? {
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension.isEmpty ? "png" : (name as NSString).pathExtension

        // 1. Try Bundle.module (Swift Package Manager resource bundle)
        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: baseName, withExtension: ext) {
            if let img = NSImage(contentsOf: url) {
                return img
            }
        }
        if let url = Bundle.module.url(forResource: baseName, withExtension: ext, subdirectory: "Assets") {
            if let img = NSImage(contentsOf: url) {
                return img
            }
        }
        #endif

        // 2. Try Bundle.main resourceURL and sub-bundles (inside standalone .app / Applications / DMG)
        if let resURL = Bundle.main.resourceURL {
            let candidateURLs = [
                resURL.appendingPathComponent(name),
                resURL.appendingPathComponent("Assets/\(name)"),
                resURL.appendingPathComponent("GSVokabelGenerator_GSVokabelGenerator.bundle/Contents/Resources/\(name)"),
                resURL.appendingPathComponent("GSVokabelGenerator_GSVokabelGenerator.bundle/Contents/Resources/Assets/\(name)"),
                resURL.appendingPathComponent("GSVokabelGenerator_GSVokabelGenerator.bundle/\(name)")
            ]
            for url in candidateURLs {
                if FileManager.default.fileExists(atPath: url.path),
                   let img = NSImage(contentsOf: url) {
                    return img
                }
            }
        }

        // 3. Try Bundle.main image(forResource:)
        if let bundleImg = Bundle.main.image(forResource: baseName) ?? Bundle.main.image(forResource: name) {
            return bundleImg
        }

        // 4. Try development fallback paths
        let devPaths = [
            "App/Resources/Assets/\(name)",
            "App/Resources/\(name)",
            "Reference-Templates/\(name)",
            "/Users/jensschneider/Documents/Gemini/GSVokabelGenerator/App/Resources/Assets/\(name)"
        ]
        for path in devPaths {
            if FileManager.default.fileExists(atPath: path),
               let img = NSImage(contentsOfFile: path) {
                return img
            }
        }

        return nil
    }

    private static func drawFallbackBookIcon(context: CGContext, rect: CGRect) {
        context.saveGState()
        context.setFillColor(NSColor.systemGreen.cgColor)
        context.fill(rect)
        context.restoreGState()
    }

    private static func drawFallbackPlantStrip(context: CGContext, rect: CGRect) {
        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.stroke(rect)
        let colW = rect.width / 4.0
        let titles = ["Samen", "Keimling", "Pflanze", "Blüte"]
        for i in 0..<4 {
            let colRect = CGRect(x: rect.minX + CGFloat(i) * colW, y: rect.minY, width: colW, height: rect.height)
            context.stroke(colRect)
            let s = titles[i] as NSString
            s.draw(at: CGPoint(x: colRect.midX - 15, y: colRect.midY), withAttributes: [:])
        }
        context.restoreGState()
    }
}

import Foundation
import CoreGraphics
import AppKit

public struct PDFLayoutConfig {
    // DIN A4 Querformat (Landscape) - für 2x DIN A5 Lernblätter
    public static let landscapeWidth: CGFloat = 842.0
    public static let landscapeHeight: CGFloat = 595.0
    public static let halfWidth: CGFloat = 421.0
    public static let landscapeMarginX: CGFloat = 24.0
    public static let landscapeContentWidth: CGFloat = halfWidth - (landscapeMarginX * 2.0) // 373 pt

    // DIN A4 Hochformat (Portrait) - für Vokabeltest Seite 1 (Version A) & Seite 2 (Version B)
    public static let portraitWidth: CGFloat = 595.0
    public static let portraitHeight: CGFloat = 842.0
    public static let portraitMarginX: CGFloat = 48.0
    public static let portraitContentWidth: CGFloat = portraitWidth - (portraitMarginX * 2.0) // 499 pt

    // Typografie
    public static func childFont(size: CGFloat, bold: Bool = false) -> NSFont {
        if bold {
            if let f = NSFont(name: "ChalkboardSE-Bold", size: size) { return f }
            if let f = NSFont(name: "ComicSansMS-Bold", size: size) { return f }
            return NSFont.systemFont(ofSize: size, weight: .bold)
        } else {
            if let f = NSFont(name: "ChalkboardSE-Regular", size: size) { return f }
            if let f = NSFont(name: "ComicSansMS", size: size) { return f }
            return NSFont.systemFont(ofSize: size, weight: .regular)
        }
    }
}

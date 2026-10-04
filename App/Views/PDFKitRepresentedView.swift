import SwiftUI
import PDFKit

public struct PDFKitRepresentedView: NSViewRepresentable {
    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        if let doc = PDFDocument(data: data) {
            pdfView.document = doc
        }
        return pdfView
    }

    public func updateNSView(_ pdfView: PDFView, context: Context) {
        if let currentData = pdfView.document?.dataRepresentation(), currentData == data {
            return
        }
        if let doc = PDFDocument(data: data) {
            pdfView.document = doc
        }
    }
}

import SwiftUI
import AppKit
import PDFKit

public struct PDFPreviewSheet: View {
    public let title: String
    public let pdfData: Data
    @Environment(\.dismiss) private var dismiss

    public init(title: String, pdfData: Data) {
        self.title = title
        self.pdfData = pdfData
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: savePDF) {
                    Label("PDF speichern...", systemImage: "square.and.arrow.down")
                }
                Button(action: printPDF) {
                    Label("Drucken...", systemImage: "printer")
                }
                .keyboardShortcut("p", modifiers: .command)
                Button("Fertig") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // PDF Ansicht
            PDFKitRepresentedView(data: pdfData)
                .frame(minWidth: 700, minHeight: 520)
        }
        .frame(minWidth: 800, minHeight: 600)
    }

    private func savePDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(title).pdf"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? pdfData.write(to: url)
            }
        }
    }

    private func printPDF() {
        guard let doc = PDFDocument(data: pdfData) else { return }
        let printInfo = NSPrintInfo.shared
        printInfo.orientation = .landscape
        printInfo.paperSize = NSSize(width: 842, height: 595)
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0

        if let printOp = doc.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) {
            printOp.showsPrintPanel = true
            printOp.run()
        }
    }
}

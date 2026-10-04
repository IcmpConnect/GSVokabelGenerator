import SwiftUI
import AppKit

public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    private var appIconImage: NSImage? {
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png", subdirectory: "Assets") {
            return NSImage(contentsOf: url)
        }
        if let direct = NSImage(contentsOfFile: "App/Resources/Assets/AppIcon.png") {
            return direct
        }
        return NSApp.applicationIconImage
    }

    public var body: some View {
        VStack(spacing: 18) {
            if let img = appIconImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            } else {
                Image(systemName: "character.book.closed.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: 6) {
                Text("GSVokabelGenerator")
                    .font(.title.bold())
                Text("Version 1.0 (Build 1.0.0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 4) {
                Text("Didaktische Grundschul-Vokabelverwaltung")
                    .font(.callout)
                Text("Lernblätter & Tests im zweigeteilten DIN A4 Format")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(width: 280)

            VStack(spacing: 4) {
                Text("Open Source • MIT-Lizenz")
                    .font(.callout.bold())
                Text("© 2026 Jens Schneider (IcmpConnect)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Schließen") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .padding(.top, 8)
        }
        .padding(30)
        .frame(width: 360, height: 340)
    }
}

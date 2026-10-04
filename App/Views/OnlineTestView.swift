import SwiftUI
import AppKit

public struct OnlineTestView: View {
    @ObservedObject public var server: OnlineTestServer
    public var unit: VocabularyUnit
    @Environment(\.dismiss) private var dismiss

    @State private var showingBeamerMode: Bool = false
    @State private var showingTroubleshooting: Bool = false
    @State private var selectedResult: StudentTestResult? = nil
    @State private var showingExportSuccess: Bool = false
    @State private var customPortText: String = ""
    @State private var showCustomPortField: Bool = false

    public init(server: OnlineTestServer, unit: VocabularyUnit) {
        self.server = server
        self.unit = unit
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Kopfbereich
            HStack(spacing: 12) {
                Image(systemName: "ipad.and.iphone")
                    .font(.title)
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("iPad Online-Test • \(unit.displayIdentifier)")
                        .font(.title2.bold())
                    Text("MacBook dient als lokaler Server im Klassenzimmer (kein Internet erforderlich)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if server.isRunning {
                    HStack(spacing: 6) {
                        Label("Server aktiv", systemImage: "circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline.bold())
                        Text("(Port \(server.port))")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(8)
                } else {
                    Label("Server gestoppt", systemImage: "circle.fill")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(8)
                }

                Button("Schließen") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Hauptbereich zweispaltig
            HSplitView {
                // Linke Spalte: QR-Code & Verbindungsdaten
                VStack(spacing: 16) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // QR-Code Box
                            VStack(spacing: 12) {
                                Text("Schüler-Zugang (QR-Code)")
                                    .font(.headline)

                                if let qrImage = server.generateQRCode(size: 260) {
                                    Image(nsImage: qrImage)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 240, height: 240)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(width: 240, height: 240)
                                        .overlay(Text("QR-Code lädt..."))
                                }

                                // Server URL
                                HStack(spacing: 8) {
                                    Text(server.serverURL)
                                        .font(.system(.body, design: .monospaced).bold())
                                        .textSelection(.enabled)

                                    Button(action: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(server.serverURL, forType: .string)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .buttonStyle(.plain)
                                    .help("Adresse in Zwischenablage kopieren")
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)

                                Button(action: { showingBeamerMode = true }) {
                                    Label("Beamer-Großansicht", systemImage: "arrow.up.left.and.arrow.down.right")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .help("Öffnet den QR-Code bildschirmfüllend für den Beamer")
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(16)

                            // Optionen & Konfiguration
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Test-Einstellungen")
                                    .font(.headline)

                                Picker("Richtung:", selection: $server.direction) {
                                    ForEach(TestDirection.allCases) { dir in
                                        Text(dir.rawValue).tag(dir)
                                    }
                                }
                                .pickerStyle(.menu)

                                Toggle("Vokabel-Reihenfolge auf Schüler-iPads mischen", isOn: $server.shuffleQuestions)
                                    .font(.subheadline)

                                Divider()

                                // Port-Auswahl
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Netzwerk-Port:")
                                            .font(.subheadline.bold())
                                        Spacer()
                                        if server.isRunning {
                                            Text("Port \(server.port) aktiv")
                                                .font(.caption.monospaced())
                                                .foregroundColor(.green)
                                        }
                                    }

                                    HStack(spacing: 8) {
                                        Picker("", selection: Binding(
                                            get: {
                                                [8000, 8080, 8888, 3000, 5000, 8443].contains(Int(server.port)) && !showCustomPortField ? server.port : 0
                                            },
                                            set: { newPort in
                                                if newPort == 0 {
                                                    showCustomPortField = true
                                                    customPortText = String(server.port)
                                                } else {
                                                    showCustomPortField = false
                                                    server.setPort(newPort)
                                                }
                                            }
                                        )) {
                                            Text("Port 8000 (Empfohlen bei Schul-WLAN)").tag(UInt16(8000))
                                            Text("Port 8080 (Standard)").tag(UInt16(8080))
                                            Text("Port 8888 (Entwicklung)").tag(UInt16(8888))
                                            Text("Port 3000 (Web-App)").tag(UInt16(3000))
                                            Text("Port 5000 (Web)").tag(UInt16(5000))
                                            Text("Port 8443 (Alt-HTTPS)").tag(UInt16(8443))
                                            Text("Anderer Port...").tag(UInt16(0))
                                        }
                                        .pickerStyle(.menu)

                                        if showCustomPortField {
                                            TextField("Port", text: $customPortText)
                                                .frame(width: 60)
                                                .textFieldStyle(.roundedBorder)

                                            Button("Setzen") {
                                                if let p = UInt16(customPortText.trimmingCharacters(in: .whitespaces)), p >= 1024 {
                                                    server.setPort(p)
                                                }
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }

                                    if !server.statusMessage.isEmpty {
                                        Text(server.statusMessage)
                                            .font(.caption2)
                                            .foregroundColor(server.isRunning ? .secondary : .red)
                                    }
                                }

                                Divider()

                                HStack {
                                    if server.isRunning {
                                        Button(role: .destructive, action: { server.stop() }) {
                                            Label("Server anhalten", systemImage: "stop.fill")
                                        }
                                    } else {
                                        Button(action: {
                                            server.start(unit: unit, port: server.port, direction: server.direction, shuffle: server.shuffleQuestions)
                                        }) {
                                            Label("Server neu starten", systemImage: "play.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }

                                    Spacer()

                                    Button(action: {
                                        server.refreshNetwork()
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise")
                                            Text("IP: \(server.localIP)")
                                        }
                                        .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Klicken, um IP-Adresse neu zu ermitteln")
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(16)

                            // Hinweis WLAN & Troubleshooting
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "wifi")
                                        .foregroundColor(.accentColor)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Schul-WLAN Hinweis:")
                                            .font(.caption.bold())
                                        Text("MacBook und iPads müssen im selben WLAN sein. Bei Schulnetzwerken verhindert oft die „Client Isolation“ direkte Verbindungen.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Button(action: { showingTroubleshooting = true }) {
                                    Label("Verbindungshilfe & Troubleshooting...", systemImage: "questionmark.circle.fill")
                                        .font(.caption.bold())
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.accentColor.opacity(0.08))
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                }
                .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)

                // Rechte Spalte: Live-Ergebnisse der Schüler
                VStack(spacing: 0) {
                    // Monitor Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Abgegebene Tests (\(server.results.count))")
                                .font(.headline)
                            if !server.results.isEmpty {
                                let avg = Double(server.results.map(\.score).reduce(0, +)) / Double(server.results.count)
                                Text("Durchschnitt: \(String(format: "%.1f", avg)) von \(unit.pairs.count) Punkten")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: exportCSV) {
                            Label("CSV exportieren", systemImage: "square.and.arrow.up")
                        }
                        .disabled(server.results.isEmpty)

                        Button(role: .destructive, action: {
                            server.clearResults()
                        }) {
                            Label("Leeren", systemImage: "trash")
                        }
                        .disabled(server.results.isEmpty)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))

                    Divider()

                    if server.results.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "hourglass")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Warte auf Schüler-Abgaben...")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("Sobald Schüler den QR-Code scannen und ihren Test abgeben, erscheinen die Ergebnisse hier live.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(server.results, selection: $selectedResult) { result in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(result.studentName)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(result.levelIcon) \(result.levelName)")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12))
                                        .cornerRadius(6)

                                    Text(result.formattedScore)
                                        .font(.title3.bold())
                                        .foregroundColor(result.score == result.maxScore ? .green : (result.score >= result.maxScore / 2 ? .primary : .orange))

                                    Text("(\(result.formattedPercentage))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                HStack {
                                    Text("Abgegeben um \(result.formattedTime)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    if result.incorrectAnswers.isEmpty {
                                        Text("✓ Alle Vokabeln fehlerfrei")
                                            .font(.caption2.bold())
                                            .foregroundColor(.green)
                                    } else {
                                        Text("\(result.incorrectAnswers.count) Fehler")
                                            .font(.caption2.bold())
                                            .foregroundColor(.orange)
                                    }
                                }

                                if !result.incorrectAnswers.isEmpty {
                                    DisclosureGroup("Fehlerhafte Wörter anzeigen (\(result.incorrectAnswers.count))") {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(result.incorrectAnswers) { ans in
                                                HStack(alignment: .top, spacing: 6) {
                                                    Text("•")
                                                    Text("\(ans.prompt):")
                                                        .fontWeight(.semibold)
                                                    Text("getippt: „\(ans.studentAnswer)“")
                                                        .foregroundColor(.red)
                                                    Text("→ richtig: „\(ans.expectedAnswer)“")
                                                        .foregroundColor(.green)
                                                }
                                                .font(.caption)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 840, minHeight: 620)
        .onAppear {
            if !server.isRunning {
                server.start(unit: unit)
            }
        }
        .sheet(isPresented: $showingBeamerMode) {
            BeamerQRCodeView(server: server, unit: unit, isPresented: $showingBeamerMode)
        }
        .sheet(isPresented: $showingTroubleshooting) {
            NetworkTroubleshootingView(server: server)
        }
    }

    private func exportCSV() {
        let csv = server.exportResultsCSV()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "Online-Test-Ergebnisse-\(unit.title.replacingOccurrences(of: " ", with: "_")).csv"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Beamer / Fullscreen QR Code View
public struct BeamerQRCodeView: View {
    @ObservedObject public var server: OnlineTestServer
    public var unit: VocabularyUnit
    @Binding public var isPresented: Bool
    @State private var showingTroubleshooting: Bool = false

    public var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            VStack(spacing: 6) {
                Text("Vokabeltest • Class \(unit.classNumber) Unit \(unit.cleanUnitNumber)")
                    .font(.largeTitle.bold())
                Text("„\(unit.title)“")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            // Huge QR Code
            if let qrImage = server.generateQRCode(size: 440) {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 380, height: 380)
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(28)
                    .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
            }

            VStack(spacing: 10) {
                Text("Mit der iPad-Kamera scannen:")
                    .font(.title3.bold())

                Text(server.serverURL)
                    .font(.system(.title2, design: .monospaced).bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(12)
            }

            HStack(spacing: 30) {
                Label("1. iPad-Kamera öffnen", systemImage: "camera.fill")
                Label("2. Auf QR-Code halten", systemImage: "qrcode.viewfinder")
                Label("3. Gelben Link antippen", systemImage: "hand.tap.fill")
            }
            .font(.headline)
            .foregroundColor(.secondary)

            Button(action: { showingTroubleshooting = true }) {
                Label("Probleme beim Verbinden? Verbindungshilfe & Troubleshooting", systemImage: "wifi.exclamationmark")
                    .font(.subheadline)
            }
            .buttonStyle(.link)
            .padding(.bottom, 24)
        }
        .frame(minWidth: 640, minHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingTroubleshooting) {
            NetworkTroubleshootingView(server: server)
        }
    }
}

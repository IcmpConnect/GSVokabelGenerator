import SwiftUI
import AppKit

public struct NetworkTroubleshootingView: View {
    @ObservedObject public var server: OnlineTestServer
    @Environment(\.dismiss) private var dismiss
    @State private var copiedURL: Bool = false

    public init(server: OnlineTestServer) {
        self.server = server
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Verbindungshilfe & Netzwerk-Troubleshooting")
                        .font(.title2.bold())
                    Text("Schritt-für-Schritt-Lösungen für Schul-WLANs, Firewalls und iPads")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Schließen") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Card 1: Diagnose & Selbsttest
                    diagnosticCard

                    // Card 2: Port-Wechsel
                    portCard

                    // Card 3: Client Isolation & Hotspot
                    clientIsolationCard

                    // Card 4: Getrennte Netzwerke / VLANs
                    vlanCard

                    // Card 5: macOS Berechtigungen & Firewall
                    macOSSecurityCard

                    // Card 6: Schüler-iPad Tipps
                    ipadTipsCard
                }
                .padding(24)
            }
        }
        .frame(minWidth: 720, minHeight: 620)
    }

    // MARK: - Subviews

    private var diagnosticCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("1. Schnelldiagnose / Selbsttest", systemImage: "stethoscope")
                    .font(.headline)
                Spacer()
                if server.isRunning {
                    Label("Server läuft", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.green)
                } else {
                    Label("Server gestoppt", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.red)
                }
            }

            Text("Prüfen Sie zuerst, ob der integrierte Webserver auf Ihrem MacBook grundsätzlich ansprechbar ist:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Text(server.serverURL)
                    .font(.system(.body, design: .monospaced).bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)

                Button(action: {
                    if let url = URL(string: server.serverURL) {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Label("Auf diesem Mac im Browser testen ↗", systemImage: "safari")
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(server.serverURL, forType: .string)
                    copiedURL = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedURL = false
                    }
                }) {
                    Label(copiedURL ? "Kopiert!" : "Kopieren", systemImage: copiedURL ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("**Ergebnis:** Wenn sich die Testseite auf Ihrem Mac sofort öffnet, arbeitet GSVokabelGenerator fehlerfrei! Das Problem liegt dann zu 100 % an der Abschottung des Schul-WLANs gegenüber den iPads.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private let commonPorts: [UInt16] = [8000, 8080, 8888, 3000, 8443]

    @ViewBuilder
    private func portButton(for p: UInt16) -> some View {
        let isSelected = (server.port == p)
        if isSelected {
            Button {
                server.setPort(p)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                    Text("Port \(p)")
                }
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                server.setPort(p)
            } label: {
                Text("Port \(p)")
            }
            .buttonStyle(.bordered)
        }
    }

    private var portCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("2. Anderen Netzwerk-Port ausprobieren", systemImage: "network")
                .font(.headline)

            Text("Schul-Firewalls blockieren häufig den Standard-Port `8080`. Versuchen Sie einen alternativen Port:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                ForEach(commonPorts, id: \.self) { p in
                    portButton(for: p)
                }
            }

            Text("💡 **Empfehlung:** Port 8000 und 8888 gehen in vielen Schulnetzen durch, in denen 8080 gefiltert wird.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var clientIsolationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("3. Häufigste Ursache: „Client Isolation“ im Schul-WLAN", systemImage: "shield.lefthalf.filled")
                    .font(.headline)
                Spacer()
                Text("Sehr häufig")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(6)
            }

            Text("""
            In den allermeisten Schulen (IServ, BayernWLAN, Eduroam, Unifi, Lancom) ist die sogenannte **Client Isolation** (oder Gastnetz-Isolation) aktiv:
            * Die iPads haben normalen Internetzugang.
            * Die iPads dürfen jedoch **unter keinen Umständen** direkt auf das MacBook der Lehrkraft im Raum zugreifen.
            * Safari zeigt auf dem iPad dann die Fehlermeldung: *„Seite kann nicht geöffnet werden, da der Server nicht antwortet“*.
            """)
            .font(.subheadline)

            Divider()

            Text("Bewährte Sofortlösungen im Unterricht:")
                .font(.subheadline.bold())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    Text("📱")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Option A: Handy-Hotspot (1-Minuten-Lösung)")
                            .font(.subheadline.bold())
                        Text("Aktivieren Sie kurz den „Persönlichen Hotspot“ auf Ihrem Smartphone. Verbinden Sie Ihr MacBook und die Schüler-iPads mit diesem Hotspot. Dort gibt es keine Blockaden und der Test klappt auf Anhieb!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("🔌")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Option B: Der 25 € Klassenraum-Reiserouter (Die beste Dauerlösung)")
                            .font(.subheadline.bold())
                        Text("Viele Lehrkräfte nutzen einen kleinen Mini-Router (z. B. TP-Link Nano oder GL.iNet Mango für 20–30 €), der einfach in die Steckdose im Raum gesteckt wird. Er spannt ein privates Klassen-WLAN auf – völlig ohne Internet, blitzschnell und 100 % unabhängig von Schul-IT und Sperren.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var vlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("4. Getrennte Netzwerke prüfen (Lehrer- vs. Schüler-WLAN)", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)

            Text("""
            Oft ist das MacBook im Netz **„Lehrer-WLAN“** eingewählt, die iPads jedoch im **„Schüler-WLAN“**.
            * Zwischen diesen beiden Netzen blockiert die Schul-Firewall jegliche Kommunikation.
            * **Lösung:** Stellen Sie sicher, dass Ihr MacBook und die Schüler-iPads im **exakt selben WLAN-Namen (SSID)** angemeldet sind.
            """)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var macOSSecurityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("5. macOS Lokales Netzwerk & Firewall prüfen", systemImage: "lock.shield")
                .font(.headline)

            Text("""
            Seit macOS 15 (Sequoia) fordert macOS für Apps eine Berechtigung für das lokale Netzwerk an:
            * Prüfen Sie unter **Systemeinstellungen → Datenschutz & Sicherheit → Lokales Netzwerk**, ob **GSVokabelGenerator** aktiviert ist.
            * Prüfen Sie unter **Systemeinstellungen → Netzwerk → Firewall**, ob eingehende Verbindungen erlaubt sind.
            """)
            .font(.subheadline)
            .foregroundColor(.secondary)

            Button(action: {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("macOS Systemeinstellungen öffnen ↗", systemImage: "gear")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var ipadTipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("6. Tipps für Schüler-iPads", systemImage: "ipad")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("• **Kamera-App verwenden:** QR-Code immer mit der Standard-Kamera von Apple scannen (nicht über Drittanbieter-Apps).")
                Text("• **Manuelle Eingabe in Safari:** Falls die Kamera nicht fokussiert, die Adresse (z. B. `\(server.serverURL)`) direkt in die Safari-Adresszeile tippen.")
                Text("• **Flugmodus-Reset:** Am iPad kurz für 3 Sekunden den Flugmodus ein- und wieder ausschalten, um die Netzwerkverbindung neu zu synchronisieren.")
                Text("• **Privates Surfen deaktivieren:** In seltenen Fällen blockieren restriktive Schul-Contentfilter Safari-Tabs im Privaten Modus.")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

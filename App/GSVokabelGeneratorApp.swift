import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "png") ??
                         Bundle.main.url(forResource: "AppIcon", withExtension: "icns") ??
                         Bundle.module.url(forResource: "AppIcon", withExtension: "png", subdirectory: "Assets") {
            if let img = NSImage(contentsOf: iconURL) {
                NSApplication.shared.applicationIconImage = img
            }
        } else if let direct = NSImage(contentsOfFile: "App/Resources/Assets/AppIcon.png") {
            NSApplication.shared.applicationIconImage = direct
        }
    }
}

@main
struct GSVokabelGeneratorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showingHelp: Bool = false
    @State private var showingAbout: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView(showingHelp: $showingHelp, showingAbout: $showingAbout)
                .sheet(isPresented: $showingHelp) {
                    HelpView()
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1050, height: 720)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Über GSVokabelGenerator...") {
                    showingAbout = true
                }
            }
            CommandGroup(replacing: .saveItem) {
                Button("Lerneinheiten sichern (Backup)...") {
                    NotificationCenter.default.post(name: .exportBackupRequested, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Backup wiederherstellen...") {
                    NotificationCenter.default.post(name: .importBackupRequested, object: nil)
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button("GSVokabelGenerator Hilfe...") {
                    showingHelp = true
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}

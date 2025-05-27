import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var aboutBoxWindowController: NSWindowController?
    private var specAllWindowController: NSWindowController?

    func showAboutPanel() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400), // Initial size
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = "About Specifier Pro"
            window.contentView = NSHostingView(rootView: AboutWindowView())
            window.center() // Center the window on the screen
            aboutBoxWindowController = NSWindowController(window: window)
        }

        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }

    func showSpecAllPanel() {
        if specAllWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600), // Initial size
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = "Specifier Pro - System Specifications"
            window.contentView = NSHostingView(rootView: SpecAllView(showSpecAllView: .constant(true)))
            window.center() // Center the window on the screen
            window.minSize = NSSize(width: 800, height: 600) // Fixed size
            specAllWindowController = NSWindowController(window: window)
        }

        specAllWindowController?.showWindow(specAllWindowController?.window)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialization code if needed
    }
    
}


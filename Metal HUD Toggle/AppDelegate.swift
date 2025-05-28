import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var aboutBoxWindowController: NSWindowController?
    
    func showAboutPanel() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .titled]
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 330, height: 380),
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = "About Metal HUD Utility"
            window.contentView = NSHostingView(rootView: AboutWindowView())
            window.center() 
            aboutBoxWindowController = NSWindowController(window: window)
        }
        
        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }
}

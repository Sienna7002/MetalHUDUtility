import SwiftUI

@main
struct Metal_HUD_ToggleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    if let window = NSApplication.shared.windows.first {
                        window.setContentSize(NSSize(width: 300, height: 300))
                        window.styleMask.remove([.resizable, .fullScreen])
                        window.standardWindowButton(.zoomButton)?.isEnabled = false
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appInfo) {
                Button(action: {
                    appDelegate.showAboutPanel()
                }) {
                    Text("About Metal HUD Utility")
                }
            }
            CommandGroup(replacing: .newItem) { }
            
            
            
        }
    }
}

//
//  ContentView.swift
//  Metal HUD Toggle
//
//  Created by 7002 on 15/03/2025.
//

import SwiftUI

struct ContentView: View {
    enum CurrentView {
        case main
        case demo
    }
    
    @State private var currentView: CurrentView = .main
    @State private var isMetalHUDEnabled = false
    @State private var logMessages: [String] = []
    @State private var demoViewID = UUID()
    @State private var showRestartBanner = false
    @State private var showRestartAlert = false
    @State private var pendingMetalHUDEnable: Bool? = nil
    
    init() {
        _isMetalHUDEnabled = State(initialValue: checkMetalHUDStatus())
        if UserDefaults.standard.bool(forKey: "launchIntoTest") {
            _currentView = State(initialValue: .demo)
            UserDefaults.standard.removeObject(forKey: "launchIntoTest")
        }
    }
    
    var body: some View {
        ZStack {
            CustomVisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)

            if isMetalHUDEnabled {
                AnimatedBackgroundView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 9), value: isMetalHUDEnabled)
            }

            switch currentView {
            case .main:
                mainView
                    .transition(.slide.combined(with: .opacity))
            case .demo:
                DemoViewContainer(isMetalHUDEnabled: isMetalHUDEnabled, goBack: { withAnimation { currentView = .main } })
                    .transition(.slide.combined(with: .opacity))
            }
        }
        .frame(minWidth: 330, minHeight: 380)
        .animation(.easeInOut(duration: 0.6), value: currentView)
        .animation(.easeInOut(duration: 0.6), value: showRestartBanner)
    }
    
    var mainView: some View {
        ZStack {
            VStack(spacing: 16) {
                Image("mcuico")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 20)
                Text("Metal HUD Utility")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.primary)
                
                VStack(spacing: 20) {
                    Toggle("Enable Metal HUD", isOn: Binding(
                        get: { isMetalHUDEnabled },
                        set: { newValue in
                            pendingMetalHUDEnable = newValue
                            showRestartAlert = true
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle())
                    .padding()
                    .frame(width: 250)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .tint(.pink)
                    .foregroundColor(Color.primary)
                    .alert(isPresented: $showRestartAlert) {
                        Alert(
                            title: Text("Metal HUD Status Change"),
                            message: Text("You must restart all apps for changes to take effect."),
                            primaryButton: .default(Text("OK")) {
                                if let newValue = pendingMetalHUDEnable {
                                    isMetalHUDEnabled = newValue
                                    toggleMetalHUD(enable: newValue)
                                }
                                pendingMetalHUDEnable = nil
                            },
                            secondaryButton: .cancel {
                                pendingMetalHUDEnable = nil
                            }
                        )
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set(true, forKey: "launchIntoTest")
                        let task = Process()
                        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                        task.arguments = ["-n", Bundle.main.bundlePath]
                        try? task.run()
                        exit(0)
                    }) {
                        Text("Test Metal HUD")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 250)
                            .background(Color.pink.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isMetalHUDEnabled)
                    .opacity(isMetalHUDEnabled ? 1.0 : 0.5)

                }
                .padding()
                .background(
                    CustomVisualEffectView(material: .windowBackground, blendingMode: .withinWindow)
                        .cornerRadius(15)
                        .shadow(radius: 10)
                )
            }
        }
        .onAppear {
            if isMetalHUDEnabled {
            }
        }
    }
    
    
    func toggleMetalHUD(enable: Bool) {
        let command = enable
        ? "defaults write -g MetalForceHudEnabled -bool YES"
        : "defaults write -g MetalForceHudEnabled -bool NO"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        
        do {
            try process.run()
            process.waitUntilExit()
            DispatchQueue.main.async {
                logMessages.append("Metal HUD \(enable ? "enabled" : "disabled").")
                showRestartBanner = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showRestartBanner = false
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                logMessages.append("Failed to toggle Metal HUD: \(error.localizedDescription)")
            }
        }
    }
    
    
    
    func checkMetalHUDStatus() -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "defaults read -g MetalForceHudEnabled 2>/dev/null"]
        
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return output == "1"
            }
        } catch {
            DispatchQueue.main.async {
                logMessages.append("Failed to check Metal HUD status: \(error.localizedDescription)")
            }
        }
        return false
    }
    
    
    
    
    struct CustomVisualEffectView: NSViewRepresentable {
        var material: NSVisualEffectView.Material
        var blendingMode: NSVisualEffectView.BlendingMode
        
        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.material = material
            view.blendingMode = blendingMode
            view.state = .active
            return view
        }
        
        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            nsView.material = material
            nsView.blendingMode = blendingMode
        }
    }
    
    struct DemoViewContainer: View {
        var isMetalHUDEnabled: Bool
        var goBack: () -> Void
        
        var body: some View {
            ZStack {
                VStack {
                    ZStack {
                        Text("Test Metal HUD")
                            .multilineTextAlignment(.center)

                        HStack {
                            Button(action: {
                                withAnimation {
                                    goBack()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.headline)
                                .padding(.all, 12)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                    }
                    DemoView()
                        .background(
                            CustomVisualEffectView(material: .windowBackground, blendingMode: .withinWindow)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isMetalHUDEnabled)
            .onAppear {
                if isMetalHUDEnabled {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                    process.arguments = ["-c", "defaults write -g MetalForceHudEnabled -bool YES"]
                    do {
                        try process.run()
                        process.waitUntilExit()
                    } catch {

                    }
                }
            }
        }
    }
    
    struct AnimatedBackgroundView: View {
        var body: some View {
            LinearGradient(gradient: Gradient(colors: [.pink.opacity(0.4), .purple.opacity(0.4), .blue.opacity(0.4)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .blur(radius: 50)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

import SwiftUI
import AppKit


struct AboutWindowView: View {
    @Environment(\.colorScheme) var colorScheme
    let appVersion = "v1 Prerelease"
    let buildNumber = "MHU1000"
    let developers = "7002"
    let appName = "Metal HUD Utility"

    var body: some View {
        ZStack {
            // Background with a subtle blur effect
            CustomVisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            // Main content view
            VStack(spacing: 16) {
                Image("sppico") // Ensure you have an image named "sppico" in your assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 20) // Add padding to the top for spacing
                
                HStack {
                    Text(appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .light ? .black : .white)
                }
                
                Text("This is open-source software. You may find the source code below.")
                    .font(.system(size: 10))
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .multilineTextAlignment(.center)

                Link(destination: URL(string: "https://github.com/Sienna7002/Metal-HUD-Toggle")!) {
                    Text("View on GitHub")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.pink)
                        .cornerRadius(8)
                }

                    
                // Content with a card-like background
                VStack(spacing: 12) {
                    HStack {
                        Text("Version:")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(colorScheme == .light ? .black : .white)
                        Spacer()
                        Text(appVersion)
                            .font(.custom("PT Mono", size: 14))
                            .foregroundColor(Color.gray)
                    }
                    
                    HStack {
                        Text("Build:")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(colorScheme == .light ? .black : .white)
                        Spacer()
                        Text(buildNumber)
                            .font(.custom("PT Mono", size: 14))
                            .foregroundColor(Color.gray)
                    }
                    
                    HStack {
                        Text("Developer:")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(colorScheme == .light ? .black : .white)
                        Spacer()
                        Text(developers)
                            .font(.custom("PT Mono", size: 14))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding(16) // Padding inside the card
                .background(
                    Group {
                        if colorScheme == .light {
                            Color.white.opacity(0.9)
                        } else {
                            CustomVisualEffectView(material: .windowBackground, blendingMode: .withinWindow)
                        }
                    }
                )
                .cornerRadius(12)
                .shadow(radius: 10) // Subtle shadow for depth
                
                Spacer() // Adjust if needed to remove extra space
            }
            .padding(24) // Refined padding for the overall layout
        }
        .frame(width: 450, height: 350)
    }

    struct CustomVisualEffectView: NSViewRepresentable {
        var material: NSVisualEffectView.Material
        var blendingMode: NSVisualEffectView.BlendingMode

        func makeNSView(context: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.material = material
            view.blendingMode = blendingMode
            view.state = .active
            view.isEmphasized = true
            return view
        }

        func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
            nsView.material = material
            nsView.blendingMode = blendingMode
            nsView.isEmphasized = true
        }
    }
}

struct AboutWindowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AboutWindowView()
                .preferredColorScheme(.light)
            AboutWindowView()
                .preferredColorScheme(.dark)
        }
    }
}

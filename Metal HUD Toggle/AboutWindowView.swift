import SwiftUI
import AppKit


struct AboutWindowView: View {
    @Environment(\.colorScheme) var colorScheme
    let appVersion = "v0.5 Alpha"
    let buildNumber = "SPP0203"
    let developers = "7002"
    let appName = "Specifier Pro"
    let appTag = "ALPHA"
    let disclosureText = "This alpha software is intended to be used for beta testing purposes only, if you are given this software without the written consent of 7002 or recieved this build through a source not endorsed or operated by 7002, destroy this copy immediately."

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
                
                HStack(spacing: 5) {
                    Text(appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .light ? .black : .white)
                    
                    Text(appTag)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.yellow)
                        .clipShape(Capsule())
                }
                
                Text(disclosureText)
                    .font(.system(size: 10))
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)

                    
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


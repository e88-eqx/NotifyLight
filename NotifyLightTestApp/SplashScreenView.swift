import SwiftUI

struct SplashScreenView: View {
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background color - EQX deep blue/navy
            Color(red: 0.1, green: 0.137, blue: 0.196) // #1a2332
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // EQX Logo text
                Text("EQX")
                    .font(.system(size: 72, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .opacity(logoOpacity)
                
                // Subtitle for SDK testing context
                Text("NotifyLight Test App")
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(logoOpacity)
            }
        }
        .onAppear {
            // NOTIFYLIGHT SDK INTEGRATION POINT: Splash Screen Load
            print("SplashScreenView: ========== SPLASH SCREEN LOADED ==========")
            print("SplashScreenView: Starting fade-in animation...")
            
            // NOTIFYLIGHT SDK INTEGRATION POINT: Early App Initialization
            print("SplashScreenView: SDK Integration Point - Early app initialization during splash...")
            // Example: NotifyLight.shared.earlyInitialization()
            
            // Animate logo fade-in
            withAnimation(.easeInOut(duration: 1.5)) {
                logoOpacity = 1.0
            }
            
            print("SplashScreenView: Fade-in animation started - will complete in 1.5 seconds")
        }
        .onDisappear {
            // NOTIFYLIGHT SDK INTEGRATION POINT: Splash Screen Disappear
            print("SplashScreenView: ========== SPLASH SCREEN DISAPPEARED ==========")
            print("SplashScreenView: SDK Integration Point - Splash screen transition complete")
            // Example: NotifyLight.shared.onSplashComplete()
        }
    }
}

#Preview {
    SplashScreenView()
}
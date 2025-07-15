import SwiftUI

@main
struct NotifyLightTestApp: App {
    @State private var showSplash = true
    @State private var hasInitialized = false
    @StateObject private var notifyLight = NotifyLight.shared
    
    init() {
        // NOTIFYLIGHT SDK INTEGRATION POINT: App Launch
        print("NotifyLightApp: ========== APP LAUNCHED ==========")
        print("NotifyLightApp: Initializing NotifyLight SDK Test App...")
        print("NotifyLightApp: SDK Integration Point - App delegate setup complete")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .onAppear {
                            print("NotifyLightApp: Splash screen appeared - starting transition timer")
                            
                            // Initialize SDK on first appearance
                            if !hasInitialized {
                                hasInitialized = true
                                Task {
                                    await configureSDK()
                                }
                            }
                            
                            // NOTIFYLIGHT SDK INTEGRATION: App Foreground
                            print("NotifyLightApp: SDK Integration Point - App entered foreground, checking for pending messages...")
                            Task {
                                await NotifyLight.shared.checkForInAppMessages()
                            }
                            
                            // Auto-transition after 1.5 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                print("NotifyLightApp: Transitioning from splash to portfolio...")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    PortfolioView()
                        .onAppear {
                            print("NotifyLightApp: Portfolio view appeared")
                            
                            // NOTIFYLIGHT SDK INTEGRATION: Main Screen Load
                            print("NotifyLightApp: SDK Integration Point - Main screen loaded, checking for in-app messages...")
                            Task {
                                await NotifyLight.shared.checkForInAppMessages()
                            }
                        }
                }
                
                // NOTIFYLIGHT SDK INTEGRATION: In-App Message Overlay
                if let message = notifyLight.currentInAppMessage {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            notifyLight.currentInAppMessage = nil
                        }
                    
                    VStack {
                        Spacer()
                        
                        InAppMessageView(message: message) {
                            notifyLight.currentInAppMessage = nil
                        }
                        
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.3), value: notifyLight.currentInAppMessage)
                }
            }
        }
    }
    
    private func configureSDK() async {
        do {
            // NOTIFYLIGHT SDK INTEGRATION: Initialize SDK
            print("NotifyLightApp: SDK Integration Point - Initialize NotifyLight SDK with API Key and User ID...")
            
            let config = NotifyLightConfiguration(
                apiUrl: URL(string: "http://localhost:3000")!,
                apiKey: "your-super-secret-api-key-1234",
                userId: "test-user-ios"
            )
            try await NotifyLight.shared.configure(with: config)
            print("NotifyLightApp: ✅ SDK configured successfully")
            
            // NOTIFYLIGHT SDK INTEGRATION: Request Push Permissions
            print("NotifyLightApp: SDK Integration Point - Request push notification permissions...")
            let authStatus = try await NotifyLight.shared.requestPushAuthorization()
            print("NotifyLightApp: ✅ Push authorization status: \(authStatus)")
            
            // NOTIFYLIGHT SDK INTEGRATION: Register device
            let deviceToken = try await NotifyLight.shared.registerDevice()
            print("NotifyLightApp: ✅ Device registered with token: \(deviceToken)")
            
            // NOTIFYLIGHT SDK INTEGRATION: Show "Hello World" message on app launch
            print("NotifyLightApp: SDK Integration Point - Showing 'Hello World' message...")
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await NotifyLight.shared.showInAppMessage(
                    title: "Hello World",
                    message: "Welcome to NotifyLight Test App! SDK integration is working."
                )
            }
            
        } catch {
            print("NotifyLightApp: ❌ SDK configuration failed: \(error)")
        }
    }
}
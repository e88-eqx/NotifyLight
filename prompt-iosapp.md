You are an expert iOS developer specializing in SwiftUI. I need you to create a **minimal, visually appealing iOS mock application** that will serve as a **testbed for a custom SDK I am building.**

**Crucial Context and Goal:**
* This app is **NOT for end-users, NOT for production, and does NOT need to scale.**
* Its **sole purpose** is to allow me to integrate and thoroughly test a custom SDK for notifications (in-app messages and push notifications).
* Therefore, **robust and easily accessible logging** of app lifecycle and SDK interaction points is paramount.
* The UI should reflect a **simplified EQX brand aesthetic** (colors, typography, rounded cards) but **without any complex animations, shadows, gradients, or intricate UI/UX interactions** that would increase development effort beyond what's necessary for a good-looking test app.

**Please provide the complete Xcode project structure and all necessary Swift/SwiftUI code files to meet these streamlined requirements.**

---

### **Streamlined Core Requirements:**

1.  **App Structure & Flow:**
    * **Launch Sequence:** A simple splash screen displaying "EQX" (text-based logo) with a basic `opacity` fade-in animation (e.g., 1.5 seconds) that automatically transitions to a single 'Portfolio' screen.
    * **Architecture:** Pure SwiftUI. Target iOS 15.0+.
    * **Performance:** The app should load quickly and smoothly for testing purposes.

2.  **EQX Brand Aesthetic (Simplified):**
    * **Color Palette:** Use a primary deep blue/navy (e.g., `#1a2332` or similar dark blue), a bright accent color (e.g., electric blue or green for positive values), and clean white/light gray for backgrounds. Use these consistently.
    * **Typography:** Use the system's modern sans-serif font (`SF Pro Display/Text`). Apply clear hierarchy (e.g., large titles, readable body text) using standard SwiftUI font modifiers.
    * **UI Elements:** Implement rounded corners on all relevant elements (e.g., buttons, card-like views). Avoid subtle shadows, depth effects, transparency, or complex gradients. Simplicity and clarity are prioritized.

3.  **EQX Logo Implementation (`SplashScreenView.swift`):**
    * A dedicated SwiftUI `View` for the splash screen.
    * Displays the text "EQX" (or a similar placeholder like "NotifyLight Test App") centrally.
    * Applies a simple `opacity` animation for fade-in/fade-out over ~1.5 seconds before transitioning.
    * Uses a simple `Timer` or `Task.delay` for the automatic transition.

4.  **Mock Portfolio Screen (`PortfolioView.swift`):**
    * **Purpose:** A screen to simulate a user interface where SDK events might naturally occur.
    * **Content:**
        * A simple header (e.g., "My Portfolio" or "Holdings").
        * A `List` or `ForEach` displaying **3-4 hardcoded mock crypto assets**. Each asset should be a simple `struct` (e.g., `CryptoAsset(symbol: String, amount: Double, price: Double, isPositive: Bool)`).
        * Each row should show: **Coin symbol** (e.g., "BTC"), **Amount held** (e.g., "0.5 BTC"), **Current Price** (e.g., "$35,000").
        * Visually distinguish positive/negative price changes using the accent color for positive and red for negative (based on `isPositive` in mock data).
        * **No complex interactions:** No pull-to-refresh, no detailed graphs, no networking for real data. Just static mock data displayed cleanly.
    * **Mock Data:** Hardcode the `CryptoAsset` data directly within the `PortfolioView` or a simple `MockData.swift` file.

5.  **Advanced Error Logging System (CRITICAL for SDK Testing):**
    * **Primary Requirement:** All logs (app lifecycle, view appearances, mock data loading, and **especially SDK interaction placeholders**) MUST be easily visible in Xcode's console/Terminal.
    * **Implementation:** Use `print()` statements throughout the app for simplicity. No complex logging frameworks are needed.
    * **Log all key events:**
        * App launch (`App` struct `init`).
        * Splash screen appearance and disappearance.
        * Portfolio screen appearance.
        * Any data loading (even mock data).
        * **Crucially, include commented-out placeholder `print()` statements for where SDK calls would go, clearly marked.** For example:
            ```swift
            // NOTIFYLIGHT SDK INTEGRATION POINT: Initialize SDK
            print("NotifyLightApp: SDK Integration Point - Initializing NotifyLight SDK with API Key and User ID...")

            // NOTIFYLIGHT SDK INTEGRATION POINT: Register for Push Notifications
            print("NotifyLightApp: SDK Integration Point - Registering for Push Notifications...")

            // NOTIFYLIGHT SDK INTEGRATION POINT: Check for In-App Message
            print("NotifyLightApp: SDK Integration Point - Checking for In-App Message for current user...")

            // NOTIFYLIGHT SDK INTEGRATION POINT: Handle Incoming Push Notification
            print("NotifyLightApp: SDK Integration Point - Handling incoming push notification: \(userInfo)")
            ```
    * No file-based logging, no log rotation, no custom log categories beyond simple `print()`.

6.  **Code Organization:**
    * Maintain a logical, standard SwiftUI project structure. Keep it flat and simple (e.g., `NotifyLightTestApp.swift`, `SplashScreenView.swift`, `PortfolioView.swift`, `Models.swift`). Do not over-engineer with complex architectural patterns.

7.  **Deliverables:**
    * A complete Xcode project structure (main app file, views, models).
    * The Swift/SwiftUI code for each file.
    * A concise `README.md` in the root of the project explaining:
        * How to build and run the app in Xcode.
        * **Crucially, how to view the logs in Xcode's console/Terminal.**
        * Where the SDK integration points are located.
        * How to easily modify mock data.

---

**Technical Specifications (for Claude's internal reference):**
* **Language:** Swift 5.9+
* **Framework:** SwiftUI (exclusive where possible)
* **Dependencies:** Standard iOS frameworks only (Foundation, SwiftUI, etc.). No third-party libraries.

---

Please provide the Xcode project as a set of code snippets for each file. Structure your response clearly, file by file. Focus on delivering the minimum code necessary to meet these requirements, with a strong emphasis on the logging and SDK integration points.

---
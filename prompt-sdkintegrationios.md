Here is a prompt you can use for Claude Pro:You are an experienced iOS software developer. Your task is to integrate a new SDK into an existing iOS test application, following the provided quickstart instructions. After successful integration, you must implement the display of in-app messages as described below.

**Context:**

* **iOS Test Application:** The sample application is located at `/NotifyLightTestApp/NotifyLightTestApp/NotifyLightTestApp.xcode-proj`. You should assume this is a standard Xcode project.
* **Quickstart Instructions:** The SDK integration instructions are provided in the file `/QUICKSTART.md`. You should assume this Markdown file contains all necessary steps for setting up the SDK, including any required dependencies, configuration, and initialisation.

**Task:**

1.  **SDK Integration:**
    * Carefully read and follow the instructions in `/QUICKSTART.md` to integrate the SDK into the `NotifyLightTestApp` Xcode project.
    * Ensure all necessary frameworks, libraries, and configurations (e.g., API keys, entitlements, Info.plist entries) are correctly set up as per the quickstart guide.
    * Handle any potential issues or common pitfalls during iOS SDK integration (e.g., linker errors, missing permissions, main thread blocking).

2.  **In-App Message Implementation:**
    * **Message 1: "Hello World" on App Open:**
        * Implement the SDK's functionality to display an in-app message with the text "Hello World" immediately when the `NotifyLightTestApp` application launches and becomes active. This should be the first message a user sees.
    * **Message 2: "Hello Again World" on Portfolio Object Click:**
        * Identify a "portfolio object" within the `NotifyLightTestApp`'s UI. This could be any tappable element that represents an item in a list, a card, or a detail view (e.g., a table view cell, a collection view cell, a button, or a specific view that represents a portfolio item).
        * When *any* of these portfolio objects is tapped or clicked by the user, trigger the SDK's functionality to display a second in-app message with the text "Hello Again World".

**Deliverables:**

* A detailed, step-by-step explanation of how you integrated the SDK, referencing specific lines of code or file modifications.
* The modified code snippets (e.g., `AppDelegate.swift`, `ViewController.swift`, or any other relevant files) showing the SDK initialization and the in-app message triggers.
* Any assumptions you made about the structure of `NotifyLightTestApp` or the content of `QUICKSTART.md` if they were not explicitly provided.
* Instructions on how to test the implemented in-app messages.

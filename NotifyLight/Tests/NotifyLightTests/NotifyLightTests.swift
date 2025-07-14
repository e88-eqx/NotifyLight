import XCTest
@testable import NotifyLight

final class NotifyLightTests: XCTestCase {
    
    var notifyLight: NotifyLight!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() {
        super.setUp()
        notifyLight = NotifyLight.shared
        mockAPIClient = MockAPIClient()
    }
    
    override func tearDown() {
        notifyLight.removeAllHandlers()
        notifyLight.disableAutoMessageCheck()
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfiguration() async throws {
        let config = NotifyLight.Configuration(
            apiUrl: URL(string: "https://test.notifylight.com")!,
            apiKey: "test-api-key",
            userId: "test-user",
            autoRegisterForNotifications: false,
            enableDebugLogging: true
        )
        
        try await notifyLight.configure(with: config)
        
        XCTAssertTrue(notifyLight.isInitialized)
    }
    
    func testInvalidConfiguration() async {
        let config = NotifyLight.Configuration(
            apiUrl: URL(string: "invalid-url")!,
            apiKey: "",
            userId: nil
        )
        
        do {
            try await notifyLight.configure(with: config)
            XCTFail("Should have thrown an error for invalid configuration")
        } catch {
            XCTAssertTrue(error is NotifyLightError)
        }
    }
    
    // MARK: - Event Handler Tests
    
    func testNotificationEventHandler() async {
        let expectation = XCTestExpectation(description: "Notification event received")
        
        notifyLight.onNotification { event in
            switch event {
            case .tokenReceived(let token):
                XCTAssertFalse(token.isEmpty)
                expectation.fulfill()
            default:
                break
            }
        }
        
        // Simulate token received event
        let mockToken = "mock-device-token-12345"
        await notifyLight.didRegisterForRemoteNotifications(
            withDeviceToken: mockToken.data(using: .utf8)!
        )
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testMessageEventHandler() async {
        let expectation = XCTestExpectation(description: "Message event received")
        
        notifyLight.onMessage { message in
            XCTAssertEqual(message.title, "Test Message")
            expectation.fulfill()
        }
        
        // Simulate message received
        let testMessage = InAppMessage(
            id: "test-message-1",
            title: "Test Message",
            message: "This is a test message"
        )
        
        // Note: In real implementation, this would be triggered by fetchMessages()
        // For testing, we'd need to mock the API response
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Device Token Tests
    
    func testDeviceTokenHandling() async {
        let testToken = "1234567890abcdef"
        let tokenData = testToken.data(using: .utf8)!
        
        await notifyLight.didRegisterForRemoteNotifications(withDeviceToken: tokenData)
        
        // In a real implementation, we'd check if the token was stored correctly
        // This would require exposing internal state or using dependency injection
        XCTAssertNotNil(notifyLight.currentToken)
    }
    
    func testDeviceTokenFailure() async {
        let expectation = XCTestExpectation(description: "Registration error received")
        
        notifyLight.onNotification { event in
            if case .registrationError(let error) = event {
                XCTAssertNotNil(error)
                expectation.fulfill()
            }
        }
        
        let testError = NSError(domain: "TestError", code: 500, userInfo: nil)
        await notifyLight.didFailToRegisterForRemoteNotifications(with: testError)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Model Tests
    
    func testDeviceModel() {
        let device = Device(
            token: "test-token",
            platform: "ios",
            userId: "user123"
        )
        
        XCTAssertEqual(device.token, "test-token")
        XCTAssertEqual(device.platform, "ios")
        XCTAssertEqual(device.userId, "user123")
        XCTAssertNotNil(device.registeredAt)
    }
    
    func testNotificationModel() {
        let notification = NotifyLightNotification(
            id: "notif-1",
            title: "Test Title",
            message: "Test Message",
            data: ["key": "value"],
            type: .push
        )
        
        XCTAssertEqual(notification.id, "notif-1")
        XCTAssertEqual(notification.title, "Test Title")
        XCTAssertEqual(notification.message, "Test Message")
        XCTAssertEqual(notification.type, .push)
        XCTAssertNotNil(notification.data)
    }
    
    func testInAppMessageModel() {
        let action = MessageAction(
            id: "action-1",
            title: "OK",
            style: .primary
        )
        
        let message = InAppMessage(
            id: "msg-1",
            title: "Test Message",
            message: "This is a test",
            actions: [action]
        )
        
        XCTAssertEqual(message.id, "msg-1")
        XCTAssertEqual(message.title, "Test Message")
        XCTAssertEqual(message.actions.count, 1)
        XCTAssertEqual(message.actions.first?.title, "OK")
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testDeviceRegistrationRequestEncoding() throws {
        let request = DeviceRegistrationRequest(
            token: "test-token",
            platform: "ios",
            userId: "user123"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeviceRegistrationRequest.self, from: data)
        
        XCTAssertEqual(decoded.token, request.token)
        XCTAssertEqual(decoded.platform, request.platform)
        XCTAssertEqual(decoded.userId, request.userId)
    }
    
    func testInAppMessageDecoding() throws {
        let json = """
        {
            "id": "msg-1",
            "title": "Test Message",
            "message": "This is a test message",
            "actions": [
                {
                    "id": "ok",
                    "title": "OK",
                    "style": "primary"
                }
            ],
            "created_at": "2024-01-01T12:00:00Z",
            "is_read": false
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let message = try decoder.decode(InAppMessage.self, from: data)
        
        XCTAssertEqual(message.id, "msg-1")
        XCTAssertEqual(message.title, "Test Message")
        XCTAssertEqual(message.actions.count, 1)
        XCTAssertFalse(message.isRead)
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkErrorHandling() {
        let error = NetworkError.httpError(404)
        XCTAssertEqual(error.localizedDescription, "HTTP error with status code: 404")
        
        let apiError = NetworkError.apiError("Invalid API key", 401)
        XCTAssertEqual(apiError.localizedDescription, "API error (401): Invalid API key")
    }
    
    // MARK: - Configuration Validation Tests
    
    func testConfigurationValidation() {
        // Valid configuration
        let validConfig = NotifyLight.Configuration(
            apiUrl: URL(string: "https://api.notifylight.com")!,
            apiKey: "valid-api-key",
            userId: "user123"
        )
        
        XCTAssertEqual(validConfig.apiKey, "valid-api-key")
        XCTAssertEqual(validConfig.userId, "user123")
        XCTAssertTrue(validConfig.autoRegisterForNotifications)
        XCTAssertEqual(validConfig.timeoutInterval, 30)
        XCTAssertFalse(validConfig.enableDebugLogging)
    }
}

// MARK: - Mock Classes

class MockAPIClient {
    var shouldFail = false
    var mockMessages: [InAppMessage] = []
    var mockRegistrationResponse: DeviceRegistrationResponse?
    
    func registerDevice(_ request: DeviceRegistrationRequest) async throws -> DeviceRegistrationResponse {
        if shouldFail {
            throw NetworkError.httpError(500)
        }
        
        return mockRegistrationResponse ?? DeviceRegistrationResponse(
            success: true,
            deviceId: "mock-device-id",
            message: "Device registered successfully"
        )
    }
    
    func fetchMessages(userId: String) async throws -> InAppMessagesResponse {
        if shouldFail {
            throw NetworkError.httpError(404)
        }
        
        return InAppMessagesResponse(
            success: true,
            messages: mockMessages,
            count: mockMessages.count
        )
    }
}

// MARK: - Test Utilities

extension XCTestCase {
    func createMockNotification(
        title: String = "Test Notification",
        message: String = "Test message"
    ) -> NotifyLightNotification {
        return NotifyLightNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            data: ["test": true],
            type: .push
        )
    }
    
    func createMockInAppMessage(
        title: String = "Test Message",
        withActions: Bool = false
    ) -> InAppMessage {
        var actions: [MessageAction] = []
        
        if withActions {
            actions = [
                MessageAction(id: "ok", title: "OK", style: .primary),
                MessageAction(id: "cancel", title: "Cancel", style: .secondary)
            ]
        }
        
        return InAppMessage(
            id: UUID().uuidString,
            title: title,
            message: "This is a test message",
            actions: actions
        )
    }
}
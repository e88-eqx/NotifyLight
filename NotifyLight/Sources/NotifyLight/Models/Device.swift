import Foundation

/// Represents a device for push notifications
public struct Device: Codable {
    public let id: String?
    public let token: String
    public let platform: String
    public let userId: String?
    public let registeredAt: Date?
    
    public init(token: String, platform: String = "ios", userId: String? = nil) {
        self.id = nil
        self.token = token
        self.platform = platform
        self.userId = userId
        self.registeredAt = Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case token
        case platform
        case userId = "user_id"
        case registeredAt = "registered_at"
    }
}

/// Device registration request payload
public struct DeviceRegistrationRequest: Codable {
    public let token: String
    public let platform: String
    public let userId: String?
    
    public init(token: String, platform: String = "ios", userId: String? = nil) {
        self.token = token
        self.platform = platform
        self.userId = userId
    }
    
    enum CodingKeys: String, CodingKey {
        case token
        case platform
        case userId = "user_id"
    }
}

/// Device registration response
public struct DeviceRegistrationResponse: Codable {
    public let success: Bool
    public let deviceId: String?
    public let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case deviceId = "device_id"
        case message
    }
}
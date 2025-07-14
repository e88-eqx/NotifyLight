import Foundation

/// Represents a push notification
public struct NotifyLightNotification: Codable {
    public let id: String?
    public let title: String
    public let message: String
    public let data: [String: Any]?
    public let receivedAt: Date
    public let type: NotificationType
    
    public init(
        id: String? = nil,
        title: String,
        message: String,
        data: [String: Any]? = nil,
        type: NotificationType = .push
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.data = data
        self.receivedAt = Date()
        self.type = type
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case data
        case receivedAt = "received_at"
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        receivedAt = try container.decodeIfPresent(Date.self, forKey: .receivedAt) ?? Date()
        type = try container.decodeIfPresent(NotificationType.self, forKey: .type) ?? .push
        
        // Handle data as flexible dictionary
        if let dataDict = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data) {
            data = dataDict.mapValues { $0.value }
        } else {
            data = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(receivedAt, forKey: .receivedAt)
        try container.encode(type, forKey: .type)
        
        if let data = data {
            let encodableData = data.mapValues { AnyCodable($0) }
            try container.encode(encodableData, forKey: .data)
        }
    }
}

/// Type of notification
public enum NotificationType: String, Codable, CaseIterable {
    case push
    case inApp = "in-app"
}

/// Notification event types
public enum NotificationEvent {
    case received(NotifyLightNotification)
    case opened(NotifyLightNotification)
    case tokenReceived(String)
    case tokenRefresh(String)
    case registrationError(Error)
}

/// In-app message model
public struct InAppMessage: Codable {
    public let id: String
    public let title: String
    public let message: String
    public let actions: [MessageAction]
    public let data: [String: Any]?
    public let createdAt: Date
    public let expiresAt: Date?
    public let isRead: Bool
    
    public init(
        id: String,
        title: String,
        message: String,
        actions: [MessageAction] = [],
        data: [String: Any]? = nil,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.actions = actions
        self.data = data
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isRead = isRead
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case message
        case actions
        case data
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case isRead = "is_read"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        actions = try container.decodeIfPresent([MessageAction].self, forKey: .actions) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        
        // Handle data as flexible dictionary
        if let dataDict = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data) {
            data = dataDict.mapValues { $0.value }
        } else {
            data = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(actions, forKey: .actions)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encode(isRead, forKey: .isRead)
        
        if let data = data {
            let encodableData = data.mapValues { AnyCodable($0) }
            try container.encode(encodableData, forKey: .data)
        }
    }
}

/// Action button for in-app messages
public struct MessageAction: Codable {
    public let id: String
    public let title: String
    public let style: ActionStyle
    public let data: [String: Any]?
    
    public init(
        id: String,
        title: String,
        style: ActionStyle = .primary,
        data: [String: Any]? = nil
    ) {
        self.id = id
        self.title = title
        self.style = style
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case style
        case data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        style = try container.decodeIfPresent(ActionStyle.self, forKey: .style) ?? .primary
        
        // Handle data as flexible dictionary
        if let dataDict = try container.decodeIfPresent([String: AnyCodable].self, forKey: .data) {
            data = dataDict.mapValues { $0.value }
        } else {
            data = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(style, forKey: .style)
        
        if let data = data {
            let encodableData = data.mapValues { AnyCodable($0) }
            try container.encode(encodableData, forKey: .data)
        }
    }
}

/// Action button style
public enum ActionStyle: String, Codable, CaseIterable {
    case primary
    case secondary
    case destructive
}

/// Helper for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode value"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value")
            )
        }
    }
}
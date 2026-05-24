public import struct Foundation::Date
public import struct Foundation::TimeInterval

public enum SweeplineVerb: Hashable, Sendable {
    // yes/no
    case yes
    // down/up
    case down
    
}

public struct SweeplineRequest: Codable, Hashable, Sendable {
    public let verb: SweeplineVerb
    public let value: Bool
    
    public let date: Date
    public let idempotencyID: String
    public let senderID: String?
    public let zoneID: String?
    public let durationHeld: TimeInterval?
    
    public init(
        verb: SweeplineVerb,
        value: Bool,
        date: Date,
        idempotencyID: String,
        senderID: String? = nil,
        zoneID: String? = nil,
        durationHeld: TimeInterval? = nil,
    ) {
        self.verb = verb
        self.value = value
        self.date = date
        self.idempotencyID = idempotencyID
        self.senderID = senderID
        self.zoneID = zoneID
        self.durationHeld = durationHeld
        
    }
    
    enum CodingKeys: String, CodingKey {
        case isYes = "is-yes"
        case isDown = "is-down"
        case date
        case idempotencyID = "idempotency-id"
        case senderID = "sender-id"
        case zoneID = "zone-id"
        case durationHeld = "duration-held"
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let yesValue = try container.decodeIfPresent(Bool.self, forKey: .isYes)
        let downValue = try container.decodeIfPresent(Bool.self, forKey: .isDown)
        
        switch (yesValue, downValue) {
        case (.some(let value), .none):
            self.verb = .yes
            self.value = value
            
        case (.none, .some(let value)):
            self.verb = .down
            self.value = value
            
        case (.some, .some):
            throw DecodingError.dataCorruptedError(
                forKey: .isDown,
                in: container,
                debugDescription: "Sweepline request must contain only one verb key."
            )
            
        case (.none, .none):
            throw DecodingError.keyNotFound(
                CodingKeys.isYes,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Sweepline request must contain either is-yes or is-down."
                )
            )
            
        }
        
        self.date = try container.decode(Date.self, forKey: .date)
        self.idempotencyID = try container.decode(String.self, forKey: .idempotencyID)
        self.senderID = try container.decodeIfPresent(String.self, forKey: .senderID)
        self.zoneID = try container.decodeIfPresent(String.self, forKey: .zoneID)
        self.durationHeld = try container.decodeIfPresent(TimeInterval.self, forKey: .durationHeld)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch verb {
        case .yes:
            try container.encode(value, forKey: .isYes)
        case .down:
            try container.encode(value, forKey: .isDown)
        }
        
        try container.encode(date, forKey: .date)
        try container.encode(idempotencyID, forKey: .idempotencyID)
        try container.encodeIfPresent(senderID, forKey: .senderID)
        try container.encodeIfPresent(zoneID, forKey: .zoneID)
        try container.encodeIfPresent(durationHeld, forKey: .durationHeld)
        
    }
    
}

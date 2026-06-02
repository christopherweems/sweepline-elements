public import struct Foundation::Date
public import struct Foundation::TimeInterval

public enum SweeplineVerb: Hashable, Sendable {
    // tap/release
    case tap
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
    public let isFirstContact: Bool?
    public let contactType: SweeplineContactMode?
    
    public init(
        verb: SweeplineVerb,
        value: Bool,
        date: Date,
        idempotencyID: String,
        senderID: String? = nil,
        zoneID: String? = nil,
        durationHeld: TimeInterval? = nil,
        isFirstContact: Bool? = nil,
        contactType: SweeplineContactMode? = nil,
    ) {
        self.verb = verb
        self.value = value
        self.date = date
        self.idempotencyID = idempotencyID
        self.senderID = senderID
        self.zoneID = zoneID
        self.durationHeld = durationHeld
        self.isFirstContact = isFirstContact
        self.contactType = contactType
        
    }
    
    enum CodingKeys: String, CodingKey {
        case isTap = "is-tap"
        case isYes = "is-yes"
        case isDown = "is-down"
        case contactType = "contact-type"
        case date
        case idempotencyID = "idempotency-id"
        case senderID = "sender-id"
        case zoneID = "zone-id"
        case durationHeld = "duration-held"
        case isFirstContact = "is-first-contact"
        
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tapValue = try container.decodeIfPresent(Bool.self, forKey: .isTap)
        let yesValue = try container.decodeIfPresent(Bool.self, forKey: .isYes)
        let downValue = try container.decodeIfPresent(Bool.self, forKey: .isDown)
        let contactType = try container.decodeIfPresent(SweeplineContactMode.self, forKey: .contactType)
        
        let verbValues: [(SweeplineVerb, Bool, CodingKeys)] = [
            (.tap, tapValue, .isTap),
            (.yes, yesValue, .isYes),
            (.down, downValue, .isDown),
        ].compactMap { verb, value, key in
            value.map { (verb, $0, key) }
        }
        
        switch verbValues.count {
        case 1:
            self.verb = verbValues[0].0
            self.value = verbValues[0].1
            
        case 0:
            throw DecodingError.keyNotFound(
                CodingKeys.isYes,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Sweepline request must contain one of is-tap, is-yes, or is-down."
                )
            )
            
        default:
            throw DecodingError.dataCorruptedError(
                forKey: verbValues[1].2,
                in: container,
                debugDescription: "Sweepline request must contain only one verb key."
            )
            
        }
        
        self.date = try container.decode(Date.self, forKey: .date)
        self.idempotencyID = try container.decode(String.self, forKey: .idempotencyID)
        self.senderID = try container.decodeIfPresent(String.self, forKey: .senderID)
        self.zoneID = try container.decodeIfPresent(String.self, forKey: .zoneID)
        self.durationHeld = try container.decodeIfPresent(TimeInterval.self, forKey: .durationHeld)
        self.isFirstContact = try container.decodeIfPresent(Bool.self, forKey: .isFirstContact)
        self.contactType = contactType
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch verb {
        case .tap:
            try container.encode(value, forKey: .isTap)
        case .yes:
            try container.encode(value, forKey: .isYes)
        case .down:
            try container.encode(value, forKey: .isDown)
        }
        
        try container.encodeIfPresent(contactType, forKey: .contactType)
        try container.encode(date, forKey: .date)
        try container.encode(idempotencyID, forKey: .idempotencyID)
        try container.encodeIfPresent(senderID, forKey: .senderID)
        try container.encodeIfPresent(zoneID, forKey: .zoneID)
        try container.encodeIfPresent(durationHeld, forKey: .durationHeld)
        try container.encodeIfPresent(isFirstContact, forKey: .isFirstContact)
        
    }
    
}

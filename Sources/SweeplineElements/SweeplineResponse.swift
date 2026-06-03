public struct SweeplineResponse: Hashable, Sendable {
    public let version: SweeplineVersion
    public let contactMode: SweeplineContactMode
    public let value: Bool?
    public let destinationURL: String?
    
    public init(
        version: SweeplineVersion = .v1_1,
        contactMode: SweeplineContactMode,
        value: Bool?,
        destinationURL: String? = nil,
    ) {
        precondition(contactMode != .tap || value != false, "tap value must be true")
        self.version = version
        self.contactMode = contactMode
        self.value = value
        self.destinationURL = destinationURL
        
    }
        
}

extension SweeplineResponse : Encodable {
    enum CodingKeys: String, CodingKey {
        case version = "sweepline-version"
        case isYes = "is-yes"
        case isDown = "is-down"
        case contactMode = "contact-mode"
        case destinationURL = "destination-url"
        
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(version, forKey: .version)
        switch (contactMode, value) {
        case (.tap, _):
            try container.encode(contactMode, forKey: .contactMode)
        case (.yes, .some(let value)):
            try container.encode(value, forKey: .isYes)
        case (.yes, .none):
            try container.encode(contactMode, forKey: .contactMode)
        case (.down, .some(let value)):
            try container.encode(value, forKey: .isDown)
        case (.down, .none):
            try container.encode(contactMode, forKey: .contactMode)
        }
        try container.encodeIfPresent(destinationURL, forKey: .destinationURL)
        
    }
    
}

extension SweeplineResponse : Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let contactMode = try container.decodeIfPresent(SweeplineContactMode.self, forKey: .contactMode)
        let yesValue = try container.decodeIfPresent(Bool.self, forKey: .isYes)
        let downValue = try container.decodeIfPresent(Bool.self, forKey: .isDown)
        
        if yesValue != nil && downValue != nil {
            throw DecodingError.dataCorruptedError(
                forKey: .isDown,
                in: container,
                debugDescription: "Sweepline response must contain only one value specifier."
            )
        }
        
        switch (contactMode, yesValue, downValue) {
        case (_, .some, .some):
            throw DecodingError.dataCorruptedError(
                forKey: .isDown,
                in: container,
                debugDescription: "Sweepline response must contain only one value specifier."
            )
            
        case (.some(.tap), .none, .none):
            self.contactMode = .tap
            self.value = true
            
        case (.some(.tap), .some, _), (.some(.tap), _, .some):
            throw DecodingError.dataCorruptedError(
                forKey: .contactMode,
                in: container,
                debugDescription: "Sweepline tap responses must not contain is-yes or is-down."
            )
            
        case (.some(.yes), .some(let value), .none), (.none, .some(let value), .none):
            self.contactMode = .yes
            self.value = value
            
        case (.some(.down), .none, .some(let value)), (.none, .none, .some(let value)):
            self.contactMode = .down
            self.value = value
            
        case (.some(.yes), .none, .none):
            self.contactMode = .yes
            self.value = nil
            
        case (.some(.down), .none, .none):
            self.contactMode = .down
            self.value = nil
            
        case (.some(.yes), .none, .some), (.some(.down), .some, .none):
            throw DecodingError.dataCorruptedError(
                forKey: .contactMode,
                in: container,
                debugDescription: "Sweepline response contact-mode must match the value specifier."
            )
            
        case (.none, .none, .none):
            throw DecodingError.keyNotFound(
                CodingKeys.contactMode,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Sweepline response must contain contact-mode, is-yes, or is-down."
                )
            )
            
        }
        
        self.version = try container.decode(SweeplineVersion.self, forKey: .version)
        self.destinationURL = try container.decodeIfPresent(String.self, forKey: .destinationURL)
        
    }
    
}

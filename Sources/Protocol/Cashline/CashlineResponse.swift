public struct CashlineResponse: Codable, Hashable, Sendable {
    public let eventType: CashlineEventType
    public let accepted: Bool

    public init(eventType: CashlineEventType, accepted: Bool) {
        self.eventType = eventType
        self.accepted = accepted
        
    }

    enum CodingKeys: String, CodingKey {
        case eventType = "event-type"
        case accepted
        
    }
    
}

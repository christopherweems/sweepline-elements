public import struct Foundation::Date

public struct CashlineRequest: Codable, Hashable, Sendable {
    public let eventType: CashlineEventType
    public let date: Date
    public let idempotencyID: String

    public init(
        eventType: CashlineEventType,
        date: Date,
        idempotencyID: String
    ) {
        self.eventType = eventType
        self.date = date
        self.idempotencyID = idempotencyID
        
    }
    
    enum CodingKeys: String, CodingKey {
        case eventType = "event-type"
        case date
        case idempotencyID = "idempotency-id"
        
    }
    
}

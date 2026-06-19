public struct SweetfeetResponse: Codable, Hashable, Sendable {
  public let eventType: SweetfeetEventType
  public let accepted: Bool
  
  public init(eventType: SweetfeetEventType, accepted: Bool) {
    self.eventType = eventType
    self.accepted = accepted
  }
  
  enum CodingKeys: String, CodingKey {
    case eventType = "event-type"
    case accepted
  }
}

public typealias CashlineResponse = SweetfeetResponse

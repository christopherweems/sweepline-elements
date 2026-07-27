public struct SweetfeetResponse: Codable, Hashable, Sendable {
  public let eventType: SweetfeetEventType
  public let accepted: Bool
  public let productID: String?
  
  public init(eventType: SweetfeetEventType, accepted: Bool, productID: String?) {
    self.eventType = eventType
    self.accepted = accepted
    self.productID = productID
  }
  
  enum CodingKeys: String, CodingKey {
    case eventType = "event-type"
    case accepted
    case productID = "product-id"
  }
}

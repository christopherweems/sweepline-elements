@_exported public import BeepSigning
public import struct Foundation.Date

public struct SweetfeetItemPriceCheckRequest: Codable, Hashable, Sendable {
  public let eventType: SweetfeetEventType
  public let senderID: String?
  public let zoneID: String?
  public let productID: String
  public let date: Date
  public let idempotencyID: String

  public init(
    senderID: String?,
    zoneID: String?,
    productID: String,
    date: Date,
    idempotencyID: String
  ) {
    self.eventType = .itemPriceCheck
    self.senderID = senderID?.isEmpty == true ? nil : senderID
    self.zoneID = zoneID?.isEmpty == true ? nil : zoneID
    self.productID = productID
    self.date = date
    self.idempotencyID = idempotencyID
  }

  enum CodingKeys: String, CodingKey {
    case eventType = "event-type"
    case senderID = "sender-id"
    case zoneID = "zone-id"
    case productID = "product-id"
    case date
    case idempotencyID = "idempotency-id"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let eventType = try container.decode(SweetfeetEventType.self, forKey: .eventType)
    guard eventType == .itemPriceCheck else {
      throw DecodingError.dataCorruptedError(
        forKey: .eventType,
        in: container,
        debugDescription: "Sweetfeet item price requests must use event-type item-price-check."
      )
    }

    self.eventType = eventType
    self.senderID = try container.decodeIfPresent(String.self, forKey: .senderID)
    self.zoneID = try container.decodeIfPresent(String.self, forKey: .zoneID)
    self.productID = try container.decode(String.self, forKey: .productID)
    self.date = try container.decode(Date.self, forKey: .date)
    self.idempotencyID = try container.decode(String.self, forKey: .idempotencyID)
  }
}

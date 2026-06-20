public struct SweetfeetItemPriceCheckResponse: Codable, Hashable, Sendable {
  public let eventType: SweetfeetEventType
  public let productID: String
  public let pricePerItem: String
  public let currency: String
  public let unit: String?

  public init(
    productID: String,
    pricePerItem: String,
    currency: String,
    unit: String? = nil
  ) {
    self.eventType = .itemPriceCheck
    self.productID = productID
    self.pricePerItem = pricePerItem
    self.currency = currency
    self.unit = unit
  }

  enum CodingKeys: String, CodingKey {
    case eventType = "event-type"
    case productID = "product-id"
    case pricePerItem = "price-per-item"
    case currency
    case unit
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let eventType = try container.decode(SweetfeetEventType.self, forKey: .eventType)
    guard eventType == .itemPriceCheck else {
      throw DecodingError.dataCorruptedError(
        forKey: .eventType,
        in: container,
        debugDescription: "Sweetfeet price-per-item inquiry responses must use event-type item-price-check."
      )
    }

    self.eventType = eventType
    self.productID = try container.decode(String.self, forKey: .productID)
    self.pricePerItem = try container.decode(String.self, forKey: .pricePerItem)
    self.currency = try container.decode(String.self, forKey: .currency)
    self.unit = try container.decodeIfPresent(String.self, forKey: .unit)
  }
}

public typealias CashlinePricePerItemInquiryResponse = SweetfeetItemPriceCheckResponse

@_exported public import SweeplineSigning
public import struct Foundation::Date
public import struct Foundation::TimeInterval

public struct SweetfeetRequest: Codable, Hashable, Sendable {
  public let eventType: SweetfeetEventType
  public let senderID: String?
  public let zoneID: String?
  
  public let productID: String
  public let quantity: Int
  public let unit: String? // `lbs`, `liter`, ..
  
  public let pricePerItem: String
  public let currency: String
  public let paymentOptions: [SweetfeetPaymentOption]?
  public let note: String?
  public let expirationDate: Date?
  
  public let date: Date
  public let idempotencyID: String
  
  public init(
    eventType: SweetfeetEventType,
    senderID: String?,
    zoneID: String?,
    productID: String,
    quantity: Int,
    unit: String? = nil,
    pricePerItem: String,
    currency: String,
    paymentOptions: [SweetfeetPaymentOption]? = nil,
    note: String? = nil,
    expirationDate: Date? = nil,
    date: Date,
    idempotencyID: String,
  ) {
    self.eventType = eventType
    self.senderID = senderID?.isEmpty == true ? nil : senderID
    self.zoneID = zoneID?.isEmpty == true ? nil : zoneID
    self.productID = productID
    self.quantity = quantity
    self.unit = unit
    self.pricePerItem = pricePerItem
    self.currency = currency
    self.paymentOptions = paymentOptions?.isEmpty == true ? nil : paymentOptions
    self.note = note
    self.expirationDate = expirationDate
    self.date = date
    self.idempotencyID = idempotencyID
  }
  
  enum CodingKeys: String, CodingKey {
    case eventType = "event-type"
    case senderID = "sender-id"
    case zoneID = "zone-id"
    case productID = "product-id"
    case quantity
    case unit
    case pricePerItem = "price-per-item"
    case currency
    case paymentOptions = "payment-options"
    case note
    case expirationDate = "expiration-date"
    case date
    case idempotencyID = "idempotency-id"
  }
}

public struct SweetfeetPaymentOption: Codable, Hashable, Sendable {
  public let amount: String?
  public let currency: String?
  public let description: String?
  
  public init(
    amount: String,
    currency: String,
  ) {
    self.amount = amount
    self.currency = currency
    self.description = nil
  }
  
  public init(description: String) {
    self.amount = nil
    self.currency = nil
    self.description = description
  }
}

public typealias CashlineRequest = SweetfeetRequest

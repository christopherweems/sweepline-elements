public enum SweetfeetVerb: String, Codable, Hashable, Sendable {
  case tap
  case sale
  case itemPriceCheck = "item-price-check"
}

public typealias SweetfeetEventType = SweetfeetVerb
public typealias CashlineVerb = SweetfeetVerb
public typealias CashlineEventType = SweetfeetEventType

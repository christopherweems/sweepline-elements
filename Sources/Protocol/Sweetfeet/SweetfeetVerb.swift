public enum SweetfeetVerb: String, Codable, Hashable, Sendable {
  case tap
  case sale
}

public typealias SweetfeetEventType = SweetfeetVerb
public typealias CashlineVerb = SweetfeetVerb
public typealias CashlineEventType = SweetfeetEventType

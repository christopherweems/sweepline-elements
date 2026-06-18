public enum CashlineVerb: String, Codable, Hashable, Sendable {
  case tap
  case sale
}

public typealias CashlineEventType = CashlineVerb

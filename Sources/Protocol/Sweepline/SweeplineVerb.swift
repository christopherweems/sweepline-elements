public enum SweeplineVerb: String, Codable, Hashable, Sendable {
  case tap
  case yes
  case down
}

public typealias SweeplineContactMode = SweeplineVerb
public typealias SweeplineContactType = SweeplineVerb

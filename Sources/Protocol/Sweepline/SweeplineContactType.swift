public enum SweeplineContactType: String, Codable, Hashable, Sendable {
    case tap
    case yes
    case down
    
}

public typealias SweeplineContactMode = SweeplineContactType
public typealias SweeplineVerb = SweeplineContactType

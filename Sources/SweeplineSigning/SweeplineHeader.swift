public enum BeepHeader: String, CaseIterable, Sendable {
  case signatureAlgorithm = "X-Beeper-Signature-Algorithm"
  case keyID = "X-Beeper-Key-ID"
  case publicKey = "X-Beeper-Public-Key"
  case signature = "X-Beeper-Signature"

  public var legacyRawValue: String {
    switch self {
    case .signatureAlgorithm:
      "X-Sweepline-Signature-Algorithm"
    case .keyID:
      "X-Sweepline-Key-ID"
    case .publicKey:
      "X-Sweepline-Public-Key"
    case .signature:
      "X-Sweepline-Signature"
    }
  }

  public var acceptedRawValues: [String] {
    [rawValue, legacyRawValue]
  }
}

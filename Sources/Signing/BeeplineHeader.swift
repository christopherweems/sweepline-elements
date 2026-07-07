public enum BeeplineHeader: String, CaseIterable, Sendable {
  case signatureAlgorithm = "X-Beepline-Signature-Algorithm"
  case keyID = "X-Beepline-Key-ID"
  case publicKey = "X-Beepline-Public-Key"
  case signature = "X-Beepline-Signature"

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

public enum SweeplineHeader: String, CaseIterable, Sendable {
    case signatureAlgorithm = "X-Sweepline-Signature-Algorithm"
    case keyID = "X-Sweepline-Key-ID"
    case publicKey = "X-Sweepline-Public-Key"
    case signature = "X-Sweepline-Signature"
}

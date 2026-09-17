public enum SweeplineHeader: String, CaseIterable, Sendable {
  case version = "X-Sweepline-Version"
  case issuedAt = "X-Sweepline-Issued-At"
  case nonce = "X-Sweepline-Nonce"
  case signatureAlgorithm = "X-Sweepline-Signature-Algorithm"
  case keyID = "X-Sweepline-Key-ID"
  case publicKey = "X-Sweepline-Public-Key"
  case signature = "X-Sweepline-Signature"
}

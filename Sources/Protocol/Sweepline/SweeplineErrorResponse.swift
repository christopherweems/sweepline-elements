/// A protocol rejection. Servers should return this with a non-success HTTP status.
/// Codes are strings so clients can recognize future errors without losing protocol identity.
public struct SweeplineErrorResponse: Codable, Hashable, Sendable {
  public let version: String
  public let error: String
  public let message: String?

  public init(version: String = SweeplineVersion.v2_0.rawValue, error: String, message: String? = nil) {
    self.version = version
    self.error = error
    self.message = message
  }

  enum CodingKeys: String, CodingKey {
    case version = "sweepline-version"
    case error = "sweepline-error"
    case message
  }

  public enum Code {
    public static let invalidSignature = "invalid-signature"
    public static let replayDetected = "replay-detected"
    public static let expired = "expired"
    public static let issuedInFuture = "issued-in-future"
    public static let unauthorized = "unauthorized"
    public static let invalidRequest = "invalid-request"
  }
}

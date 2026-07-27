public import struct Foundation.Data

/// The exact bytes and signature metadata received for a Sweepline-signed request.
///
/// `bodyBase64` deliberately preserves the original bytes instead of re-encoding a
/// decoded payload, because even semantically equivalent JSON would invalidate the
/// signature.
public struct SweeplineSignedArtifact: Codable, Hashable, Sendable {
  public static let defaultContentType = "application/json"

  public let contentType: String
  public let bodyBase64: String
  public let signedMessage: SweeplineSignedMessage

  public init(
    contentType: String = Self.defaultContentType,
    body: Data,
    signedMessage: SweeplineSignedMessage
  ) {
    self.contentType = contentType
    self.bodyBase64 = body.base64EncodedString()
    self.signedMessage = signedMessage
  }

  public init(
    contentType: String = Self.defaultContentType,
    bodyBase64: String,
    signedMessage: SweeplineSignedMessage
  ) {
    self.contentType = contentType
    self.bodyBase64 = bodyBase64
    self.signedMessage = signedMessage
  }

  public var body: Data? {
    Data(base64Encoded: bodyBase64)
  }

  enum CodingKeys: String, CodingKey {
    case contentType = "content-type"
    case bodyBase64 = "body"
    case signedMessage = "signature"
  }
}

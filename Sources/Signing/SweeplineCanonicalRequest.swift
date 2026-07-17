public import protocol Foundation::ContiguousBytes
public import struct Foundation::Data

public struct SweeplineCanonicalRequest: Hashable, Sendable {
  public let body: Data
  public let signedMessage: SweeplineSignedMessage

  public init(body: Data, signedMessage: SweeplineSignedMessage) {
    self.body = body
    self.signedMessage = signedMessage
  }

  public var headers: [String: String] {
    signedMessage.headers
  }
}

extension SweeplineSigner {
  public static func canonicalRequest(
    body: Data,
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) -> SweeplineCanonicalRequest {
    SweeplineCanonicalRequest(
      body: body,
      signedMessage: signedMessage(
        publicKeyRawRepresentation: publicKeyRawRepresentation,
        signature: signature
      )
    )
  }
}

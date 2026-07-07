public import protocol Foundation::ContiguousBytes
public import struct Foundation::Data

public struct BeeplineCanonicalRequest: Hashable, Sendable {
  public let body: Data
  public let signedMessage: BeeplineSignedMessage

  public init(body: Data, signedMessage: BeeplineSignedMessage) {
    self.body = body
    self.signedMessage = signedMessage
  }

  public var headers: [String: String] {
    signedMessage.headers
  }
}

extension BeeplineSigner {
  public static func canonicalRequest(
    body: Data,
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) -> BeeplineCanonicalRequest {
    BeeplineCanonicalRequest(
      body: body,
      signedMessage: signedMessage(
        publicKeyRawRepresentation: publicKeyRawRepresentation,
        signature: signature
      )
    )
  }
}

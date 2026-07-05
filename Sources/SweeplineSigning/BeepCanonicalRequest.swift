public import protocol Foundation::ContiguousBytes
public import struct Foundation::Data

public struct BeepCanonicalRequest: Hashable, Sendable {
  public let body: Data
  public let signedMessage: BeepSignedMessage

  public init(body: Data, signedMessage: BeepSignedMessage) {
    self.body = body
    self.signedMessage = signedMessage
  }

  public var headers: [String: String] {
    signedMessage.headers
  }
}

extension BeepSigner {
  public static func canonicalRequest(
    body: Data,
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) -> BeepCanonicalRequest {
    BeepCanonicalRequest(
      body: body,
      signedMessage: signedMessage(
        publicKeyRawRepresentation: publicKeyRawRepresentation,
        signature: signature
      )
    )
  }
}

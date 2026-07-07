public import protocol Foundation::ContiguousBytes

public struct BeeplineSigner: Sendable {}

extension BeeplineSigner {
  public static func signedMessage(
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) -> BeeplineSignedMessage {
    BeeplineSignedMessage(
      publicKeyRawRepresentation: publicKeyRawRepresentation,
      signature: signature
    )
  }
}

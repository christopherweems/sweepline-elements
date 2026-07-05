public import protocol Foundation::ContiguousBytes

public struct BeepSigner: Sendable {}

extension BeepSigner {
  public static func signedMessage(
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) -> BeepSignedMessage {
    BeepSignedMessage(
      publicKeyRawRepresentation: publicKeyRawRepresentation,
      signature: signature
    )
  }
}

public import protocol Foundation.ContiguousBytes

public struct SweeplineSigner: Sendable { }

extension SweeplineSigner {
    public static func signedMessage(
        publicKeyRawRepresentation: some ContiguousBytes,
        signature: some ContiguousBytes
    ) -> SweeplineSignedMessage {
        SweeplineSignedMessage(
            publicKeyRawRepresentation: publicKeyRawRepresentation,
            signature: signature
        )
    }
    
}

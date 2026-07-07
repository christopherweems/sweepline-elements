public import struct Foundation::Data
private import Crypto

public struct BeeplineVerifier: Sendable {
  public init() {}
}

extension BeeplineVerifier {
  public func verify(body: Data, signedMessage: BeeplineSignedMessage) throws -> Bool {
    try verificationResult(body: body, signedMessage: signedMessage) == .valid
  }

  public func verificationResult(
    body: Data,
    signedMessage: BeeplineSignedMessage
  ) throws(BeeplineVerificationError) -> BeeplineVerificationResult {
    guard signedMessage.signatureAlgorithm.lowercased() == BeeplineSignedMessage.algorithm else {
      throw .unsupportedSignatureAlgorithm(signedMessage.signatureAlgorithm)
    }

    guard let publicKeyData = Data(base64Encoded: signedMessage.publicKeyBase64) else {
      throw .invalidPublicKeyBase64
    }
    guard let signature = Data(base64Encoded: signedMessage.signatureBase64) else {
      throw .invalidSignatureBase64
    }

    let computedKeyID = BeeplineKeyID(publicKeyRawRepresentation: publicKeyData)
    guard computedKeyID == signedMessage.keyID else {
      throw .keyIDMismatch(expected: computedKeyID, actual: signedMessage.keyID)
    }

    do {
      let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
      return publicKey.isValidSignature(signature, for: body) ? .valid : .invalidSignature
    } catch {
      throw .invalidPublicKey
    }
  }
}

public enum BeeplineVerificationResult: Hashable, Sendable {
  case valid
  case invalidSignature
}

public enum BeeplineVerificationError: Error, Hashable, Sendable {
  case unsupportedSignatureAlgorithm(String)
  case invalidPublicKeyBase64
  case invalidSignatureBase64
  case invalidPublicKey
  case keyIDMismatch(expected: BeeplineKeyID, actual: BeeplineKeyID)
}

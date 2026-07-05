public import struct Foundation::Data
private import Crypto

public struct BeepVerifier: Sendable {
  public init() {}
}

extension BeepVerifier {
  public func verify(body: Data, signedMessage: BeepSignedMessage) throws -> Bool {
    try verificationResult(body: body, signedMessage: signedMessage) == .valid
  }

  public func verificationResult(
    body: Data,
    signedMessage: BeepSignedMessage
  ) throws(BeepVerificationError) -> BeepVerificationResult {
    guard signedMessage.signatureAlgorithm.lowercased() == BeepSignedMessage.algorithm else {
      throw .unsupportedSignatureAlgorithm(signedMessage.signatureAlgorithm)
    }

    guard let publicKeyData = Data(base64Encoded: signedMessage.publicKeyBase64) else {
      throw .invalidPublicKeyBase64
    }
    guard let signature = Data(base64Encoded: signedMessage.signatureBase64) else {
      throw .invalidSignatureBase64
    }

    let computedKeyID = BeepKeyID(publicKeyRawRepresentation: publicKeyData)
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

public enum BeepVerificationResult: Hashable, Sendable {
  case valid
  case invalidSignature
}

public enum BeepVerificationError: Error, Hashable, Sendable {
  case unsupportedSignatureAlgorithm(String)
  case invalidPublicKeyBase64
  case invalidSignatureBase64
  case invalidPublicKey
  case keyIDMismatch(expected: BeepKeyID, actual: BeepKeyID)
}

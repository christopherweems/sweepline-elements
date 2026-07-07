@_exported public import BeeplineSigning
public import struct Foundation::Data
public import protocol Foundation::ContiguousBytes

@available(*, deprecated, renamed: "BeeplineHeader")
public enum SweeplineHeader: String, CaseIterable, Sendable {
  case signatureAlgorithm = "X-Sweepline-Signature-Algorithm"
  case keyID = "X-Sweepline-Key-ID"
  case publicKey = "X-Sweepline-Public-Key"
  case signature = "X-Sweepline-Signature"

  var beeplineHeader: BeeplineHeader {
    switch self {
    case .signatureAlgorithm:
      .signatureAlgorithm
    case .keyID:
      .keyID
    case .publicKey:
      .publicKey
    case .signature:
      .signature
    }
  }

  init(_ beeplineHeader: BeeplineHeader) {
    switch beeplineHeader {
    case .signatureAlgorithm:
      self = .signatureAlgorithm
    case .keyID:
      self = .keyID
    case .publicKey:
      self = .publicKey
    case .signature:
      self = .signature
    }
  }
}

@available(*, deprecated, renamed: "BeeplineKeyID")
public struct SweeplineKeyID: RawRepresentable, Hashable, Sendable {
  public let rawValue: String

  public init?(rawValue: String) {
    guard let keyID = BeeplineKeyID(rawValue: rawValue) else {
      return nil
    }

    self.rawValue = keyID.rawValue
  }

  public init(publicKeyRawRepresentation: some ContiguousBytes) {
    self.rawValue = BeeplineKeyID(publicKeyRawRepresentation: publicKeyRawRepresentation).rawValue
  }

  init(_ keyID: BeeplineKeyID) {
    self.rawValue = keyID.rawValue
  }

  var beeplineKeyID: BeeplineKeyID {
    BeeplineKeyID(rawValue: rawValue)!
  }
}

@available(*, deprecated, renamed: "BeeplineSignedMessage")
public struct SweeplineSignedMessage: Hashable, Sendable {
  public static let algorithm = BeeplineSignedMessage.algorithm

  public let signatureAlgorithm: String
  public let keyID: SweeplineKeyID
  public let publicKeyBase64: String
  public let signatureBase64: String

  public init(
    signatureAlgorithm: String = Self.algorithm,
    keyID: SweeplineKeyID,
    publicKeyBase64: String,
    signatureBase64: String
  ) {
    self.signatureAlgorithm = signatureAlgorithm
    self.keyID = keyID
    self.publicKeyBase64 = publicKeyBase64
    self.signatureBase64 = signatureBase64
  }

  public init(
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) {
    self.init(
      keyID: SweeplineKeyID(publicKeyRawRepresentation: publicKeyRawRepresentation),
      publicKeyBase64: BeeplineSignedMessage(
        publicKeyRawRepresentation: publicKeyRawRepresentation,
        signature: signature
      ).publicKeyBase64,
      signatureBase64: BeeplineSignedMessage(
        publicKeyRawRepresentation: publicKeyRawRepresentation,
        signature: signature
      ).signatureBase64
    )
  }

  public init(headers: [String: String]) throws {
    do {
      self.init(try BeeplineSignedMessage(headers: headers))
    } catch let error as BeeplineSignedMessageHeaderError {
      throw SweeplineSignedMessageHeaderError(error)
    }
  }

  init(_ signedMessage: BeeplineSignedMessage) {
    self.signatureAlgorithm = signedMessage.signatureAlgorithm
    self.keyID = SweeplineKeyID(signedMessage.keyID)
    self.publicKeyBase64 = signedMessage.publicKeyBase64
    self.signatureBase64 = signedMessage.signatureBase64
  }

  var beeplineSignedMessage: BeeplineSignedMessage {
    BeeplineSignedMessage(
      signatureAlgorithm: signatureAlgorithm,
      keyID: keyID.beeplineKeyID,
      publicKeyBase64: publicKeyBase64,
      signatureBase64: signatureBase64
    )
  }

  public var headers: [String: String] {
    [
      SweeplineHeader.signatureAlgorithm.rawValue: signatureAlgorithm,
      SweeplineHeader.keyID.rawValue: keyID.rawValue,
      SweeplineHeader.publicKey.rawValue: publicKeyBase64,
      SweeplineHeader.signature.rawValue: signatureBase64,
    ]
  }
}

@available(*, deprecated, renamed: "BeeplineSignedMessageHeaderError")
public enum SweeplineSignedMessageHeaderError: Error, Hashable, Sendable {
  case missingHeader(SweeplineHeader)
  case duplicateHeader(String)
  case invalidKeyID(String)

  init(_ error: BeeplineSignedMessageHeaderError) {
    switch error {
    case .missingHeader(let header):
      self = .missingHeader(SweeplineHeader(header))
    case .duplicateHeader(let header):
      let legacyHeader = BeeplineHeader.allCases.first { $0.rawValue.lowercased() == header }?.legacyRawValue
      self = .duplicateHeader(legacyHeader?.lowercased() ?? header)
    case .invalidKeyID(let keyID):
      self = .invalidKeyID(keyID)
    }
  }
}

@available(*, deprecated, renamed: "BeeplineSigner")
public struct SweeplineSigner: Sendable {}

extension SweeplineSigner {
  public static func signedMessage(
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes
  ) -> SweeplineSignedMessage {
    SweeplineSignedMessage(
      BeeplineSigner.signedMessage(
        publicKeyRawRepresentation: publicKeyRawRepresentation,
        signature: signature
      )
    )
  }
}

@available(*, deprecated, renamed: "BeeplineVerifier")
public struct SweeplineVerifier: Sendable {
  public init() {}
}

extension SweeplineVerifier {
  public func verify(body: Data, signedMessage: SweeplineSignedMessage) throws -> Bool {
    try verificationResult(body: body, signedMessage: signedMessage) == .valid
  }

  public func verificationResult(
    body: Data,
    signedMessage: SweeplineSignedMessage
  ) throws(SweeplineVerificationError) -> SweeplineVerificationResult {
    do {
      let result = try BeeplineVerifier().verificationResult(
        body: body,
        signedMessage: signedMessage.beeplineSignedMessage
      )
      return SweeplineVerificationResult(result)
    } catch {
      throw SweeplineVerificationError(error as! BeeplineVerificationError)
    }
  }
}

@available(*, deprecated, renamed: "BeeplineVerificationResult")
public enum SweeplineVerificationResult: Hashable, Sendable {
  case valid
  case invalidSignature

  init(_ result: BeeplineVerificationResult) {
    switch result {
    case .valid:
      self = .valid
    case .invalidSignature:
      self = .invalidSignature
    }
  }
}

@available(*, deprecated, renamed: "BeeplineVerificationError")
public enum SweeplineVerificationError: Error, Hashable, Sendable {
  case unsupportedSignatureAlgorithm(String)
  case invalidPublicKeyBase64
  case invalidSignatureBase64
  case invalidPublicKey
  case keyIDMismatch(expected: SweeplineKeyID, actual: SweeplineKeyID)

  init(_ error: BeeplineVerificationError) {
    switch error {
    case .unsupportedSignatureAlgorithm(let algorithm):
      self = .unsupportedSignatureAlgorithm(algorithm)
    case .invalidPublicKeyBase64:
      self = .invalidPublicKeyBase64
    case .invalidSignatureBase64:
      self = .invalidSignatureBase64
    case .invalidPublicKey:
      self = .invalidPublicKey
    case .keyIDMismatch(let expected, let actual):
      self = .keyIDMismatch(expected: SweeplineKeyID(expected), actual: SweeplineKeyID(actual))
    }
  }
}

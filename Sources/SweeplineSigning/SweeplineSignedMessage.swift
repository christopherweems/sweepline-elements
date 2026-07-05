public import protocol Foundation::ContiguousBytes
/* private */ import struct Foundation::Data

public struct BeepSignedMessage: Hashable, Sendable {
  public static let algorithm = "ed25519"

  public let signatureAlgorithm: String
  public let keyID: BeepKeyID
  public let publicKeyBase64: String
  public let signatureBase64: String

  public init(
    signatureAlgorithm: String = Self.algorithm,
    keyID: BeepKeyID,
    publicKeyBase64: String,
    signatureBase64: String,
  ) {
    self.signatureAlgorithm = signatureAlgorithm
    self.keyID = keyID
    self.publicKeyBase64 = publicKeyBase64
    self.signatureBase64 = signatureBase64
  }

  public init(
    publicKeyRawRepresentation: some ContiguousBytes,
    signature: some ContiguousBytes,
  ) {
    self.init(
      keyID: BeepKeyID(publicKeyRawRepresentation: publicKeyRawRepresentation),
      publicKeyBase64: Self.base64EncodedString(publicKeyRawRepresentation),
      signatureBase64: Self.base64EncodedString(signature),
    )
  }

  public init(headers: [String: String]) throws {
    var normalizedHeaders: [String: String] = [:]
    let acceptedHeaders = Dictionary(
      uniqueKeysWithValues: BeepHeader.allCases.flatMap { header in
        header.acceptedRawValues.map { ($0.lowercased(), header) }
      }
    )

    for (key, value) in headers {
      let normalizedKey = key.lowercased()
      guard let header = acceptedHeaders[normalizedKey] else {
        normalizedHeaders[normalizedKey] = value
        continue
      }

      let canonicalKey = header.rawValue.lowercased()

      guard normalizedHeaders[canonicalKey] == nil else {
        throw BeepSignedMessageHeaderError.duplicateHeader(canonicalKey)
      }

      normalizedHeaders[canonicalKey] = value
    }

    let signatureAlgorithm = try Self.headerValue(for: .signatureAlgorithm, in: normalizedHeaders)
    let keyIDRawValue = try Self.headerValue(for: .keyID, in: normalizedHeaders)
    guard let keyID = BeepKeyID(rawValue: keyIDRawValue) else {
      throw BeepSignedMessageHeaderError.invalidKeyID(keyIDRawValue)
    }

    self.init(
      signatureAlgorithm: signatureAlgorithm,
      keyID: keyID,
      publicKeyBase64: try Self.headerValue(for: .publicKey, in: normalizedHeaders),
      signatureBase64: try Self.headerValue(for: .signature, in: normalizedHeaders),
    )
  }

  public var headers: [String: String] {
    [
      BeepHeader.signatureAlgorithm.rawValue: signatureAlgorithm,
      BeepHeader.keyID.rawValue: keyID.rawValue,
      BeepHeader.publicKey.rawValue: publicKeyBase64,
      BeepHeader.signature.rawValue: signatureBase64,
    ]
  }

  private static func headerValue(
    for header: BeepHeader,
    in normalizedHeaders: [String: String]
  ) throws -> String {
    guard let value = normalizedHeaders[header.rawValue.lowercased()] else {
      throw BeepSignedMessageHeaderError.missingHeader(header)
    }

    return value
  }

  private static func base64EncodedString(_ bytes: some ContiguousBytes) -> String {
    bytes.withUnsafeBytes { buffer in
      Data(buffer).base64EncodedString()
    }
  }
}

public enum BeepSignedMessageHeaderError: Error, Hashable, Sendable {
  case missingHeader(BeepHeader)
  case duplicateHeader(String)
  case invalidKeyID(String)
}

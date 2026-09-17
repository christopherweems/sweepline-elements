public import struct Foundation.Data
private import Crypto

/// Version 2 HTTP authorization. Verification does not consume the nonce.
public struct SweeplineHTTPAuthorization: Hashable, Sendable {
  public static let version = "2"
  public let issuedAt: Int64
  public let nonce: String
  public let signedMessage: SweeplineSignedMessage

  private init(issuedAt: Int64, nonce: String, signedMessage: SweeplineSignedMessage) {
    self.issuedAt = issuedAt
    self.nonce = nonce
    self.signedMessage = signedMessage
  }

  /// Pass original header pairs, before collapsing duplicate names into a dictionary.
  public init(headers: [(String, String)]) throws {
    var fields: [String: String] = [:]
    let names = Set(SweeplineHeader.allCases.map { $0.rawValue.lowercased() })
    for (name, value) in headers {
      let name = name.lowercased()
      guard names.contains(name) else { continue }
      guard fields[name] == nil else { throw SweeplineHTTPAuthorizationError.duplicateHeader(name) }
      guard value.utf8.count <= 128 else { throw SweeplineHTTPAuthorizationError.invalidHeader(name) }
      fields[name] = value
    }
    func field(_ header: SweeplineHeader) throws -> String {
      guard let value = fields[header.rawValue.lowercased()] else {
        throw SweeplineHTTPAuthorizationError.missingHeader(header)
      }
      return value
    }
    guard try field(.version) == Self.version else { throw SweeplineHTTPAuthorizationError.unsupportedVersion }
    let time = try field(.issuedAt)
    guard let issuedAt = Int64(time), String(issuedAt) == time, issuedAt >= 0 else {
      throw SweeplineHTTPAuthorizationError.invalidHeader(SweeplineHeader.issuedAt.rawValue.lowercased())
    }
    let nonce = try field(.nonce)
    try Self.validate(issuedAt: issuedAt, nonce: nonce)
    let message = try SweeplineSignedMessage(headers: fields)
    guard message.signatureAlgorithm == SweeplineSignedMessage.algorithm else {
      throw SweeplineHTTPAuthorizationError.invalidHeader(SweeplineHeader.signatureAlgorithm.rawValue.lowercased())
    }
    _ = try Self.bytes(message.publicKeyBase64, count: 32, header: .publicKey)
    _ = try Self.bytes(message.signatureBase64, count: 64, header: .signature)
    self.init(issuedAt: issuedAt, nonce: nonce, signedMessage: message)
  }

  public var headers: [String: String] {
    signedMessage.headers.merging([
      SweeplineHeader.version.rawValue: Self.version,
      SweeplineHeader.issuedAt.rawValue: String(issuedAt),
      SweeplineHeader.nonce.rawValue: nonce,
    ], uniquingKeysWith: { _, new in new })
  }

  /// Generates 128 random bits with the system random-number generator.
  public static func makeNonce() -> String {
    (0..<16).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max)) }.joined()
  }

  /// The only HTTP signing-input builder. See HTTP-SIGNING.md for the byte format.
  public static func signingInput(
    request: SweeplineHTTPRequest, body: Data, issuedAt: Int64, nonce: String,
    publicKey: Data
  ) throws -> Data {
    try validate(issuedAt: issuedAt, nonce: nonce)
    guard publicKey.count == 32 else { throw SweeplineVerificationError.invalidPublicKey }
    var input = Data("sweepline-http/2\0".utf8)
    let fields = [
      Data(request.method.utf8), Data(request.url.utf8), Data((request.contentType ?? "").utf8),
      Data(String(issuedAt).utf8), Data(nonce.utf8), publicKey, Data(SHA256.hash(data: body)),
    ]
    for field in fields {
      input.append(contentsOf: "\(field.count):".utf8)
      input.append(field)
    }
    return input
  }

  private static func validate(issuedAt: Int64, nonce: String) throws {
    guard issuedAt >= 0 else { throw SweeplineHTTPAuthorizationError.invalidHeader("x-sweepline-issued-at") }
    guard nonce.utf8.count == 32,
      nonce.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
      throw SweeplineHTTPAuthorizationError.invalidHeader("x-sweepline-nonce")
    }
  }

  private static func bytes(_ value: String, count: Int, header: SweeplineHeader) throws -> Data {
    guard let bytes = Data(base64Encoded: value), bytes.count == count,
      bytes.base64EncodedString() == value else {
      throw SweeplineHTTPAuthorizationError.invalidHeader(header.rawValue.lowercased())
    }
    return bytes
  }

  /// A valid signature and freshness check. The service must still authorize the key
  /// and atomically consume (audience, keyID, nonce) before admitting the request.
  public struct Verified: Hashable, Sendable {
    public let keyID: SweeplineKeyID
    public let issuedAt: Int64
    public let nonce: String
    /// Exclusive upper bound: keep the replay record until at least this Unix second.
    public let validUntil: Int64
    fileprivate init(keyID: SweeplineKeyID, issuedAt: Int64, nonce: String, validUntil: Int64) {
      self.keyID = keyID
      self.issuedAt = issuedAt
      self.nonce = nonce
      self.validUntil = validUntil
    }
  }

  fileprivate static func sign(
    request: SweeplineHTTPRequest, body: Data, issuedAt: Int64, nonce: String,
    publicKey: Data, signature: (Data) throws -> Data
  ) throws -> Self {
    let input = try signingInput(request: request, body: body, issuedAt: issuedAt, nonce: nonce, publicKey: publicKey)
    let signedMessage = SweeplineSignedMessage(publicKeyRawRepresentation: publicKey, signature: try signature(input))
    // Reject a signing callback that returns a malformed signature or uses a different key.
    guard try SweeplineVerifier().verifyArtifact(body: input, signedMessage: signedMessage) else {
      throw SweeplineHTTPAuthorizationError.invalidSignature
    }
    return Self(issuedAt: issuedAt, nonce: nonce, signedMessage: signedMessage)
  }
}

extension SweeplineSigner {
  /// The caller retains its private key and signs the supplied bytes exactly once.
  public static func httpAuthorization(
    request: SweeplineHTTPRequest, body: Data, issuedAt: Int64,
    nonce: String = SweeplineHTTPAuthorization.makeNonce(), publicKey: Data,
    sign: (Data) throws -> Data
  ) throws -> SweeplineHTTPAuthorization {
    try SweeplineHTTPAuthorization.sign(request: request, body: body, issuedAt: issuedAt,
      nonce: nonce, publicKey: publicKey, signature: sign)
  }
}

extension SweeplineVerifier {
  /// `request` must describe the actual HTTP request and an origin trusted by the
  /// service, not a destination asserted in authorization headers. Times are Unix seconds.
  /// Policy is supplied by the service; this method has no replay store or clock of its own.
  public func verifyHTTP(
    request: SweeplineHTTPRequest, body: Data, authorization: SweeplineHTTPAuthorization,
    now: Int64, maximumAge: Int64, allowedFutureSkew: Int64
  ) throws -> SweeplineHTTPAuthorization.Verified {
    guard now >= 0, maximumAge > 0, allowedFutureSkew >= 0 else {
      throw SweeplineHTTPAuthorizationError.invalidTimePolicy
    }
    let (validUntil, expiryOverflow) = authorization.issuedAt.addingReportingOverflow(maximumAge)
    let (futureLimit, skewOverflow) = now.addingReportingOverflow(allowedFutureSkew)
    guard !expiryOverflow, !skewOverflow else { throw SweeplineHTTPAuthorizationError.invalidTimePolicy }
    guard authorization.issuedAt <= futureLimit, now < validUntil else {
      throw SweeplineHTTPAuthorizationError.stale
    }
    guard let publicKey = Data(base64Encoded: authorization.signedMessage.publicKeyBase64) else {
      throw SweeplineVerificationError.invalidPublicKeyBase64
    }
    let input = try SweeplineHTTPAuthorization.signingInput(request: request, body: body,
      issuedAt: authorization.issuedAt, nonce: authorization.nonce, publicKey: publicKey)
    guard try verifyArtifact(body: input, signedMessage: authorization.signedMessage) else {
      throw SweeplineHTTPAuthorizationError.invalidSignature
    }
    return .init(keyID: authorization.signedMessage.keyID, issuedAt: authorization.issuedAt,
      nonce: authorization.nonce, validUntil: validUntil)
  }
}

public enum SweeplineHTTPAuthorizationError: Error, Hashable, Sendable {
  case invalidRequest
  case missingHeader(SweeplineHeader)
  case duplicateHeader(String)
  case invalidHeader(String)
  case unsupportedVersion
  case invalidTimePolicy
  case stale
  case invalidSignature
}

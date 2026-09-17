import Crypto
import Foundation
import Testing
import SweeplineSigning

private let nonce = "000102030405060708090a0b0c0d0e0f"
private let issuedAt: Int64 = 1_800_000_000
private let body = Data("{\"is-tap\":true}".utf8)

private func key() throws -> Curve25519.Signing.PrivateKey {
  try Curve25519.Signing.PrivateKey(rawRepresentation: Data(0..<32))
}

private func request() throws -> SweeplineHTTPRequest {
  try .init(method: "POST", url: "https://example.com/radio?x=1&x=2", contentType: "application/json")
}

private func authorization(body: Data = body, time: Int64 = issuedAt) throws -> SweeplineHTTPAuthorization {
  let key = try key()
  return try SweeplineSigner.httpAuthorization(request: request(), body: body, issuedAt: time,
    nonce: nonce, publicKey: key.publicKey.rawRepresentation, sign: key.signature(for:))
}

private func verify(
  _ authorization: SweeplineHTTPAuthorization, request actualRequest: SweeplineHTTPRequest? = nil,
  body: Data = body, now: Int64 = issuedAt, maximumAge: Int64 = 300, skew: Int64 = 30
) throws -> SweeplineHTTPAuthorization.Verified {
  try SweeplineVerifier().verifyHTTP(request: actualRequest ?? request(), body: body,
    authorization: authorization, now: now, maximumAge: maximumAge, allowedFutureSkew: skew)
}

@Test func httpAuthorizationRoundTripAndMinimalHeaders() throws {
  let signed = try authorization()
  #expect(signed.headers.count == 7)
  let parsed = try SweeplineHTTPAuthorization(headers: signed.headers.map { ($0.key.lowercased(), $0.value) })
  #expect(parsed == signed)
  let verified = try verify(parsed)
  #expect(verified.keyID.rawValue == "56475aa75463474c")
  #expect(verified.issuedAt == issuedAt)
  #expect(verified.nonce == nonce)
  #expect(verified.validUntil == issuedAt + 300)
  // The library is deliberately stateless. Only a service's atomic nonce reservation
  // can turn repeated cryptographic verification into a rejected replay.
  #expect(try verify(parsed) == verified)
}

@Test func httpAuthorizationBindsEveryRequestComponent() throws {
  let signed = try authorization()
  for changed in [
    try SweeplineHTTPRequest(method: "GET", url: "https://example.com/radio?x=1&x=2", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://other.example/radio?x=1&x=2", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com:8443/radio?x=1&x=2", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/admin?x=1&x=2", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/radio/?x=1&x=2", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/radio?x=2&x=1", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/radio?x=1", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/%72adio?x=1&x=2", contentType: "application/json"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/radio?x=1&x=2", contentType: "text/plain"),
    try SweeplineHTTPRequest(method: "POST", url: "https://example.com/radio?x=1&x=2"),
  ] {
    #expect(throws: SweeplineHTTPAuthorizationError.invalidSignature) { try verify(signed, request: changed) }
  }
  #expect(throws: SweeplineHTTPAuthorizationError.invalidSignature) { try verify(signed, body: Data("changed".utf8)) }
  for (header, value) in [
    (SweeplineHeader.issuedAt, String(issuedAt + 1)),
    (.nonce, String(repeating: "f", count: 32)),
  ] {
    var headers = signed.headers
    headers[header.rawValue] = value
    let changed = try SweeplineHTTPAuthorization(headers: headers.map { ($0.key, $0.value) })
    #expect(throws: SweeplineHTTPAuthorizationError.invalidSignature) { try verify(changed) }
  }
}

@Test func httpAuthorizationDoesNotAcceptArtifactsOrAnotherSigner() throws {
  let key = try key()
  let artifact = SweeplineSigner.signedMessage(publicKeyRawRepresentation: key.publicKey.rawRepresentation,
    signature: try key.signature(for: body))
  #expect(try SweeplineVerifier().verifyArtifact(body: body, signedMessage: artifact))
  var headers = try authorization().headers
  headers[SweeplineHeader.signature.rawValue] = artifact.signatureBase64
  let forged = try SweeplineHTTPAuthorization(headers: headers.map { ($0.key, $0.value) })
  #expect(throws: SweeplineHTTPAuthorizationError.invalidSignature) { try verify(forged) }
  let other = Curve25519.Signing.PrivateKey()
  headers[SweeplineHeader.publicKey.rawValue] = other.publicKey.rawRepresentation.base64EncodedString()
  #expect(throws: SweeplineVerificationError.self) {
    try verify(SweeplineHTTPAuthorization(headers: headers.map { ($0.key, $0.value) }))
  }
}

@Test func httpAuthorizationRejectsMissingDuplicateAndMalformedHeaders() throws {
  let signed = try authorization()
  for (name, value) in signed.headers {
    let pairs = signed.headers.map { ($0.key, $0.value) }
    for duplicateName in [name, name.lowercased()] {
      #expect(throws: SweeplineHTTPAuthorizationError.duplicateHeader(name.lowercased())) {
        try SweeplineHTTPAuthorization(headers: pairs + [(duplicateName, value)])
      }
    }
    #expect(throws: (any Error).self) {
      try SweeplineHTTPAuthorization(headers: pairs.filter { $0.0 != name })
    }
  }
  for (header, value) in [
    (SweeplineHeader.version, "1"), (.version, "02"), (.version, "3"),
    (.issuedAt, "-1"), (.issuedAt, "01800000000"), (.issuedAt, "+1800000000"),
    (.issuedAt, "1800000000.0"), (.issuedAt, "9223372036854775808"),
    (.nonce, "short"), (.nonce, String(repeating: "A", count: 32)),
    (.nonce, String(repeating: "a", count: 129)),
    (.signatureAlgorithm, "ED25519"), (.publicKey, "bad"), (.signature, "bad"),
    (.keyID, "not-a-key"),
  ] {
    var headers = signed.headers
    headers[header.rawValue] = value
    #expect(throws: (any Error).self) { try SweeplineHTTPAuthorization(headers: headers.map { ($0.key, $0.value) }) }
  }
}

@Test func httpAuthorizationFreshnessBoundariesAndOverflow() throws {
  let signed = try authorization()
  #expect(try verify(signed, now: issuedAt - 30).validUntil == issuedAt + 300)
  #expect(try verify(signed, now: issuedAt + 299).validUntil == issuedAt + 300)
  for now in [issuedAt - 31, issuedAt + 300, issuedAt + 301] {
    #expect(throws: SweeplineHTTPAuthorizationError.stale) { try verify(signed, now: now) }
  }
  for (now, age, skew): (Int64, Int64, Int64) in [(issuedAt, 0, 30), (issuedAt, 300, -1), (-1, 300, 30), (.max, 300, 30), (issuedAt, .max, 30)] {
    #expect(throws: SweeplineHTTPAuthorizationError.invalidTimePolicy) { try verify(signed, now: now, maximumAge: age, skew: skew) }
  }
}

@Test func httpAuthorizationProtectsEmptyGET() throws {
  let request = try SweeplineHTTPRequest(method: "GET", url: "https://example.com/status")
  let key = try key()
  let signed = try SweeplineSigner.httpAuthorization(request: request, body: Data(), issuedAt: issuedAt,
    publicKey: key.publicKey.rawRepresentation, sign: key.signature(for:))
  #expect(signed.nonce.count == 32)
  #expect(try verify(signed, request: request, body: Data()).keyID == signed.signedMessage.keyID)
  let other = try SweeplineHTTPRequest(method: "GET", url: "https://example.com/admin")
  #expect(throws: SweeplineHTTPAuthorizationError.invalidSignature) { try verify(signed, request: other, body: Data()) }
}

@Test func httpRequestRejectsAmbiguousInput() throws {
  for url in ["http://example.com/", "https://example.com", "https://example.com/#fragment",
    "https://user:password@example.com/", "https://example.com/bad path", "https://example.com/%zz",
    "https://example.com:0/", "https://example.com:65536/", "https://example.com/\\path"] {
    #expect(throws: SweeplineHTTPAuthorizationError.invalidRequest) { try SweeplineHTTPRequest(method: "GET", url: url) }
  }
  #expect(throws: SweeplineHTTPAuthorizationError.invalidRequest) {
    try SweeplineHTTPRequest(method: "GET\nPOST", url: "https://example.com/")
  }
  #expect(throws: SweeplineHTTPAuthorizationError.invalidRequest) {
    try SweeplineHTTPRequest(method: "GET", url: "https://example.com/", contentType: "application/json\r\nOther: x")
  }
}

@Test func httpSigningRejectsInvalidMetadataAndWrongSigningKey() throws {
  let key = try key()
  let other = Curve25519.Signing.PrivateKey()
  #expect(throws: SweeplineHTTPAuthorizationError.invalidSignature) {
    try SweeplineSigner.httpAuthorization(request: request(), body: body, issuedAt: issuedAt,
      nonce: nonce, publicKey: key.publicKey.rawRepresentation, sign: other.signature(for:))
  }
  for (time, value) in [(Int64(-1), nonce), (issuedAt, "bad-nonce")] {
    #expect(throws: SweeplineHTTPAuthorizationError.self) {
      try SweeplineHTTPAuthorization.signingInput(request: request(), body: body,
        issuedAt: time, nonce: value, publicKey: key.publicKey.rawRepresentation)
    }
  }
  #expect(throws: SweeplineVerificationError.invalidPublicKey) {
    try SweeplineHTTPAuthorization.signingInput(request: request(), body: body,
      issuedAt: issuedAt, nonce: nonce, publicKey: Data())
  }
}

@Test func httpRequestPreservesExactURLRepresentation() throws {
  for url in ["https://EXAMPLE.com:443/", "https://example.com/a%2fb?x=&x=2&", "https://example.com/?"] {
    #expect(try SweeplineHTTPRequest(method: "GET", url: url).url == url)
  }
}

@Test func httpSigningInputHasFixedFraming() throws {
  let key = try key()
  let input = try SweeplineHTTPAuthorization.signingInput(request: request(), body: body,
    issuedAt: issuedAt, nonce: nonce, publicKey: key.publicKey.rawRepresentation)
  var expected = Data("sweepline-http/2\0".utf8)
  expected.append(Data("4:POST33:https://example.com/radio?x=1&x=216:application/json10:180000000032:000102030405060708090a0b0c0d0e0f32:".utf8))
  expected.append(key.publicKey.rawRepresentation)
  expected.append(Data("32:".utf8))
  expected.append(Data(SHA256.hash(data: body)))
  #expect(input == expected)
  // Independently generated with Python cryptography's Ed25519 implementation.
  // CryptoKit may randomize signatures, so verify the fixed vector instead of
  // requiring its signer to produce the same signature bytes.
  var headers = try authorization().headers
  headers[SweeplineHeader.signature.rawValue] =
    "rp9HvmdEmoNgjbUqhrqowwSSpdQBMelcrvQruK+oblrhEJlxh8TGCassTPvOB/TN8FjOhxccHPcdN0b1fUZCCA=="
  let vector = try SweeplineHTTPAuthorization(headers: headers.map { ($0.key, $0.value) })
  #expect(try verify(vector).keyID.rawValue == "56475aa75463474c")
}

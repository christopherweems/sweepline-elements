import Crypto
import Foundation
import Testing

@testable import BeeperProtocol
@testable import SweeplinePhoto
@testable import SweetfeetElements
@testable import SweeplineElements
@testable import SweeplineSigning

/* Tests for the superseded split-upload SweeplinePhoto protocol.
@Test func sweeplinePhotoEndpointRequiresExplicitOptionsOptIn() throws {
  let endpointURL = try #require(URL(string: "https://service.example/photos"))
  let request = SweeplinePhotoEndpoint.optionsRequest(for: endpointURL)

  #expect(request.url == endpointURL)
  #expect(request.httpMethod == "OPTIONS")

  let permitted = try #require(HTTPURLResponse(
    url: endpointURL,
    statusCode: 204,
    httpVersion: nil,
    headerFields: ["sweepline-photo": "1"]
  ))
  #expect(SweeplinePhotoEndpoint.permitsDownload(permitted))

  for (statusCode, headers) in [
    (200, ["Sweepline-Photo": "1"]),
    (204, [:]),
    (204, ["Sweepline-Photo": "0"]),
    (204, ["Sweepline-Photo": "true"]),
  ] {
    let response = try #require(HTTPURLResponse(
      url: endpointURL,
      statusCode: statusCode,
      httpVersion: nil,
      headerFields: headers
    ))
    #expect(!SweeplinePhotoEndpoint.permitsDownload(response))
  }
}

@Test func sweeplinePhotoEncodesDownloadMetadata() throws {
  let imageHash = "sha256:" + String(repeating: "0123456789abcdef", count: 4)
  let photo = try SweeplinePhoto(
    imageHash: imageHash,
    memo: "Package front photo",
    byteCount: 42_000,
    mediaType: "image/jpeg",
    downloadURL: try #require(URL(string: "https://uploads.example/photo.jpg")),
    goodUntil: 1_800_000_000
  )

  let data = try JSONEncoder().encode(photo)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["image-hash"] as? String == imageHash)
  #expect(object["memo"] as? String == "Package front photo")
  #expect(object["byte-count"] as? Int64 == 42_000)
  #expect(object["media-type"] as? String == "image/jpeg")
  #expect(object["download-url"] as? String == "https://uploads.example/photo.jpg")
  #expect(object["good-until"] as? Int64 == 1_800_000_000)
  #expect(object.count == 6)
}

@Test func sweeplinePhotoUsesSweeplineSigningHeaders() throws {
  let photo = try SweeplinePhoto(
    imageHash: "sha256:" + String(repeating: "0123456789abcdef", count: 4),
    byteCount: 42_000,
    mediaType: "image/jpeg",
    downloadURL: try #require(URL(string: "https://uploads.example/photo.jpg")),
    goodUntil: 1_800_000_000
  )
  let body = try JSONEncoder().encode(photo)
  let privateKey = Curve25519.Signing.PrivateKey()
  let signature = try privateKey.signature(for: body)
  let signedPhoto = SweeplineSigner.canonicalRequest(
    body: body,
    publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
    signature: signature
  )

  #expect(signedPhoto.body == body)
  #expect(signedPhoto.headers[SweeplineHeader.signature.rawValue] != nil)
  #expect(try SweeplineVerifier().verify(
    body: signedPhoto.body,
    signedMessage: signedPhoto.signedMessage
  ))
}

@Test func sweeplinePhotoRoundTripsUnixExpiry() throws {
  let imageHash = "sha256:" + String(repeating: "abcdef0123456789", count: 4)
  let data = Data(
    #"{"image-hash":"\#(imageHash)","memo":"Delivery confirmation","byte-count":42000,"media-type":"image/jpeg","download-url":"https://uploads.example/image","good-until":1800000000}"#.utf8
  )

  let photo = try JSONDecoder().decode(SweeplinePhoto.self, from: data)

  #expect(photo.imageHash == imageHash)
  #expect(photo.memo == "Delivery confirmation")
  #expect(photo.byteCount == 42_000)
  #expect(photo.mediaType == "image/jpeg")
  #expect(photo.downloadURL.absoluteString == "https://uploads.example/image")
  #expect(photo.goodUntil == 1_800_000_000)
}

@Test func sweeplinePhotoOmitsOptionalMemo() throws {
  let imageHash = "sha256:" + String(repeating: "abcdef0123456789", count: 4)
  let photo = try SweeplinePhoto(
    imageHash: imageHash,
    byteCount: 42_000,
    mediaType: "image/jpeg",
    downloadURL: try #require(URL(string: "https://uploads.example/image")),
    goodUntil: 1_800_000_000
  )

  let data = try JSONEncoder().encode(photo)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(photo.memo == nil)
  #expect(object["memo"] == nil)
  #expect(try JSONDecoder().decode(SweeplinePhoto.self, from: data).memo == nil)
}

@Test func sweeplinePhotoStorageRequestEncodesUploadMetadata() throws {
  let imageHash = "sha256:" + String(repeating: "0123456789abcdef", count: 4)
  let request = try SweeplinePhotoStorageRequest(imageHash: imageHash, byteCount: 42_000)

  let data = try JSONEncoder().encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["image-hash"] as? String == imageHash)
  #expect(object["byte-count"] as? Int64 == 42_000)
  #expect(object["good-until"] == nil)
  #expect(object.count == 2)
  #expect(try JSONDecoder().decode(SweeplinePhotoStorageRequest.self, from: data) == request)
}

@Test func sweeplinePhotoStorageResponseBuildsPhoto() throws {
  let response = SweeplinePhotoStorageResponse(
    assetURL: try #require(URL(string: "https://uploads.example/stored-image")),
    assetUploadGoodUntil: 1_799_999_000,
    goodUntil: 1_800_000_000
  )
  let data = try JSONEncoder().encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["asset-url"] as? String == "https://uploads.example/stored-image")
  #expect(object["asset-upload-good-until"] as? Int64 == 1_799_999_000)
  #expect(object["good-until"] as? Int64 == 1_800_000_000)

  let request = try SweeplinePhotoStorageRequest(
    imageHash: "sha256:" + String(repeating: "abcdef0123456789", count: 4),
    byteCount: 42_000
  )
  let photo = try SweeplinePhoto(
    imageHash: request.imageHash,
    byteCount: request.byteCount,
    mediaType: "image/jpeg",
    downloadURL: response.assetURL,
    goodUntil: response.goodUntil
  )
  #expect(photo.downloadURL == response.assetURL)
  #expect(photo.goodUntil == response.goodUntil)
}

@Test func sweeplinePhotoStorageRequestUsesSweeplineSigningHeaders() throws {
  let request = try SweeplinePhotoStorageRequest(
    imageHash: "sha256:" + String(repeating: "abcdef0123456789", count: 4),
    byteCount: 42_000
  )
  let body = try JSONEncoder().encode(request)
  let privateKey = Curve25519.Signing.PrivateKey()
  let signature = try privateKey.signature(for: body)
  let signedRequest = SweeplineSigner.canonicalRequest(
    body: body,
    publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
    signature: signature
  )

  #expect(signedRequest.body == body)
  #expect(signedRequest.headers[SweeplineHeader.signature.rawValue] != nil)
  #expect(try SweeplineVerifier().verify(
    body: signedRequest.body,
    signedMessage: signedRequest.signedMessage
  ))
}

@Test func sweeplinePhotoStorageRequestRejectsNegativeByteCount() {
  let imageHash = "sha256:" + String(repeating: "abcdef0123456789", count: 4)

  #expect(throws: SweeplinePhotoStorageRequestError.invalidByteCount(-1)) {
    try SweeplinePhotoStorageRequest(imageHash: imageHash, byteCount: -1)
  }
}

@Test func sweeplinePhotoRejectsNoncanonicalImageHashes() throws {
  let downloadURL = try #require(URL(string: "https://uploads.example/image"))
  let uppercaseDigest = "sha256:" + String(repeating: "A", count: 64)

  for imageHash in [
    "abc123",
    "sha256:abc123",
    uppercaseDigest,
    "sha256:" + String(repeating: "g", count: 64),
    "sha256:" + String(repeating: "١", count: 64),
  ] {
    #expect(throws: SweeplinePhotoError.invalidImageHash(imageHash)) {
      try SweeplinePhoto(
        imageHash: imageHash,
        memo: "Invalid hash",
        byteCount: 42_000,
        mediaType: "image/jpeg",
        downloadURL: downloadURL,
        goodUntil: 1_800_000_000
      )
    }

    let data = try JSONEncoder().encode([
      "image-hash": imageHash,
      "byte-count": "42000",
      "download-url": downloadURL.absoluteString,
      "good-until": "1800000000",
    ])
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(SweeplinePhoto.self, from: data)
    }
  }
}

@Test func sweeplinePhotoRejectsInvalidMediaTypes() throws {
  let imageHash = "sha256:" + String(repeating: "abcdef0123456789", count: 4)
  let downloadURL = try #require(URL(string: "https://uploads.example/image"))

  for mediaType in ["", "image", "image/jpeg; charset=binary", "IMAGE/JPEG", "image//jpeg"] {
    #expect(throws: SweeplinePhotoError.invalidMediaType(mediaType)) {
      try SweeplinePhoto(
        imageHash: imageHash,
        byteCount: 42_000,
        mediaType: mediaType,
        downloadURL: downloadURL,
        goodUntil: 1_800_000_000
      )
    }
  }
}

*/

private func photoAttestation(for description: SweeplinePhotoDescription) throws -> SweeplineSignedArtifact {
  let key = Curve25519.Signing.PrivateKey()
  let body = try JSONEncoder().encode(description)
  let signedMessage = SweeplineSignedMessage(
    publicKeyRawRepresentation: key.publicKey.rawRepresentation,
    signature: try key.signature(for: body)
  )
  return SweeplineSignedArtifact(body: body, signedMessage: signedMessage)
}

@Test func sweeplinePhotoOptionsAdvertisesMaximumUploadByteCount() throws {
  let endpointURL = try #require(URL(string: "https://service.example/photos"))
  let request = SweeplinePhotoEndpoint.optionsRequest(for: endpointURL)
  #expect(request.httpMethod == "OPTIONS")

  for (value, expected) in [("42000", Int64(42_000)), ("0", Int64(0))] {
    let response = try #require(HTTPURLResponse(
      url: endpointURL, statusCode: 204, httpVersion: nil,
      headerFields: [SweeplinePhotoEndpoint.maximumUploadSizeHeader: value]))
    #expect(SweeplinePhotoEndpoint.maximumUploadSize(response) == expected)
  }

  for value in ["", "-1", "+1", "1.0", "unlimited", "9223372036854775808"] {
    let response = try #require(HTTPURLResponse(
      url: endpointURL, statusCode: 204, httpVersion: nil,
      headerFields: [SweeplinePhotoEndpoint.maximumUploadSizeHeader: value]))
    #expect(SweeplinePhotoEndpoint.maximumUploadSize(response) == nil)
  }
}

@Test func sweeplinePhotoCarriesAttestedMetadataAndInlineData() throws {
  let bytes = Data([0xff, 0xd8, 0xff])
  let description = try SweeplinePhotoDescription(
    imageHash: "sha256:" + String(repeating: "ab", count: 32),
    memo: "Package front photo", senderID: "courier-17",
    byteCount: Int64(bytes.count), mediaType: "image/jpeg")
  let photo = try SweeplinePhoto(
    description: description, attestation: photoAttestation(for: description),
    zoneID: "receiving-dock", imageData: bytes)

  let data = try JSONEncoder().encode(photo)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
  let encodedDescription = try #require(object["description"] as? [String: Any])
  #expect(encodedDescription["sender-id"] as? String == "courier-17")
  #expect(encodedDescription["zone-id"] == nil)
  #expect(object["zone-id"] as? String == "receiving-dock")
  let decoded = try JSONDecoder().decode(SweeplinePhoto.self, from: data)
  #expect(decoded.description == description)
  #expect(decoded.description.senderID == "courier-17")
  #expect(decoded.zoneID == "receiving-dock")
  #expect(decoded.imageData == bytes)
}

@Test func sweeplinePhotoSupportsDescriptionOnlyForwarding() throws {
  let description = try SweeplinePhotoDescription(
    imageHash: "sha256:" + String(repeating: "cd", count: 32),
    byteCount: 42_000, mediaType: "image/jpeg")
  let photo = try SweeplinePhoto(
    description: description, attestation: photoAttestation(for: description))

  #expect(photo.imageData == nil)
}

@Test func sweeplinePhotoRejectsMismatchedInlineData() throws {
  let description = try SweeplinePhotoDescription(
    imageHash: "sha256:" + String(repeating: "ef", count: 32),
    byteCount: 3, mediaType: "image/jpeg")
  let attestation = try photoAttestation(for: description)
  #expect(throws: SweeplinePhotoError.imageDataByteCountMismatch(expected: 3, actual: 2)) {
    try SweeplinePhoto(description: description, attestation: attestation, imageData: Data([1, 2]))
  }
}

@Test func signedMessageUsesSweeplineHeaders() throws {
  let keyID = try #require(SweeplineKeyID(rawValue: "abcdef0123456789"))
  let signedMessage = SweeplineSignedMessage(
    keyID: keyID,
    publicKeyBase64: "public-key",
    signatureBase64: "signature"
  )

  #expect(signedMessage.headers[SweeplineHeader.signatureAlgorithm.rawValue] == "ed25519")
  #expect(signedMessage.headers[SweeplineHeader.keyID.rawValue] == "abcdef0123456789")
  #expect(signedMessage.headers[SweeplineHeader.publicKey.rawValue] == "public-key")
  #expect(signedMessage.headers[SweeplineHeader.signature.rawValue] == "signature")
}

@Test func signedMessageAcceptsSweeplineHeadersCaseInsensitively() throws {
  let signedMessage = try SweeplineSignedMessage(headers: [
    "x-sweepline-signature-algorithm": "ed25519",
    "X-SWEEPLINE-KEY-ID": "abcdef0123456789",
    "X-Sweepline-Public-Key": "public-key",
    "x-Sweepline-signature": "signature",
  ])

  #expect(signedMessage.signatureAlgorithm == "ed25519")
  #expect(signedMessage.keyID.rawValue == "abcdef0123456789")
  #expect(signedMessage.publicKeyBase64 == "public-key")
  #expect(signedMessage.signatureBase64 == "signature")
}

@Test func signedMessageRejectsDuplicateNormalizedSweeplineHeader() {
  #expect(throws: SweeplineSignedMessageHeaderError.duplicateHeader("x-sweepline-key-id")) {
    try SweeplineSignedMessage(headers: [
      SweeplineHeader.signatureAlgorithm.rawValue: "ed25519",
      SweeplineHeader.keyID.rawValue: "abcdef0123456789",
      SweeplineHeader.keyID.rawValue.lowercased(): "0000000000000000",
      SweeplineHeader.publicKey.rawValue: "public-key",
      SweeplineHeader.signature.rawValue: "signature",
    ])
  }
}

@Test func canonicalRequestUsesSweeplineHeaders() throws {
  let privateKey = Curve25519.Signing.PrivateKey()
  let body = Data("beep".utf8)
  let signature = try privateKey.signature(for: body)

  let canonicalRequest = SweeplineSigner.canonicalRequest(
    body: body,
    publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
    signature: signature
  )

  #expect(canonicalRequest.body == body)
  #expect(canonicalRequest.headers[SweeplineHeader.signature.rawValue] == signature.base64EncodedString())
}

@Test func beeperMessageEncodesExpectedKeys() throws {
  let message = BeeperMessage(
    title: "Front desk",
    topic: "arrival",
    message: "Package waiting",
    messageID: "beep-001",
    date: Date(timeIntervalSince1970: 0),
    timeSensitive: true
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(message)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["title"] as? String == "Front desk")
  #expect(object["topic"] as? String == "arrival")
  #expect(object["message"] as? String == "Package waiting")
  #expect(object["message-id"] as? String == "beep-001")
  #expect(object["date"] as? String == "1970-01-01T00:00:00Z")
  #expect(object["is-time-sensitive"] as? Bool == true)
}

@Test func beeperEnvelopeRoundTripsExactSignedBody() throws {
  let privateKey = Curve25519.Signing.PrivateKey()
  let body = Data(#"{"notification":{"future-field":true}}"#.utf8)
  let signature = try privateKey.signature(for: body)
  let signedMessage = SweeplineSignedMessage(
    publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
    signature: signature
  )
  let envelope = BeeperEnvelope(
    artifact: SweeplineSignedArtifact(body: body, signedMessage: signedMessage),
    delivery: BeeperDeliveryMetadata(
      messageID: "delivery-001",
      receivedAt: Date(timeIntervalSince1970: 0)
    )
  )

  let encoded = try JSONEncoder().encode(envelope)
  let decoded = try JSONDecoder().decode(BeeperEnvelope.self, from: encoded)

  #expect(decoded.artifact.body == body)
  #expect(try SweeplineVerifier().verify(body: body, signedMessage: decoded.artifact.signedMessage))
}

@Test func verifiesValidSignature() throws {
  let privateKey = Curve25519.Signing.PrivateKey()
  let publicKeyData = privateKey.publicKey.rawRepresentation
  let body = Data(#"{"is-yes":true,"date":0,"idempotency-id":"abc"}"#.utf8)
  let signature = try privateKey.signature(for: body)

  let signedMessage = SweeplineSignedMessage(
    publicKeyRawRepresentation: publicKeyData,
    signature: signature
  )

  let verifier = SweeplineVerifier()
  let isValid = try verifier.verify(body: body, signedMessage: signedMessage)

  #expect(isValid)
}

@Test func fixedCompatibilityFixtureProducesExpectedHeadersAndVerifies() throws {
  let publicKeyBytes = Data([
    0x3d, 0x40, 0x17, 0xc3, 0xe8, 0x43, 0x89, 0x5a,
    0x92, 0xb7, 0x0a, 0xa7, 0x4d, 0x1b, 0x7e, 0xbc,
    0x9c, 0x98, 0x2c, 0xcf, 0x2e, 0xc4, 0x96, 0x8c,
    0xc0, 0xcd, 0x55, 0xf1, 0x2a, 0xf4, 0x66, 0x0c,
  ])
  let bodyBytes = Data([0x72])
  let signatureBytes = Data([
    0x92, 0xa0, 0x09, 0xa9, 0xf0, 0xd4, 0xca, 0xb8,
    0x72, 0x0e, 0x82, 0x0b, 0x5f, 0x64, 0x25, 0x40,
    0xa2, 0xb2, 0x7b, 0x54, 0x16, 0x50, 0x3f, 0x8f,
    0xb3, 0x76, 0x22, 0x23, 0xeb, 0xdb, 0x69, 0xda,
    0x08, 0x5a, 0xc1, 0xe4, 0x3e, 0x15, 0x99, 0x6e,
    0x45, 0x8f, 0x36, 0x13, 0xd0, 0xf1, 0x1d, 0x8c,
    0x38, 0x7b, 0x2e, 0xae, 0xb4, 0x30, 0x2a, 0xee,
    0xb0, 0x0d, 0x29, 0x16, 0x12, 0xbb, 0x0c, 0x00,
  ])

  let signedMessage = SweeplineSignedMessage(
    publicKeyRawRepresentation: publicKeyBytes,
    signature: signatureBytes
  )

  #expect(signedMessage.keyID.rawValue == "39f713d0a644253f")
  #expect(
    signedMessage.headers == [
      SweeplineHeader.signatureAlgorithm.rawValue: "ed25519",
      SweeplineHeader.keyID.rawValue: "39f713d0a644253f",
      SweeplineHeader.publicKey.rawValue: "PUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw=",
      SweeplineHeader.signature.rawValue:
        "kqAJqfDUyrhyDoILX2QlQKKye1QWUD+Ps3YiI+vbadoIWsHkPhWZbkWPNhPQ8R2MOHsurrQwKu6wDSkWErsMAA==",
    ])
  #expect(try SweeplineVerifier().verify(body: bodyBytes, signedMessage: signedMessage))
}

@Test func returnsVerificationResultForValidSignature() throws {
  let privateKey = Curve25519.Signing.PrivateKey()
  let publicKeyData = privateKey.publicKey.rawRepresentation
  let body = Data("body".utf8)
  let signature = try privateKey.signature(for: body)
  let signedMessage = SweeplineSigner.signedMessage(
    publicKeyRawRepresentation: publicKeyData,
    signature: signature
  )

  let result = try SweeplineVerifier().verificationResult(
    body: body,
    signedMessage: signedMessage
  )

  #expect(result == .valid)
}

@Test func rejectsMutatedBody() throws {
  let privateKey = Curve25519.Signing.PrivateKey()
  let publicKeyData = privateKey.publicKey.rawRepresentation
  let body = Data("original".utf8)
  let signature = try privateKey.signature(for: body)

  let signedMessage = SweeplineSignedMessage(
    publicKeyRawRepresentation: publicKeyData,
    signature: signature
  )

  let verifier = SweeplineVerifier()
  let isValid = try verifier.verify(body: Data("mutated".utf8), signedMessage: signedMessage)
  let result = try verifier.verificationResult(
    body: Data("mutated".utf8), signedMessage: signedMessage)

  #expect(!isValid)
  #expect(result == .invalidSignature)
}

@Test func rejectsMismatchedKeyID() throws {
  let privateKey = Curve25519.Signing.PrivateKey()
  let publicKeyData = privateKey.publicKey.rawRepresentation
  let body = Data("body".utf8)
  let signature = try privateKey.signature(for: body)
  let mismatchedKeyID = try #require(SweeplineKeyID(rawValue: "0000000000000000"))

  let signedMessage = SweeplineSignedMessage(
    keyID: mismatchedKeyID,
    publicKeyBase64: publicKeyData.base64EncodedString(),
    signatureBase64: signature.base64EncodedString()
  )

  let verifier = SweeplineVerifier()

  #expect(
    throws: SweeplineVerificationError.keyIDMismatch(
      expected: SweeplineKeyID(publicKeyRawRepresentation: publicKeyData),
      actual: mismatchedKeyID
    )
  ) {
    try verifier.verify(body: body, signedMessage: signedMessage)
  }
}

@Test func signedMessageIncludesSweeplineHeaders() throws {
  let keyID = try #require(SweeplineKeyID(rawValue: "abcdef0123456789"))
  let signedMessage = SweeplineSignedMessage(
    keyID: keyID,
    publicKeyBase64: "public-key",
    signatureBase64: "signature"
  )

  #expect(signedMessage.headers[SweeplineHeader.signatureAlgorithm.rawValue] == "ed25519")
  #expect(signedMessage.headers[SweeplineHeader.keyID.rawValue] == "abcdef0123456789")
  #expect(signedMessage.headers[SweeplineHeader.publicKey.rawValue] == "public-key")
  #expect(signedMessage.headers[SweeplineHeader.signature.rawValue] == "signature")
}

@Test func signedMessageRejectsMissingHeader() {
  #expect(throws: SweeplineSignedMessageHeaderError.missingHeader(.signature)) {
    try SweeplineSignedMessage(headers: [
      SweeplineHeader.signatureAlgorithm.rawValue: "ed25519",
      SweeplineHeader.keyID.rawValue: "abcdef0123456789",
      SweeplineHeader.publicKey.rawValue: "public-key",
    ])
  }
}

@Test func keyIDRejectsInvalidRawValues() {
  #expect(SweeplineKeyID(rawValue: "wrong") == nil)
  #expect(SweeplineKeyID(rawValue: "ABCDEF0123456789") == nil)
  #expect(SweeplineKeyID(rawValue: "abcdef012345678\u{0661}") == nil)
  #expect(SweeplineKeyID(rawValue: "abcdef0123456789")?.rawValue == "abcdef0123456789")
}

@Test func decodesRequestUsingIsYesKey() throws {
  let data = Data(#"{"is-yes":true,"date":0,"idempotency-id":"yes"}"#.utf8)
  let decoder = JSONDecoder()

  let request = try decoder.decode(SweeplineRequest.self, from: data)

  #expect(request.verb == .yes)
  #expect(request.value)
  #expect(request.idempotencyID == "yes")
}

@Test func decodesRequestUsingIsDownKey() throws {
  let data = Data(#"{"is-down":false,"date":0,"idempotency-id":"down"}"#.utf8)
  let decoder = JSONDecoder()

  let request = try decoder.decode(SweeplineRequest.self, from: data)

  #expect(request.verb == .down)
  #expect(!request.value)
  #expect(request.idempotencyID == "down")
}

@Test func decodesTapRequestWithDownContactType() throws {
  let data = Data(
    #"{"contact-type":"down","is-tap":true,"date":0,"idempotency-id":"down-tap"}"#.utf8)
  let decoder = JSONDecoder()

  let request = try decoder.decode(SweeplineRequest.self, from: data)

  #expect(request.verb == .tap)
  #expect(request.value)
  #expect(request.contactType == .down)
  #expect(request.idempotencyID == "down-tap")
}

@Test func decodesRequestUsingIsTapKey() throws {
  let data = Data(#"{"is-tap":true,"date":0,"idempotency-id":"tap"}"#.utf8)
  let decoder = JSONDecoder()

  let request = try decoder.decode(SweeplineRequest.self, from: data)

  #expect(request.verb == .tap)
  #expect(request.value)
  #expect(request.idempotencyID == "tap")
}

@Test func decodesRequestWithIsFirstContact() throws {
  let data = Data(
    #"{"is-yes":true,"date":0,"idempotency-id":"first-contact","is-first-contact":true}"#.utf8)
  let decoder = JSONDecoder()

  let request = try decoder.decode(SweeplineRequest.self, from: data)

  #expect(request.isFirstContact == true)
}

@Test func rejectsRequestWithMultipleVerbKeys() throws {
  let data = Data(
    #"{"is-tap":true,"is-yes":true,"is-down":false,"date":0,"idempotency-id":"ambiguous"}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineRequest.self, from: data)
  }
}

@Test func rejectsRequestWithIsTapAndIsDownEvenWithContactType() throws {
  let data = Data(
    #"{"contact-type":"down","is-tap":true,"is-down":false,"date":0,"idempotency-id":"ambiguous-down-tap"}"#
      .utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineRequest.self, from: data)
  }
}

@Test func encodesRequestUsingVerbKey() throws {
  let request = SweeplineRequest(
    verb: .down,
    value: true,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "encoded",
    contactType: .down
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["is-down"] as? Bool == true)
  #expect(object["contact-type"] as? String == "down")
  #expect(object["is-tap"] == nil)
  #expect(object["is-yes"] == nil)
  #expect(object["idempotency-id"] as? String == "encoded")
}

@Test func encodesTapRequestWithDownContactType() throws {
  let request = SweeplineRequest(
    verb: .tap,
    value: true,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "encoded-down-tap",
    contactType: .down
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["is-tap"] as? Bool == true)
  #expect(object["contact-type"] as? String == "down")
  #expect(object["is-down"] == nil)
  #expect(object["is-yes"] == nil)
  #expect(object["idempotency-id"] as? String == "encoded-down-tap")
}

@Test func encodesRequestUsingIsTapKey() throws {
  let request = SweeplineRequest(
    verb: .tap,
    value: true,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "encoded-tap"
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["is-tap"] as? Bool == true)
  #expect(object["is-yes"] == nil)
  #expect(object["is-down"] == nil)
}

@Test func encodesRequestWithIsFirstContact() throws {
  let request = SweeplineRequest(
    verb: .yes,
    value: true,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "encoded-first-contact",
    isFirstContact: true
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["is-first-contact"] as? Bool == true)
}

@Test func omitsNilIsFirstContact() throws {
  let request = SweeplineRequest(
    verb: .yes,
    value: true,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "encoded-without-first-contact"
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["is-first-contact"] == nil)
}

@Test func decodesSweetfeetRequestFromSamplePayload() throws {
  let data = Data(
    #"{"date":"2026-05-24T16:20:00Z","idempotency-id":"7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA","sender-id":"christopher","zone-id":"front-desk","event-type":"sale","product-id":"fz-003","quantity":3,"unit":"item","price-per-item":"5.00","currency":"USD","note":"fruit appears bruised","expiration-date":"2026-05-31T16:20:00Z"}"#.utf8)
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  let request = try decoder.decode(SweetfeetRequest.self, from: data)

  #expect(request.eventType == .sale)
  #expect(request.idempotencyID == "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA")
  #expect(request.senderID == "christopher")
  #expect(request.zoneID == "front-desk")
  #expect(request.productID == "fz-003")
  #expect(request.quantity == 3)
  #expect(request.unit == "item")
  #expect(request.pricePerItem == "5.00")
  #expect(request.currency == "USD")
  #expect(request.paymentOptions == nil)
  #expect(request.note == "fruit appears bruised")
  #expect(request.expirationDate == Date(timeIntervalSince1970: 1_780_244_400))
}

@Test func decodesSweetfeetRequestWithoutUnit() throws {
  let data = Data(
    #"{"date":"2026-05-24T16:20:00Z","idempotency-id":"7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA","sender-id":"christopher","zone-id":"front-desk","event-type":"sale","product-id":"fz-003","quantity":3,"price-per-item":"5.00","currency":"USD"}"#.utf8)
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  let request = try decoder.decode(SweetfeetRequest.self, from: data)

  #expect(request.unit == nil)
  #expect(request.pricePerItem == "5.00")
  #expect(request.currency == "USD")
  #expect(request.expirationDate == nil)
}

@Test func decodesSweetfeetRequestWithoutSenderAndZone() throws {
  let data = Data(
    #"{"date":"2026-05-24T16:20:00Z","idempotency-id":"7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA","event-type":"sale","product-id":"fz-003","quantity":3,"price-per-item":"5.00","currency":"USD"}"#.utf8)
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  let request = try decoder.decode(SweetfeetRequest.self, from: data)

  #expect(request.senderID == nil)
  #expect(request.zoneID == nil)
  #expect(request.pricePerItem == "5.00")
  #expect(request.currency == "USD")
}

@Test func decodesSweetfeetRequestWithoutPriceFields() throws {
  let data = Data(
    #"{"date":"2026-05-24T16:20:00Z","idempotency-id":"7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA","event-type":"sale","product-id":"fz-003","quantity":3}"#.utf8)
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  let request = try decoder.decode(SweetfeetRequest.self, from: data)

  #expect(request.pricePerItem == nil)
  #expect(request.currency == nil)
}

@Test func encodesSweetfeetRequestUsingKebabCaseKeys() throws {
  let request = SweetfeetRequest(
    eventType: .sale,
    senderID: "christopher",
    zoneID: "front-desk",
    productID: "fz-003",
    quantity: 3,
    unit: "item",
    pricePerItem: "5.00",
    currency: "USD",
    paymentOptions: [
      SweetfeetPaymentOption(amount: "2", currency: "USD"),
      SweetfeetPaymentOption(description: "lightly used iPod mini"),
    ],
    note: "fruit appears bruised",
    expirationDate: Date(timeIntervalSince1970: 1_780_244_400),
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA"
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["date"] as? String == "1970-01-01T00:00:00Z")
  #expect(object["idempotency-id"] as? String == "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA")
  #expect(object["sender-id"] as? String == "christopher")
  #expect(object["zone-id"] as? String == "front-desk")
  #expect(object["event-type"] as? String == "sale")
  #expect(object["product-id"] as? String == "fz-003")
  #expect((object["quantity"] as? NSNumber)?.intValue == 3)
  #expect(object["unit"] as? String == "item")
  #expect(object["price-per-item"] as? String == "5.00")
  #expect(object["currency"] as? String == "USD")
  let paymentOptions = try #require(object["payment-options"] as? [[String: Any]])
  #expect(paymentOptions.count == 2)
  #expect(paymentOptions[0]["amount"] as? String == "2")
  #expect(paymentOptions[0]["currency"] as? String == "USD")
  #expect(paymentOptions[0]["description"] == nil)
  #expect(paymentOptions[1]["amount"] == nil)
  #expect(paymentOptions[1]["currency"] == nil)
  #expect(paymentOptions[1]["description"] as? String == "lightly used iPod mini")
  #expect(object["note"] as? String == "fruit appears bruised")
  #expect(object["expiration-date"] as? String == "2026-05-31T16:20:00Z")
}

@Test func encodesSweetfeetRequestWithoutUnitOmittingKey() throws {
  let request = SweetfeetRequest(
    eventType: .sale,
    senderID: "christopher",
    zoneID: "front-desk",
    productID: "fz-003",
    quantity: 3,
    pricePerItem: "5.00",
    currency: "USD",
    note: "fruit appears bruised",
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA"
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["unit"] == nil)
}

@Test func encodesSweetfeetRequestWithoutSenderAndZoneOmittingKeys() throws {
  let request = SweetfeetRequest(
    eventType: .sale,
    senderID: nil,
    zoneID: nil,
    productID: "fz-003",
    quantity: 3,
    pricePerItem: "5.00",
    currency: "USD",
    note: nil,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA"
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["sender-id"] == nil)
  #expect(object["zone-id"] == nil)
}

@Test func encodesSweetfeetRequestWithoutPriceOmittingKeys() throws {
  let request = SweetfeetRequest(
    eventType: .sale,
    senderID: "christopher",
    zoneID: "front-desk",
    productID: "fz-003",
    quantity: 3,
    note: nil,
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA"
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["price-per-item"] == nil)
  #expect(object["currency"] == nil)
}

@Test func decodesSweetfeetPricePerItemInquiryEventType() throws {
  let eventType = try JSONDecoder().decode(
    SweetfeetEventType.self,
    from: Data(#""item-price-check""#.utf8)
  )

  #expect(eventType == .itemPriceCheck)
}

@Test func encodesSweetfeetPricePerItemInquiryRequest() throws {
  let request = SweetfeetItemPriceCheckRequest(
    senderID: "christopher",
    zoneID: "front-desk",
    productID: "fz-003",
    date: Date(timeIntervalSince1970: 0),
    idempotencyID: "price-inquiry-001"
  )
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(request)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["event-type"] as? String == "item-price-check")
  #expect(object["sender-id"] as? String == "christopher")
  #expect(object["zone-id"] as? String == "front-desk")
  #expect(object["product-id"] as? String == "fz-003")
  #expect(object["date"] as? String == "1970-01-01T00:00:00Z")
  #expect(object["idempotency-id"] as? String == "price-inquiry-001")
  #expect(object["quantity"] == nil)
  #expect(object["price-per-item"] == nil)
  #expect(object["currency"] == nil)
}

@Test func decodesSweetfeetPricePerItemInquiryRequest() throws {
  let data = Data(
    #"{"date":"2026-05-24T16:20:00Z","idempotency-id":"price-inquiry-001","sender-id":"christopher","zone-id":"front-desk","event-type":"item-price-check","product-id":"fz-003"}"#.utf8)
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601

  let request = try decoder.decode(SweetfeetItemPriceCheckRequest.self, from: data)

  #expect(request.eventType == .itemPriceCheck)
  #expect(request.senderID == "christopher")
  #expect(request.zoneID == "front-desk")
  #expect(request.productID == "fz-003")
  #expect(request.date == Date(timeIntervalSince1970: 1_779_639_600))
  #expect(request.idempotencyID == "price-inquiry-001")
}

@Test func encodesSweetfeetPricePerItemInquiryResponse() throws {
  let response = SweetfeetItemPriceCheckResponse(
    productID: "fz-003",
    productNotes: "Fizzy Zero is the one you want",
    pricePerItem: "5.00",
    currency: "USD",
    unit: "item"
  )
  let data = try JSONEncoder().encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["event-type"] as? String == "item-price-check")
  #expect(object["product-id"] as? String == "fz-003")
  #expect(object["product-notes"] as? String == "Fizzy Zero is the one you want")
  #expect(object["price-per-item"] as? String == "5.00")
  #expect(object["currency"] as? String == "USD")
  #expect(object["unit"] as? String == "item")
}

@Test func decodesSweetfeetPricePerItemInquiryResponseWithoutUnit() throws {
  let data = Data(
    #"{"event-type":"item-price-check","product-id":"fz-003","product-notes":"Fizzy Zero is the one you want","price-per-item":"5.00","currency":"USD"}"#.utf8)

  let response = try JSONDecoder().decode(SweetfeetItemPriceCheckResponse.self, from: data)

  #expect(response.eventType == .itemPriceCheck)
  #expect(response.productID == "fz-003")
  #expect(response.productNotes == "Fizzy Zero is the one you want")
  #expect(response.pricePerItem == "5.00")
  #expect(response.currency == "USD")
  #expect(response.unit == nil)
}

@Test func rejectsSweetfeetPricePerItemInquiryResponseWithMismatchedEventType() {
  let data = Data(
    #"{"event-type":"sale","product-id":"fz-003","price-per-item":"5.00","currency":"USD"}"#.utf8)

  #expect(throws: DecodingError.self) {
    try JSONDecoder().decode(SweetfeetItemPriceCheckResponse.self, from: data)
  }
}

@Test func decodesTapResponseUsingContactMode() throws {
  let data = Data(
    #"{"sweepline-version":"1.1","contact-mode":"tap","destination-url":"https://example.com/contact"}"#
      .utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .tap)
  #expect(response.value == true)
  #expect(response.destinationURL == "https://example.com/contact")
}

@Test func decodesYesResponseUsingIsYesKey() throws {
  let data = Data(
    #"{"sweepline-version":"1.1","is-yes":true,"destination-url":"https://example.com/yes"}"#.utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .yes)
  #expect(response.value == true)
  #expect(response.destinationURL == "https://example.com/yes")
}

@Test func decodesYesResponseUsingMatchingContactModeAndIsYesKey() throws {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"yes","is-yes":false}"#.utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .yes)
  #expect(response.value == false)
}

@Test func decodesLaneOnlyYesResponse() throws {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"yes"}"#.utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .yes)
  #expect(response.value == nil)
}

@Test func decodesDownResponseUsingIsDownKey() throws {
  let data = Data(#"{"sweepline-version":"1.1","is-down":false}"#.utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .down)
  #expect(response.value == false)
}

@Test func decodesDownResponseUsingMatchingContactModeAndIsDownKey() throws {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"down","is-down":true}"#.utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .down)
  #expect(response.value == true)
}

@Test func decodesLaneOnlyDownResponse() throws {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"down"}"#.utf8)
  let decoder = JSONDecoder()

  let response = try decoder.decode(SweeplineResponse.self, from: data)

  #expect(response.version == .v1_1)
  #expect(response.contactMode == .down)
  #expect(response.value == nil)
}

@Test func encodesYesResponseUsingIsYesKey() throws {
  let response = SweeplineResponse(
    contactMode: .yes,
    value: true,
    destinationURL: "https://example.com/yes"
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["sweepline-version"] as? String == "1.1")
  #expect(object["is-yes"] as? Bool == true)
  #expect(object["is-down"] == nil)
  #expect(object["contact-mode"] == nil)
  #expect(object["value"] == nil)
  #expect(object["destination-url"] as? String == "https://example.com/yes")
}

@Test func encodesTapResponseWithoutValueKey() throws {
  let response = SweeplineResponse(
    contactMode: .tap,
    value: true,
    destinationURL: "https://example.com/tap"
  )
  let encoder = JSONEncoder()
  let data = try encoder.encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["sweepline-version"] as? String == "1.1")
  #expect(object["contact-mode"] as? String == "tap")
  #expect(object["is-yes"] == nil)
  #expect(object["is-down"] == nil)
  #expect(object["value"] == nil)
  #expect(object["destination-url"] as? String == "https://example.com/tap")
}

@Test func encodesDownResponseUsingIsDownKey() throws {
  let response = SweeplineResponse(contactMode: .down, value: false)
  let encoder = JSONEncoder()
  let data = try encoder.encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["sweepline-version"] as? String == "1.1")
  #expect(object["is-down"] as? Bool == false)
  #expect(object["is-yes"] == nil)
  #expect(object["contact-mode"] == nil)
  #expect(object["value"] == nil)
  #expect(object["destination-url"] == nil)
}

@Test func encodesLaneOnlyYesResponseUsingContactMode() throws {
  let response = SweeplineResponse(contactMode: .yes, value: nil)
  let encoder = JSONEncoder()
  let data = try encoder.encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["sweepline-version"] as? String == "1.1")
  #expect(object["contact-mode"] as? String == "yes")
  #expect(object["is-yes"] == nil)
  #expect(object["is-down"] == nil)
}

@Test func encodesLaneOnlyDownResponseUsingContactMode() throws {
  let response = SweeplineResponse(contactMode: .down, value: nil)
  let encoder = JSONEncoder()
  let data = try encoder.encode(response)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

  #expect(object["sweepline-version"] as? String == "1.1")
  #expect(object["contact-mode"] as? String == "down")
  #expect(object["is-yes"] == nil)
  #expect(object["is-down"] == nil)
}

@Test func rejectsResponseMissingContactKey() {
  let data = Data(#"{"sweepline-version":"1.1"}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineResponse.self, from: data)
  }
}

@Test func rejectsResponseWithMultipleValueSpecifiers() {
  let data = Data(#"{"sweepline-version":"1.1","is-yes":true,"is-down":false}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineResponse.self, from: data)
  }
}

@Test func rejectsResponseWithMismatchedContactModeAndValueSpecifier() {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"yes","is-down":true}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineResponse.self, from: data)
  }
}

@Test func rejectsTapResponseWithValueSpecifier() {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"tap","is-yes":true}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineResponse.self, from: data)
  }
}

@Test func rejectsResponseWithUnknownContactMode() {
  let data = Data(#"{"sweepline-version":"1.1","contact-mode":"maybe"}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineResponse.self, from: data)
  }
}

@Test func rejectsResponseWithUnknownSweeplineVersion() {
  let data = Data(#"{"sweepline-version":"2.0","contact-mode":"tap"}"#.utf8)
  let decoder = JSONDecoder()

  #expect(throws: DecodingError.self) {
    try decoder.decode(SweeplineResponse.self, from: data)
  }
}

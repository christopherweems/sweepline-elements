import Crypto
import Foundation
import Testing
@testable import SweeplineElements

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
    #expect(signedMessage.headers == [
        SweeplineHeader.signatureAlgorithm.rawValue: "ed25519",
        SweeplineHeader.keyID.rawValue: "39f713d0a644253f",
        SweeplineHeader.publicKey.rawValue: "PUAXw+hDiVqStwqnTRt+vJyYLM8uxJaMwM1V8Sr0Zgw=",
        SweeplineHeader.signature.rawValue: "kqAJqfDUyrhyDoILX2QlQKKye1QWUD+Ps3YiI+vbadoIWsHkPhWZbkWPNhPQ8R2MOHsurrQwKu6wDSkWErsMAA==",
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
    let result = try verifier.verificationResult(body: Data("mutated".utf8), signedMessage: signedMessage)

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

    #expect(throws: SweeplineVerificationError.keyIDMismatch(
        expected: SweeplineKeyID(publicKeyRawRepresentation: publicKeyData),
        actual: mismatchedKeyID
    )) {
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

@Test func signedMessageParsesHeadersCaseInsensitively() throws {
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

@Test func signedMessageRejectsMissingHeader() {
    #expect(throws: SweeplineSignedMessageHeaderError.missingHeader(.signature)) {
        try SweeplineSignedMessage(headers: [
            SweeplineHeader.signatureAlgorithm.rawValue: "ed25519",
            SweeplineHeader.keyID.rawValue: "abcdef0123456789",
            SweeplineHeader.publicKey.rawValue: "public-key",
        ])
    }
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

@Test func decodesRequestUsingIsTapKey() throws {
    let data = Data(#"{"is-tap":true,"date":0,"idempotency-id":"tap"}"#.utf8)
    let decoder = JSONDecoder()

    let request = try decoder.decode(SweeplineRequest.self, from: data)

    #expect(request.verb == .tap)
    #expect(request.value)
    #expect(request.idempotencyID == "tap")
}

@Test func decodesRequestWithIsFirstContact() throws {
    let data = Data(#"{"is-yes":true,"date":0,"idempotency-id":"first-contact","is-first-contact":true}"#.utf8)
    let decoder = JSONDecoder()

    let request = try decoder.decode(SweeplineRequest.self, from: data)

    #expect(request.isFirstContact == true)
}

@Test func rejectsRequestWithMultipleVerbKeys() throws {
    let data = Data(#"{"is-tap":true,"is-yes":true,"is-down":false,"date":0,"idempotency-id":"ambiguous"}"#.utf8)
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
        idempotencyID: "encoded"
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(request)
    let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(object["is-down"] as? Bool == true)
    #expect(object["is-tap"] == nil)
    #expect(object["is-yes"] == nil)
    #expect(object["idempotency-id"] as? String == "encoded")
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

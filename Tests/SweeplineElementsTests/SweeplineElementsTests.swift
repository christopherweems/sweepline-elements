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

@Test func keyIDRejectsInvalidRawValues() {
    #expect(SweeplineKeyID(rawValue: "wrong") == nil)
    #expect(SweeplineKeyID(rawValue: "ABCDEF0123456789") == nil)
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

@Test func rejectsRequestWithMultipleVerbKeys() throws {
    let data = Data(#"{"is-yes":true,"is-down":false,"date":0,"idempotency-id":"ambiguous"}"#.utf8)
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
    #expect(object["is-yes"] == nil)
    #expect(object["idempotency-id"] as? String == "encoded")
}

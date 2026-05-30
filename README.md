# sweepline-elements

Swift types for reading, verifying, and producing Sweepline protocol messages.

Written to help you get your Sweepline endpoint validating and responding to requests, `sweepline-elements` keeps the wire-format details in one place: request JSON keys, signature header names, Ed25519 verification, and public-key fingerprinting. 

App developers: `sweepline-elements` could be useful in your Sweepline client (iOS, Windows Phone, Chromebook – and we're looking for a solid Android implementation to point people to).

## The Protocol

Sweepline clients send a JSON request body (see `Request Payload`) via HTTP POST plus four signature headers:

```http
X-Sweepline-Signature-Algorithm: ed25519
X-Sweepline-Key-ID: <16-character-key-id>
X-Sweepline-Public-Key: <base64-raw-ed25519-public-key>
X-Sweepline-Signature: <base64-ed25519-signature>
```

## The Package

`SweeplineElements` provides:

- `SweeplineSignedMessage` for parsing and emitting signature metadata.
- `SweeplineVerifier` for verifying a signed request body.
- `SweeplineRequest` for decoding the request JSON payload.
- `SweeplineResponse` for encoding and decoding endpoint response JSON.
- `SweeplineKeyID` for the shared key ID derivation algorithm.
- `SweeplineHeader` for the canonical HTTP header names.

It does not own server routing, replay protection, authorization, key storage policy, or client Keychain behavior.


## Installation

Add the package to your server target:

```swift
.package(url: "https://github.com/christopherweems/sweepline-elements.git", from: "0.1.4")
```

Then add the product dependency:

```swift
.product(name: "SweeplineElements", package: "sweepline-elements")
```


## Verifying An Incoming Request

Verify the exact body bytes received over HTTP. Do not re-encode JSON before verification; even semantically equivalent JSON can produce different bytes and fail signature verification.

```swift
import Foundation
import SweeplineElements

func handleSweeplineRequest(
    body: Data,
    headers: [String: String]
) throws -> SweeplineRequest {
    let signedMessage = try SweeplineSignedMessage(headers: headers)
    let verifier = SweeplineVerifier()

    switch try verifier.verificationResult(body: body, signedMessage: signedMessage) {
    case .valid:
        break
    case .invalidSignature:
        throw RequestError.unauthorized
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(SweeplineRequest.self, from: body)
}
```

`SweeplineSignedMessage.init(headers:)` treats header names case-insensitively, which matches HTTP header semantics.


## Request Payload

A Sweepline request contains exactly one verb key. Current request bodies use `is-tap`, `is-yes`, or `is-down`:

```json
{
  "is-yes": true,
  "date": "2026-05-24T16:20:00Z",
  "idempotency-id": "7E3F9C6B-3E2D-4985-A17B-3F4B2D51F1AA",
  "sender-id": "kobe-bryant",
  "zone-id": "staples-center",
  "duration-held": 81.00,
  "is-first-contact": true
}
```

Fields:

- `is-tap`: Boolean tap/release state. Present when `verb == .tap`.
- `is-yes`: Boolean yes/no state. Present when `verb == .yes`.
- `is-down`: Boolean down/up state. Present when `verb == .down`.
- `date`: Client timestamp.
- `idempotency-id`: Client-generated idempotency token. Servers should use this for replay/idempotency handling.
- `sender-id`: Optional client sender identifier.
- `zone-id`: Optional endpoint zone identifier.
- `duration-held` (*): Optional hold duration in seconds.
- `is-first-contact` (*): Optional flag set when this request is the sender's first contact with the endpoint.

`SweeplineRequest` rejects payloads with more than one of `is-tap`, `is-yes`, or `is-down`, and also rejects payloads with no verb key.


## Response Payload

An endpoint response identifies the protocol version and exactly one contact signal:

```json
{
  "sweepline-version": "1.1",
  "is-yes": true,
  "destination-url": "https://example.com/contact"
}
```

Fields:

- `sweepline-version`: Protocol version. `SweeplineResponse` currently supports `1.1`.
- `contact-mode`: Optional contact lane. Required as `"tap"` for tap responses; for `yes` and `down`, it may be included when it matches the value specifier.
- `is-yes`: Boolean yes/no state. Present when `contactMode == .yes`.
- `is-down`: Boolean down/up state. Present when `contactMode == .down`.
- `destination-url`: Optional landing URL for client to present after server's acknowledgement of gesture.


## Signature Contract

Sweepline signatures use Ed25519 over the raw HTTP request body bytes.

Verification performs these checks:

1. `X-Sweepline-Signature-Algorithm` must be `ed25519`, case-insensitive.
2. `X-Sweepline-Public-Key` must be valid base64 raw Ed25519 public-key bytes.
3. `X-Sweepline-Signature` must be valid base64 signature bytes.
4. `X-Sweepline-Key-ID` must match the supplied public key.
5. The signature must verify against the exact body bytes.

Malformed metadata throws `SweeplineVerificationError`. A well-formed message with a bad signature returns `.invalidSignature` from `verificationResult(...)` or `false` from `verify(...)`.


## Key IDs

A Sweepline Key ID is a short public-key fingerprint:

```text
lowercaseHex(first 8 bytes of SHA256(rawEd25519PublicKeyBytes))
```

That yields a 16-character lowercase hex string. The Key ID is not a secret and is not an authorization decision by itself. Use it as a compact identifier for logging, lookup, and comparing the supplied public key against the signed message metadata.

```swift
let keyID = SweeplineKeyID(publicKeyRawRepresentation: publicKeyData)
print(keyID.rawValue)
```

## Header Names

Use `SweeplineHeader` rather than string literals when possible:

```swift
let keyIDHeader = SweeplineHeader.keyID.rawValue
```

Canonical names:

```text
X-Sweepline-Signature-Algorithm
X-Sweepline-Key-ID
X-Sweepline-Public-Key
X-Sweepline-Signature
```

## Server Responsibilities

This package verifies message integrity. Servers still need to decide policy.

Recommended server-side checks:

- Enforce HTTPS at the edge. (ATS requires it.)
- Verify the signature before decoding and acting on the body.
- Store processed `idempotency-id` values for replay/idempotency handling.
- Decide whether a public key is allowed for a route, account, sender, or zone.
- Log the Key ID and route outcome, but avoid logging full request bodies if they contain sensitive data.


## Producing Signed Messages

Most server code only verifies requests. For tests, tools, or server-to-server flows, use `SweeplineSigner` when you already have raw public key and signature bytes:

```swift
let signedMessage = SweeplineSigner.signedMessage(
    publicKeyRawRepresentation: publicKeyData,
    signature: signatureData
)

let headers = signedMessage.headers
```


## Questions, Comments, Concerns 
### (This could have been a pull request?)

https://christopherweems.com/contact

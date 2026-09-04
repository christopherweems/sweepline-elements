# sweepline-elements

`sweepline-elements` is an umbrella Swift package for a family of signed protocols built on the same Ed25519 HTTP signing rules.

Primary modules:

- `SweeplineSigning` for shared signing, verification, key identifiers, HTTP signature headers, and canonical signed-request construction across `Sweepline`, `SweetfeetProtocol`, and `BeeperProtocol`.
- `Sweepline` for gesture and interaction payloads.
- `SweeplinePhoto` for attested image descriptions and optional inline delivery.
- `SweetfeetProtocol` for commerce and event payloads.
- `BeeperProtocol` for minimal signed messages.

Every protocol in the family is payload-agnostic at the signing layer: the signature covers the raw HTTP request body bytes, and protocol meaning lives entirely in the JSON body.

## Installation

```swift
.package(url: "https://github.com/christopherweems/sweepline-elements.git", branch: "main")
```

Products:

```swift
.product(name: "SweeplineSigning", package: "sweepline-elements")
.product(name: "Sweepline", package: "sweepline-elements")
.product(name: "SweetfeetProtocol", package: "sweepline-elements")
.product(name: "BeeperProtocol", package: "sweepline-elements")
.product(name: "SweeplinePhoto", package: "sweepline-elements")
```

Compatibility umbrella products remain available:

- `SweeplineElements`
- `SweetfeetElements`

## Signing

`SweeplineSigning` emits canonical `X-Sweepline-*` headers:

```http
X-Sweepline-Signature-Algorithm: ed25519
X-Sweepline-Key-ID: <16-character-key-id>
X-Sweepline-Public-Key: <base64-raw-ed25519-public-key>
X-Sweepline-Signature: <base64-ed25519-signature>
```

```swift
import Foundation
import SweeplineSigning

func verify(body: Data, headers: [String: String]) throws -> Bool {
  let signedMessage = try SweeplineSignedMessage(headers: headers)
  return try SweeplineVerifier().verify(body: body, signedMessage: signedMessage)
}
```

If you already have body bytes plus a public key and signature, you can construct a canonical signed request:

```swift
let canonicalRequest = SweeplineSigner.canonicalRequest(
  body: body,
  publicKeyRawRepresentation: publicKeyData,
  signature: signatureData
)

let headers = canonicalRequest.headers
```

## Sweepline

`Sweepline` models signed gesture and interaction requests and responses:

- `SweeplineRequest`
- `SweeplineResponse`
- `SweeplineVerb`
- `SweeplineVersion`

## SweeplinePhoto

`SweeplinePhoto` is a single POST envelope containing an image description,
the submitter's attestation of that description, and optional image bytes.

```swift
import SweeplinePhoto

let description = try SweeplinePhotoDescription(
  imageHash: "sha256:<64 lowercase hexadecimal digits>",
  memo: "A field of sunflowers below a blue sky",
  senderID: "tony-fresh",
  batchID: "sunflowers-2026-05-24",
  timestamp: 1_780_000_000,
  byteCount: Int64(imageData.count),
  mediaType: "image/jpeg"
)
let descriptionBody = try JSONEncoder().encode(description)
let signature = try privateKey.signature(for: descriptionBody)
let signedMessage = SweeplineSigner.signedMessage(
  publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
  signature: signature
)
let attestation = SweeplineSignedArtifact(
  body: descriptionBody,
  signedMessage: signedMessage
)
let photo = try SweeplinePhoto(
  description: description,
  attestation: attestation,
  zoneID: "basement-door",
  imageData: imageData
)
```

`image-hash` is canonical and validated when constructing or decoding a
`SweeplinePhoto`: it must be `sha256:` followed by exactly 64 lowercase
hexadecimal digits.

Before POSTing, query the endpoint with `OPTIONS`. A `204 No Content` response
uses `Sweepline-Photo-Max-Bytes` as a decimal maximum raw-image byte count. A
value of zero means the endpoint accepts the description and its attestation,
but no inline `image-data`.

A front-end server can accept and retain the bytes, then notify a nested
SweeplinePhoto endpoint by forwarding the same description and attestation in
a new request without the bytes. The nested server can use either the
description or its attestation as a cache key when asking the front-end server
for the image later. That retrieval mechanism is deliberately outside the
SweeplinePhoto protocol and can be implemented ad hoc.

`SweeplinePhotoEndpoint.optionsRequest(for:)` constructs the request and
`maximumUploadSize(_:)` parses the response.

## SweetfeetProtocol

`SweetfeetProtocol` models signed commerce and event payloads:

- `SweetfeetRequest`
- `SweetfeetResponse`
- `SweetfeetItemPriceCheckRequest`
- `SweetfeetItemPriceCheckResponse`
- `SweetfeetEventType`

## BeeperProtocol

`BeeperProtocol` models a minimal signed messaging payload with:

- `title`
- `topic`
- `message`
- `message-id`
- `date`
- `is-time-sensitive`

It also provides `BeeperEnvelope`, `BeeperDeliveryMetadata`, and
`SweeplineSignedArtifact` for transporting the exact signed request bytes through
delivery systems such as APNS. Presentation metadata can be projected beside the
envelope without altering the signed artifact.

```swift
import BeeperProtocol

let message = BeeperMessage(
  title: "Front desk",
  topic: "arrival",
  message: "Package waiting",
  messageID: "beep-001",
  date: Date(),
  timeSensitive: true
)
```

## Compatibility

- Prefer `SweeplineSigning`, `Sweepline`, `SweetfeetProtocol`, `BeeperProtocol`,
  and `SweeplinePhoto`.
- `SweeplineElements` and `SweetfeetElements` remain available as umbrella products.
- `Cashline*` aliases have been removed.

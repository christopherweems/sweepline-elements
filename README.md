# sweepline-elements

`sweepline-elements` is an umbrella Swift package for a family of signed protocols built on Ed25519.

Primary modules:

- `SweeplineSigning` for shared signing, verification, key identifiers, and HTTP authorization across `Sweepline`, `SweetfeetProtocol`, and `BeeperProtocol`.
- `Sweepline` for gesture and interaction payloads.
- `SweeplinePhoto` for attested image descriptions and optional inline delivery.
- `SweetfeetProtocol` for commerce and event payloads.
- `BeeperProtocol` for minimal signed messages.

The signing layer is payload-agnostic. HTTP authorization binds the exact request
context, body, timestamp, and nonce. Durable artifact signatures cover the original
artifact bytes and remain verifiable after delivery.

This is the unreleased **2.0.0** API. See [HTTP-SIGNING.md](HTTP-SIGNING.md) for the
wire format, trust boundary, test vector, and migration requirements.

## Installation

```swift
.package(url: "https://github.com/christopherweems/sweepline-elements.git", branch: "main")
```

Products:

```swift
.product(name: "SweeplineSigning", package: "sweepline-elements")
.product(name: "Sweepline", package: "sweepline-elements")
.product(name: "SweeplinePhoto", package: "sweepline-elements")
.product(name: "SweetfeetProtocol", package: "sweepline-elements")
.product(name: "BeeperProtocol", package: "sweepline-elements")
```

Compatibility umbrella products remain available:

- `SweeplineElements`
- `SweetfeetElements`

## HTTP authorization

HTTP format 2 adds three fields to the existing signature headers:

```http
X-Sweepline-Version: 2
X-Sweepline-Issued-At: <unix-seconds>
X-Sweepline-Nonce: <32-lowercase-hex-digits>
X-Sweepline-Signature-Algorithm: ed25519
X-Sweepline-Key-ID: <16-character-key-id>
X-Sweepline-Public-Key: <base64-raw-ed25519-public-key>
X-Sweepline-Signature: <base64-ed25519-signature>
```

```swift
import Foundation
import SweeplineSigning

let request = try SweeplineHTTPRequest(
  method: "POST",
  url: "https://service.example/action",
  contentType: "application/json"
)
let authorization = try SweeplineSigner.httpAuthorization(
  request: request,
  body: body,
  issuedAt: Int64(Date().timeIntervalSince1970),
  publicKey: privateKey.publicKey.rawRepresentation,
  sign: privateKey.signature(for:)
)
// Send the same method, URL, content type, body, and authorization.headers.
```

HTTPS is the default. For an HTTP endpoint protected by an equivalent private transport,
such as WireGuard, explicitly opt in when constructing the signed context:

```swift
let request = try SweeplineHTTPRequest(
  method: "POST",
  url: "http://service.internal/action",
  contentType: "application/json",
  allowHTTP: true
)
```

The service reconstructing that HTTP request context must also pass `allowHTTP: true`.

On the server, construct `request` from the actual request and a trusted external
origin. Pass original header pairs without first converting them to a dictionary:

```swift
let authorization = try SweeplineHTTPAuthorization(headers: headerPairs)
let verified = try SweeplineVerifier().verifyHTTP(
  request: request,
  body: body,
  authorization: authorization,
  now: Int64(Date().timeIntervalSince1970),
  maximumAge: 300,
  allowedFutureSkew: 30
)
// Check verified.keyID against the endpoint's authorization policy.
// Atomically reserve (trusted audience, verified.keyID, verified.nonce),
// retaining it until verified.validUntil, before issuing credentials or acting.
```

`verifyHTTP` checks the signature and freshness. It has no replay store, clock,
key allowlist, or application retry policy. The example's age and skew limits are
service choices, not protocol constants. Never fall back to artifact verification
when HTTP authorization fails.

## Artifact signatures

`SweeplineSigner.signedMessage` packages a signature over exact artifact bytes.
`SweeplineVerifier.verifyArtifact(body:signedMessage:)` verifies those bytes without
HTTP context or expiration. It is suitable for stored photo attestations and signed
messages, not endpoint access. `SweeplineSignedArtifact` preserves those bytes and
signature metadata for later verification.

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

## Protocol rejections

Return `SweeplineErrorResponse` with a non-success HTTP status when rejecting a
Sweepline request. For example, HTTP 409 with:

```json
{"sweepline-version":"2.0","sweepline-error":"replay-detected"}
```

The optional `message` supplies a human-readable explanation. Standard codes are
`invalid-signature`, `replay-detected`, `expired`, `issued-in-future`,
`unauthorized`, and `invalid-request`. Clients must preserve unknown error codes
and recognize them as protocol rejections. An `X-Sweepline-Version` response
header can identify protocol responses when no structured body is available.
Rejections must not cause clients to retry through unsigned GET. A timeout or
connection failure does not establish that an endpoint lacks protocol support.
These errors report server decisions; they do not implement nonce reservation or
key authorization policy.

# sweepline-elements

`sweepline-elements` is an umbrella Swift package for a family of signed protocols built on the same Ed25519 HTTP signing rules.

Primary modules:

- `SweeplineSigning` for shared signing, verification, key identifiers, HTTP signature headers, and canonical signed-request construction across `Sweepline`, `SweetfeetProtocol`, and `BeeperProtocol`.
- `Sweepline` for gesture and interaction payloads.
- `SweetfeetProtocol` for commerce and event payloads.
- `BeeperProtocol` for minimal signed messages.
- `SweeplinePhoto` for signed, pull-based image delivery metadata.

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

## SweeplinePhoto

`SweeplinePhoto` tells a server where to download an image instead of placing
the image bytes in the signed request. Its JSON payload contains `image-hash`,
`download-url`, and `good-until`; the latter is an integer Unix timestamp in
seconds. The raw JSON body is signed using the standard `X-Sweepline-*` headers.

```swift
import SweeplinePhoto

let photo = SweeplinePhoto(
  imageHash: "sha256:<digest>",
  downloadURL: URL(string: "https://example.com/image.jpg")!,
  goodUntil: 1_800_000_000
)
```

## Compatibility

- Prefer `SweeplineSigning`, `Sweepline`, `SweetfeetProtocol`, `BeeperProtocol`,
  and `SweeplinePhoto`.
- `SweeplineElements` and `SweetfeetElements` remain available as umbrella products.
- `Cashline*` aliases have been removed.

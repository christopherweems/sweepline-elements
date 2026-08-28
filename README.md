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
an optional `memo`, `download-url`, and `good-until`; the latter is an integer Unix
timestamp in seconds. The raw JSON body is signed using the standard `X-Sweepline-*`
headers.

```swift
import SweeplinePhoto

let photo = try SweeplinePhoto(
  imageHash: "sha256:<64 lowercase hexadecimal digits>",
  memo: "Package front photo",
  downloadURL: URL(string: "https://example.com/image.jpg")!,
  goodUntil: 1_800_000_000
)
```

Upload the encoded photo payload as the exact body signed by the same key used
for storage requests. Send the resulting `signedPhoto.headers` with
`signedPhoto.body`:

```swift
let body = try JSONEncoder().encode(photo)
let signature = try privateKey.signature(for: body)
let signedPhoto = SweeplineSigner.canonicalRequest(
  body: body,
  publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
  signature: signature
)
```

`image-hash` is canonical and validated when constructing or decoding a
`SweeplinePhoto`: it must be `sha256:` followed by exactly 64 lowercase
hexadecimal digits.

### Intermediary storage

Use `SweeplinePhotoStorageRequest` when sending image bytes to an
intermediary. It carries the `image-hash` and `byte-count`; the intermediary assigns the
`download-url` and `good-until` timestamp in a
`SweeplinePhotoStorageResponse`. Combine those values with the request's hash
to create and sign the `SweeplinePhoto` sent to the recipient.

The encoded storage request is itself signed as the exact HTTP body using the
standard `X-Sweepline-*` headers from `SweeplineSigning`:

```swift
let storageRequest = try SweeplinePhotoStorageRequest(
  imageHash: "sha256:<64 lowercase hexadecimal digits>",
  byteCount: imageData.count
)
let body = try JSONEncoder().encode(storageRequest)
let signature = try privateKey.signature(for: body)
let signedRequest = SweeplineSigner.canonicalRequest(
  body: body,
  publicKeyRawRepresentation: privateKey.publicKey.rawRepresentation,
  signature: signature
)

// Send `signedRequest.body` and `signedRequest.headers` to the intermediary.
```

Before downloading the announced image, a receiving service must make an
`OPTIONS` request to its SweeplinePhoto endpoint. It may download the image
only when the response is `204 No Content` and includes `Sweepline-Photo: 1`.
`SweeplinePhotoEndpoint.optionsRequest(for:)` constructs the check, and
`SweeplinePhotoEndpoint.permitsDownload(_:)` validates its response.

## Compatibility

- Prefer `SweeplineSigning`, `Sweepline`, `SweetfeetProtocol`, `BeeperProtocol`,
  and `SweeplinePhoto`.
- `SweeplineElements` and `SweetfeetElements` remain available as umbrella products.
- `Cashline*` aliases have been removed.

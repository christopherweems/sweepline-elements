# sweepline-elements

`sweepline-elements` is an umbrella Swift package for a family of signed protocols built on the same Ed25519 HTTP signing rules.

Primary modules:

- `SweeplineSigning` for shared signing, verification, key identifiers, HTTP signature headers, and canonical signed-request construction across `Sweepline`, `Sweetfeet`, and `BeeperProtocol`.
- `Sweepline` for gesture and interaction payloads.
- `Sweetfeet` for commerce and event payloads.
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
.product(name: "Sweetfeet", package: "sweepline-elements")
.product(name: "BeeperProtocol", package: "sweepline-elements")
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

## Sweetfeet

`Sweetfeet` models signed commerce and event payloads:

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

- Prefer `SweeplineSigning`, `Sweepline`, `Sweetfeet`, and `BeeperProtocol`.
- `SweeplineElements` and `SweetfeetElements` remain available as umbrella products.
- `Cashline*` aliases have been removed.

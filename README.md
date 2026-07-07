# beepline-elements

`beepline-elements` is an umbrella Swift package for a family of signed protocols built on the same Ed25519 HTTP signing rules.

Primary modules:

- `BeeplineSigning` for shared signing, verification, key identifiers, HTTP signature headers, and canonical signed-request construction.
- `Sweepline` for gesture and interaction payloads.
- `Sweetfeet` for commerce and event payloads.
- `Beeper` for minimal signed messages.

Every protocol in the family is payload-agnostic at the signing layer: the signature covers the raw HTTP request body bytes, and protocol meaning lives entirely in the JSON body.

## Installation

```swift
.package(url: "https://github.com/christopherweems/beepline-elements.git", branch: "main")
```

Products:

```swift
.product(name: "BeeplineSigning", package: "beepline-elements")
.product(name: "Sweepline", package: "beepline-elements")
.product(name: "Sweetfeet", package: "beepline-elements")
.product(name: "Beeper", package: "beepline-elements")
```

Deprecated compatibility products remain available during migration:

- `SweeplineElements`
- `SweetfeetElements`
- `SweeplineSigning`

## Signing

`BeeplineSigning` emits canonical `X-Beepline-*` headers:

```http
X-Beepline-Signature-Algorithm: ed25519
X-Beepline-Key-ID: <16-character-key-id>
X-Beepline-Public-Key: <base64-raw-ed25519-public-key>
X-Beepline-Signature: <base64-ed25519-signature>
```

Verification accepts both `X-Beepline-*` and legacy `X-Sweepline-*` header families during the transition. If both families provide the same semantic header in one request, parsing fails as a duplicate-header error.

```swift
import Foundation
import BeeplineSigning

func verify(body: Data, headers: [String: String]) throws -> Bool {
  let signedMessage = try BeeplineSignedMessage(headers: headers)
  return try BeeplineVerifier().verify(body: body, signedMessage: signedMessage)
}
```

If you already have body bytes plus a public key and signature, you can construct a canonical signed request:

```swift
let canonicalRequest = BeeplineSigner.canonicalRequest(
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

## Beeper

`Beeper` models a minimal signed messaging payload with:

- `title`
- `topic`
- `message`
- `message-id`
- `date`

```swift
import Beeper

let message = BeeperMessage(
  title: "Front desk",
  topic: "arrival",
  message: "Package waiting",
  messageID: "beep-001",
  date: Date()
)
```

## Migration

- Prefer `BeeplineSigning`, `Sweepline`, `Sweetfeet`, and `Beeper` for new code.
- `SweeplineSigning`, `SweeplineElements`, and `SweetfeetElements` remain available as deprecated compatibility products.
- Legacy `Sweepline*` signing APIs remain available as deprecated wrappers where practical.
- `Cashline*` aliases have been removed.

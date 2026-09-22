# HTTP signing format 2 · sweepline-elements 2.0.0

Status: implemented, unreleased. Package version and HTTP format version are
separate. This format does not change durable photo or message artifact signatures.

## Minimal contract

An authorization identifies the signing key, the request it signed, and when it
was issued, with a random nonce that a service can consume once. There are seven
headers: the existing algorithm, key ID, public key, and signature, plus version,
issued-at, and nonce. Method, URL, content type, and body are taken from HTTP itself;
they are not repeated in authorization headers. No additional JSON envelope is
introduced. Application payloads do not change.

| Header | Format |
| --- | --- |
| `X-Sweepline-Version` | Exactly `2` |
| `X-Sweepline-Issued-At` | Nonnegative Int64 Unix seconds; canonical decimal, no leading zeroes except `0` |
| `X-Sweepline-Nonce` | 16 random bytes encoded as 32 lowercase hexadecimal digits |
| `X-Sweepline-Signature-Algorithm` | Exactly `ed25519` |
| `X-Sweepline-Key-ID` | Existing 16-character lowercase hexadecimal key ID |
| `X-Sweepline-Public-Key` | Standard padded Base64 of the 32-byte Ed25519 public key |
| `X-Sweepline-Signature` | Standard padded Base64 of the 64-byte Ed25519 signature |

The key ID remains the first eight bytes of SHA-256 of the public key, encoded as
lowercase hexadecimal. Verification checks this relationship. Authorization field
names are case-insensitive; each must occur exactly once. Each value is limited
to 128 UTF-8 bytes. Duplicate fields are rejected even when the values agree.
Unrelated HTTP headers are ignored by the authorization parser.

## Request context

`SweeplineHTTPRequest` holds the method, external absolute HTTP or HTTPS URL, and optional
content type. These strings are signed exactly as supplied, without normalization.

- Method is a nonempty HTTP token, at most 32 ASCII bytes, with case preserved.
- URL is at most 8192 ASCII bytes, has scheme `https` by default. An `http` URL requires
  the client or service constructing the request context to pass `allowHTTP: true`; this
  explicit opt-in is intended for routes with equivalent protection outside HTTP, such as
  WireGuard. The URL has a nonempty host, an explicit
  path beginning with `/`, and an optional port in `1...65535`. Credentials,
  fragments, whitespace, backslashes, and malformed percent escapes are rejected.
  Use an ASCII hostname representation and percent-encoded paths/queries.
- Include the full encoded query string, preserving ordering, empty values,
  duplicate names, and an empty trailing `?` when present.
- Host casing, explicit default ports, percent-escape casing, dot segments, and
  trailing slashes are not silently equated. `https://example.com/` is valid;
  `https://example.com` must be constructed with an explicit `/` before signing.
- Content type is the exact single HTTP field value after normal HTTP boundary
  whitespace handling, or absent. When present it is 1–1024 printable ASCII bytes,
  without surrounding whitespace. Absence is encoded as an empty string.

Clients must sign the final request representation they actually send. Servers
must reconstruct the same external URL using their configured trusted origin and
the original encoded target, before internal route aliases or rewrites. Reject
requests addressed to an unapproved origin. Do not let arbitrary Host or forwarded
headers establish trust. If a proxy changes the target, preserve the original
through an explicitly trusted mechanism. Redirects need a new authorization for
the new destination; do not forward the old signature.

This format binds content type and body bytes, not every possible HTTP header.
Endpoints must not use unsigned headers to switch privileged operations or body
interpretation. Reject duplicate content types and unsupported content encodings;
verify original body bytes before application decoding. Body-size and overall
HTTP-header limits belong to the receiving service.

## Exact signing bytes

Start with the ASCII bytes `sweepline-http/2` followed by one NUL byte (`00`). Append
the following fields in order. Frame each field as its decimal byte length, one
ASCII colon, and the field's exact bytes. Lengths have no leading zeroes. There
are no separators between framed fields beyond their own length prefixes.

1. Method, UTF-8.
2. Absolute external URL, UTF-8.
3. Content type, UTF-8, or zero bytes when absent.
4. Issued-at time, canonical decimal UTF-8.
5. Nonce, lowercase hexadecimal UTF-8.
6. Raw Ed25519 public key, 32 bytes.
7. SHA-256 of the original HTTP body, 32 bytes, including for an empty body.

Sign these bytes directly with Ed25519. This is not Ed25519ph. The digest is an
internal part of the signing input, not another wire header. The format/domain
prefix fixes the algorithm and separates HTTP signatures from artifact signatures.
The raw public key binds identity; there is no need to repeat its derived key ID
inside the signing input.

`SweeplineHTTPAuthorization.signingInput` is the shared builder. The convenience
`SweeplineSigner.httpAuthorization` generates a nonce when omitted and passes the
input to the caller's signing closure. The caller retains its private key. The
helper verifies the returned signature against the supplied public key.

The parser does not accept a dictionary: supply original `(String, String)` header
pairs. Unknown versions fail. There is no automatic fallback to body-only signing.
An altered request context fails signature verification; the format does not
transmit a second context merely to classify a destination mismatch separately.

## Freshness and replay admission

`verifyHTTP` takes the current Unix second, maximum age, and allowed future skew
explicitly. There is no implicit clock or default service policy. Maximum age must
be positive, skew and current time nonnegative, and arithmetic must not overflow.

Acceptance requires both:

```
issuedAt <= now + allowedFutureSkew
now < issuedAt + maximumAge
```

The returned `Verified` value exposes the authenticated key ID, issued-at time,
nonce, and exclusive `validUntil = issuedAt + maximumAge`. Services must check the
key's permissions, then atomically reserve `(format, trusted audience, key ID,
nonce)` before issuing credentials or admitting an action. Format can be implicit
in a store dedicated to format 2. The audience is the receiving service's trusted
external origin, not a client-supplied claim. Do not scope reservations to a path.

Keep reservations until at least `validUntil`, including for requests accepted
ahead of local time within the skew allowance. All instances serving an audience
must share durable replay state; a restart must not allow reuse. Fail closed on
storage failure. The library intentionally verifies a valid repeated request
again; it cannot replace this service responsibility.

Generate a fresh nonce for each HTTP attempt. Keep application idempotency IDs
separate: they may persist across freshly authorized retries. Services must
prevent repeated side effects through their own durable operation semantics and
must not reissue bearer credentials to a replayed authorization.

HTTPS is the default. HTTP must be explicitly enabled with `allowHTTP: true` for every
request context and should only be used over a route that supplies equivalent transport
protection, such as WireGuard. A captured, unconsumed authorization can race its intended
delivery; at most one copy can be admitted by the replay store. This protocol does not
prevent theft of private keys or of browser bearer tokens.

## Fixed vector

Test-only Ed25519 private seed: the 32 bytes `00` through `1f`, in order. Never use
this key outside tests. Public key (hex):

```
03a107bff3ce10be1d70dd18e74bc09967e4d6309ba50d5f1ddc8664125531b8
```

Method `POST`; URL `https://example.com/radio?x=1&x=2`; content type
`application/json`; issued-at `1800000000`; nonce
`000102030405060708090a0b0c0d0e0f`; body exactly `{"is-tap":true}` with no newline.
Key ID: `56475aa75463474c`.

Signing input (hex; join the lines without whitespace):

```
73776565706c696e652d687474702f3200343a504f535433333a68747470733a2f2f
6578616d706c652e636f6d2f726164696f3f783d3126783d3231363a6170706c6963
6174696f6e2f6a736f6e31303a3138303030303030303033323a3030303130323033
30343035303630373038303930613062306330643065306633323a03a107bff3ce10
be1d70dd18e74bc09967e4d6309ba50d5f1ddc8664125531b833323ab28dc2029806
9e7b26ad8c7614450b2ca98447e504562da0e1ffeb8f95c80684
```

Signature (standard Base64, independently generated with Python cryptography and
checked by the Swift tests):

```
rp9HvmdEmoNgjbUqhrqowwSSpdQBMelcrvQruK+oblrhEJlxh8TGCassTPvOB/TN8FjOhxccHPcdN0b1fUZCCA==
```

## 2.0.0 migration

- Replace `SweeplineCanonicalRequest` and `SweeplineSigner.canonicalRequest` with
  `SweeplineHTTPRequest` and `SweeplineSigner.httpAuthorization` for HTTP traffic.
- Replace HTTP `verify(body:signedMessage:)` calls with `verifyHTTP`. It requires
  the actual context, timestamp policy, and format-2 authorization. Add durable
  nonce admission and key authorization in the service.
- For durable artifact callers, rename `verify` to `verifyArtifact` and
  `verificationResult` to `artifactVerificationResult`. Artifact wire bytes and
  metadata remain unchanged. These methods do not authorize HTTP access.
- Add all seven authorization headers to applicable CORS allow-header lists.
- Coordinate the client/server cutover; accepting legacy HTTP signatures leaves
  the replay vulnerability open. Do not downgrade on verification failure.

No service database, key allowlist, retry engine, endpoint routing, browser session
format, application payload fields, or private-key storage is added to this package.

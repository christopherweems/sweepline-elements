# Roadmap to Sweepline 2.0.0

Status: planned release; implementation and validation in progress.

The app will remain **v1.2**, supporting the **Sweepline 2.0.0 protocol family**.
The `sweepline-elements` Swift package will release as **2.0.0**, including
Sweepline, SweeplinePhoto, SweetfeetProtocol, BeeperProtocol, and their shared
SweeplineSigning layer.

## Version contract

| Component | Release or format version | Meaning |
| --- | --- | --- |
| App | 1.2 | User-facing app release supporting Sweepline 2.0.0 |
| Sweepline protocol family and Swift package | 2.0.0 | Coordinated protocol release and breaking Swift API update |
| HTTP authorization | 2 | Request-signing wire format in `X-Sweepline-Version` |
| Individual payloads and envelopes | Independently versioned | Their wire versions do not automatically become 2.0.0 |

Currently, `SweeplineVersion` exposes `1.1`, `SweetfeetVersion` exposes `0.1`,
and `BeeperEnvelope.currentVersion` is `1`. Review and document these values
before release; change a payload version only when its contract requires it.
Do not substitute the app or package version into an HTTP or payload version field.

## 1. Freeze the public contract

- [ ] Review the public APIs and wire representations of all five primary modules.
- [ ] Inventory breaking changes against the published `v1.1.1` package and
  document migration steps, distinguishing released APIs from unreleased work.
- [ ] Confirm the supported role of the `SweeplineElements` and
  `SweetfeetElements` compatibility products. Their continued availability does
  not imply that removed APIs remain source-compatible.
- [ ] Confirm payload and envelope version handling, including behavior for
  unsupported versions.
- [ ] Specify date encodings and other encoder-dependent wire choices used by
  app and server implementations, with representative fixtures.

The 2.0.0 release permits deliberate breaking changes. In particular,
`SweeplineVerifier.verify` and `verificationResult` become `verifyArtifact` and
`artifactVerificationResult`. HTTP access uses `verifyHTTP` instead.

## 2. Complete HTTP authorization integration

HTTP format 2 is implemented in the package. Its authoritative wire contract,
fixed test vector, and service responsibilities are in [HTTP-SIGNING.md](HTTP-SIGNING.md).

- [ ] Integrate app v1.2 with signing of the final HTTP method, external URL,
  content type, body, issued-at time, and a fresh nonce for each attempt.
- [ ] Integrate servers with verification against the actual request and a
  configured trusted external origin.
- [ ] Enforce key authorization and atomically consume nonces before admitting
  actions or issuing credentials. Replay state must survive restarts and be
  shared across instances serving the same audience.
- [ ] Set service freshness and clock-skew policies, retain replay records until
  expiration, and fail closed when replay storage is unavailable.
- [ ] Update applicable CORS header allowlists and verify proxy/redirect behavior.
- [ ] Exercise app-to-server success, tampering, expiration, replay, and retry
  scenarios. Application idempotency remains separate from authorization nonces.

Artifact verification must never serve as a fallback when HTTP authorization
fails. Replay storage, key permissions, and application idempotency belong to
the receiving service rather than this package.

## 3. Validate the included protocols

### SweeplinePhoto

The current model checks description/attestation consistency and inline byte
count. Constructing or decoding a photo does not verify the attestation's
signature or compare the image bytes with the declared SHA-256 hash.

- [ ] Define and document the complete receiving verification path: verify the
  original attestation bytes, authorize the signer, match the description, and
  check the hash and byte count whenever image bytes are available.
- [ ] Decide whether a package helper should perform these checks or whether
  service integration owns them, and test the chosen contract.
- [ ] Cover invalid signatures, mismatched descriptions, same-length altered
  images, malformed hashes, and description-only forwarding.
- [ ] Verify `OPTIONS` negotiation and raw-image upload limits, including zero
  meaning that inline image bytes are not accepted.
- [ ] Preserve original signed bytes across forwarding and storage. Clarify that
  signatures cover those bytes; no shared canonical JSON encoding is currently
  defined. Document that `zone-id` is outside the durable description attestation.
- [ ] Replace obsolete commented-out split-upload tests with relevant coverage.

Image retrieval after description-only forwarding remains outside the protocol.

### SweetfeetProtocol

- [ ] Confirm request/response fixtures for supported commerce events and item
  price checks, including optional fields and event-type validation.
- [ ] Document price, currency, quantity, and payment-option representations and
  which business rules the receiving application must enforce.
- [ ] Verify signed app-to-service exchanges using HTTP format 2.

### BeeperProtocol

- [ ] Confirm message and envelope fixtures, date encoding, and version handling.
- [ ] Verify that delivery and storage preserve the exact signed artifact bytes.
- [ ] Document that delivery metadata and APNS presentation fields are outside
  the artifact signature; verify the artifact before trusting signed content.
- [ ] Exercise the app's receive-and-verify path, including altered artifacts.

## 4. Establish release evidence

- [ ] Run the complete Swift test suite with resolved dependencies and record the
  toolchain and results.
- [ ] Build the library products for the declared Apple platform support and
  verify the app's supported deployment targets.
- [ ] Build app v1.2 against the release candidate and complete the relevant
  client/server integration scenarios above.
- [ ] Check migration examples and fixed wire fixtures against the release candidate.

The initial release review did not complete a test run: dependency fetching
could not resolve GitHub in the review environment. This is an outstanding
validation item, not evidence of a package test failure.

## 5. Prepare documentation and rollout

- [ ] Clean up the README around the app v1.2 / Sweepline 2.0.0 distinction,
  primary products, installation, and verified usage examples.
- [ ] Publish release notes and a migration guide covering source-breaking APIs,
  HTTP format 2, and the boundaries between HTTP and artifact verification.
- [ ] Coordinate the server cutover with app v1.2 availability and explicitly
  define how older clients are handled. Do not downgrade to legacy signatures
  when format-2 verification fails.
- [ ] Define rollout monitoring and rollback behavior that preserves the new
  authorization requirements.
- [ ] After release checks pass, tag the package `v2.0.0`, update installation
  examples to the release, and release the app as v1.2.

## Release completion

Sweepline 2.0.0 is ready when its public contracts are documented, package and
platform checks pass, app v1.2 interoperates with the receiving services, and
signature verification, replay admission, and protocol-specific validation have
been exercised end to end. Documentation cleanup alone does not satisfy these
release gates.

@_exported public import SweeplineSigning
public import Foundation

/// The immutable image description attested to by a photo submitter.
///
/// The description, or its signed artifact, can be used as a cache key by a
/// server that retains the corresponding image bytes.
public struct SweeplinePhotoDescription: Codable, Hashable, Sendable {
  public static let imageHashPrefix = "sha256:"
  public let imageHash: String
  public let memo: String?
  public let senderID: String?
  public let byteCount: Int64
  public let mediaType: String

  public init(
    imageHash: String,
    memo: String? = nil,
    senderID: String? = nil,
    byteCount: Int64,
    mediaType: String
  ) throws {
    guard Self.isValidImageHash(imageHash) else { throw SweeplinePhotoError.invalidImageHash(imageHash) }
    guard 0 <= byteCount else { throw SweeplinePhotoError.invalidByteCount(byteCount) }
    guard Self.isValidMediaType(mediaType) else { throw SweeplinePhotoError.invalidMediaType(mediaType) }
    self.imageHash = imageHash
    self.memo = memo
    self.senderID = senderID
    self.byteCount = byteCount
    self.mediaType = mediaType
  }

  enum CodingKeys: String, CodingKey {
    case imageHash = "image-hash"
    case memo
    case senderID = "sender-id"
    case byteCount = "byte-count"
    case mediaType = "media-type"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let imageHash = try container.decode(String.self, forKey: .imageHash)
    guard Self.isValidImageHash(imageHash) else {
      throw DecodingError.dataCorruptedError(forKey: .imageHash, in: container,
        debugDescription: "image-hash must be sha256: followed by exactly 64 lowercase hexadecimal digits.")
    }
    let byteCount = try container.decode(Int64.self, forKey: .byteCount)
    guard byteCount >= 0 else {
      throw DecodingError.dataCorruptedError(forKey: .byteCount, in: container,
        debugDescription: "byte-count must not be negative.")
    }
    let mediaType = try container.decode(String.self, forKey: .mediaType)
    guard Self.isValidMediaType(mediaType) else {
      throw DecodingError.dataCorruptedError(forKey: .mediaType, in: container,
        debugDescription: "media-type must be a lowercase, parameter-free Internet media type.")
    }
    self.imageHash = imageHash
    self.memo = try container.decodeIfPresent(String.self, forKey: .memo)
    self.senderID = try container.decodeIfPresent(String.self, forKey: .senderID)
    self.byteCount = byteCount
    self.mediaType = mediaType
  }

  static func isValidImageHash(_ value: String) -> Bool {
    guard value.hasPrefix(imageHashPrefix) else { return false }
    let digest = value.dropFirst(imageHashPrefix.count)
    return digest.count == 64 && digest.allSatisfy { "0123456789abcdef".contains($0) }
  }

  static func isValidMediaType(_ value: String) -> Bool {
    let parts = value.split(separator: "/", omittingEmptySubsequences: false)
    guard parts.count == 2 else { return false }
    let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789!#$&^_.+-")
    return parts.allSatisfy { !$0.isEmpty && $0.allSatisfy(allowed.contains) }
  }
}

/// A photo POST containing an attested description and optional inline bytes.
///
/// The attestation signs the canonical encoding of `description`. A server that
/// accepts and stores `imageData` can forward the same description and
/// attestation to a nested endpoint. When that endpoint advertises a maximum
/// size of zero, the forwarded request omits `imageData`; the nested server can
/// use the description or attestation as a cache key if it retrieves the bytes
/// from the collecting server later.
public struct SweeplinePhoto: Codable, Hashable, Sendable {
  public let description: SweeplinePhotoDescription
  public let attestation: SweeplineSignedArtifact
  public let zoneID: String?
  public let imageData: Data?

  public init(
    description: SweeplinePhotoDescription,
    attestation: SweeplineSignedArtifact,
    zoneID: String? = nil,
    imageData: Data? = nil
  ) throws {
    guard let attestedDescriptionData = attestation.body,
      let attestedDescription = try? JSONDecoder().decode(
        SweeplinePhotoDescription.self, from: attestedDescriptionData),
      attestedDescription == description
    else { throw SweeplinePhotoError.attestationDescriptionMismatch }
    if let imageData, Int64(imageData.count) != description.byteCount {
      throw SweeplinePhotoError.imageDataByteCountMismatch(
        expected: description.byteCount, actual: Int64(imageData.count))
    }
    self.description = description
    self.attestation = attestation
    self.zoneID = zoneID
    self.imageData = imageData
  }

  enum CodingKeys: String, CodingKey {
    case description
    case attestation
    case zoneID = "zone-id"
    case imageData = "image-data"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let description = try container.decode(SweeplinePhotoDescription.self, forKey: .description)
    let attestation = try container.decode(SweeplineSignedArtifact.self, forKey: .attestation)
    let zoneID = try container.decodeIfPresent(String.self, forKey: .zoneID)
    let imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
    do {
      try self.init(
        description: description,
        attestation: attestation,
        zoneID: zoneID,
        imageData: imageData
      )
    } catch {
      throw DecodingError.dataCorruptedError(forKey: .attestation, in: container,
        debugDescription: "The attestation must contain this photo description; inline data must match its byte count.")
    }
  }
}

public enum SweeplinePhotoError: Error, Hashable, Sendable {
  case invalidImageHash(String)
  case invalidByteCount(Int64)
  case invalidMediaType(String)
  case attestationDescriptionMismatch
  case imageDataByteCountMismatch(expected: Int64, actual: Int64)
}

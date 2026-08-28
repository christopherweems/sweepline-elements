@_exported public import SweeplineSigning
public import struct Foundation.URL

/// An invitation for a server to download an image.
///
/// This value is carried by a signed Sweepline message. The image bytes are
/// not part of this payload. `imageHash` and `mediaType` identify the expected
/// bytes at `downloadURL`, and `goodUntil` is the Unix timestamp, in seconds,
/// through which the URL should be considered usable.
public struct SweeplinePhoto: Codable, Hashable, Sendable {
  public static let imageHashPrefix = "sha256:"

  /// SHA-256 digest of the image bytes, encoded as lowercase hexadecimal.
  public let imageHash: String

  /// A human-readable note accompanying the image.
  public let memo: String?

  /// Size of the image bytes, in bytes.
  public let byteCount: Int64

  /// Lowercase Internet media type of the image bytes, without parameters.
  public let mediaType: String

  public let downloadURL: URL
  public let goodUntil: Int64
  
  public init(
    imageHash: String,
    memo: String? = nil,
    byteCount: Int64,
    mediaType: String,
    downloadURL: URL,
    goodUntil: Int64
  ) throws {
    guard Self.isValidImageHash(imageHash) else {
      throw SweeplinePhotoError.invalidImageHash(imageHash)
    }
    guard byteCount >= 0 else {
      throw SweeplinePhotoError.invalidByteCount(byteCount)
    }
    guard Self.isValidMediaType(mediaType) else {
      throw SweeplinePhotoError.invalidMediaType(mediaType)
    }

    self.imageHash = imageHash
    self.memo = memo
    self.byteCount = byteCount
    self.mediaType = mediaType
    self.downloadURL = downloadURL
    self.goodUntil = goodUntil
  }
  
  enum CodingKeys: String, CodingKey {
    case imageHash = "image-hash"
    case memo
    case byteCount = "byte-count"
    case mediaType = "media-type"
    case downloadURL = "download-url"
    case goodUntil = "good-until"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let imageHash = try container.decode(String.self, forKey: .imageHash)

    guard Self.isValidImageHash(imageHash) else {
      throw DecodingError.dataCorruptedError(
        forKey: .imageHash,
        in: container,
        debugDescription: "image-hash must be sha256: followed by exactly 64 lowercase hexadecimal digits."
      )
    }
    let byteCount = try container.decode(Int64.self, forKey: .byteCount)

    guard byteCount >= 0 else {
      throw DecodingError.dataCorruptedError(
        forKey: .byteCount,
        in: container,
        debugDescription: "byte-count must not be negative."
      )
    }
    let mediaType = try container.decode(String.self, forKey: .mediaType)
    guard Self.isValidMediaType(mediaType) else {
      throw DecodingError.dataCorruptedError(
        forKey: .mediaType,
        in: container,
        debugDescription: "media-type must be a lowercase, parameter-free Internet media type."
      )
    }

    self.imageHash = imageHash
    self.memo = try container.decodeIfPresent(String.self, forKey: .memo)
    self.byteCount = byteCount
    self.mediaType = mediaType
    self.downloadURL = try container.decode(URL.self, forKey: .downloadURL)
    self.goodUntil = try container.decode(Int64.self, forKey: .goodUntil)
  }

  static func isValidImageHash(_ imageHash: String) -> Bool {
    guard imageHash.hasPrefix(imageHashPrefix) else {
      return false
    }

    let digest = imageHash.dropFirst(imageHashPrefix.count)
    return digest.count == 64 && digest.allSatisfy { character in
      "0123456789abcdef".contains(character)
    }
  }

  static func isValidMediaType(_ mediaType: String) -> Bool {
    let parts = mediaType.split(separator: "/", omittingEmptySubsequences: false)
    guard parts.count == 2 else { return false }

    let tokenCharacters = Set("abcdefghijklmnopqrstuvwxyz0123456789!#$&^_.+-")
    return parts.allSatisfy { part in
      !part.isEmpty && part.allSatisfy { tokenCharacters.contains($0) }
    }
  }
}

public enum SweeplinePhotoError: Error, Hashable, Sendable {
  case invalidImageHash(String)
  case invalidByteCount(Int64)
  case invalidMediaType(String)
}

public typealias SweeplinePhotoRequest = SweeplinePhoto

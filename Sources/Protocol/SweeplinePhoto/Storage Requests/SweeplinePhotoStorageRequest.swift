import struct Foundation.URL

/// A request for an intermediary to retain image bytes for later delivery.
///
/// The client uploads the image bytes separately. `imageHash` and `byteCount`
/// identify those bytes. Once storage is accepted, the intermediary returns a
/// `SweeplinePhotoStorageResponse` with the assigned download URL and expiry.

public struct SweeplinePhotoStorageRequest: Codable, Hashable, Sendable {
  /// SHA-256 digest of the image bytes, encoded as lowercase hexadecimal.
  public let imageHash: String

  /// Size of the requested upload, in bytes.
  public let byteCount: Int64

  public init(imageHash: String, byteCount: Int64) throws {
    guard SweeplinePhoto.isValidImageHash(imageHash) else {
      throw SweeplinePhotoError.invalidImageHash(imageHash)
    }
    guard byteCount >= 0 else {
      throw SweeplinePhotoStorageRequestError.invalidByteCount(byteCount)
    }

    self.imageHash = imageHash
    self.byteCount = byteCount
  }

  enum CodingKeys: String, CodingKey {
    case imageHash = "image-hash"
    case byteCount = "byte-count"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let imageHash = try container.decode(String.self, forKey: .imageHash)

    guard SweeplinePhoto.isValidImageHash(imageHash) else {
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

    self.imageHash = imageHash
    self.byteCount = byteCount
  }
}

public enum SweeplinePhotoStorageRequestError: Error, Hashable, Sendable {
  case invalidByteCount(Int64)
}


/// Storage details assigned by an intermediary for a photo.
///
/// Use the returned values with the original storage request's `imageHash` to
/// construct the `SweeplinePhoto` that is signed and sent to the recipient.
 
public struct SweeplinePhotoStorageResponse: Codable, Hashable, Sendable {
  public let downloadURL: URL
  public let goodUntil: Int64

  public init(downloadURL: URL, goodUntil: Int64) {
    self.downloadURL = downloadURL
    self.goodUntil = goodUntil
  }

  enum CodingKeys: String, CodingKey {
    case downloadURL = "download-url"
    case goodUntil = "good-until"
  }
}

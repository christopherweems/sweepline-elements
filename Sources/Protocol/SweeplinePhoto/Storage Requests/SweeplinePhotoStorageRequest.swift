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


/// Storage details assigned by an intermediary for a photo asset.
///
/// Send the image bytes in a `POST` request to `assetURL` before
/// `assetUploadGoodUntil`. Once uploaded, that URL serves the asset through
/// `GET`. Use it with the original storage request's `imageHash`, `byteCount`,
/// and `goodUntil` to construct the `SweeplinePhoto` signed for the recipient.
 
public struct SweeplinePhotoStorageResponse: Codable, Hashable, Sendable {
  /// Endpoint that accepts the asset through POST and serves it through GET.
  public let assetURL: URL

  /// Unix timestamp, in seconds, through which the asset can be uploaded.
  public let assetUploadGoodUntil: Int64

  /// Unix timestamp, in seconds, through which the asset can be downloaded.
  public let goodUntil: Int64

  public init(assetURL: URL, assetUploadGoodUntil: Int64, goodUntil: Int64) {
    self.assetURL = assetURL
    self.assetUploadGoodUntil = assetUploadGoodUntil
    self.goodUntil = goodUntil
  }

  enum CodingKeys: String, CodingKey {
    case assetURL = "asset-url"
    case assetUploadGoodUntil = "asset-upload-good-until"
    case goodUntil = "good-until"
  }
}

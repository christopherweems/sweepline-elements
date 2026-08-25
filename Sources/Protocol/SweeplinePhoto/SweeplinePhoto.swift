@_exported public import SweeplineSigning
public import struct Foundation.URL

/// An invitation for a server to download an image.
///
/// This value is carried by a signed Sweepline message. The image bytes are
/// not part of this payload. `imageHash` identifies the expected bytes at
/// `downloadURL`, and `goodUntil` is the Unix timestamp, in seconds, through
/// which the URL should be considered usable.
public struct SweeplinePhoto: Codable, Hashable, Sendable {
  /// SHA-256 digest of the image bytes, encoded as lowercase hexadecimal.
  public let imageHash: String
  
  public let downloadURL: URL
  public let goodUntil: Int64
  
  public init(
    imageHash: String,
    downloadURL: URL,
    goodUntil: Int64
  ) {
    self.imageHash = imageHash
    self.downloadURL = downloadURL
    self.goodUntil = goodUntil
  }
  
  enum CodingKeys: String, CodingKey {
    case imageHash = "image-hash"
    case downloadURL = "download-url"
    case goodUntil = "good-until"
  }
}

public typealias SweeplinePhotoRequest = SweeplinePhoto

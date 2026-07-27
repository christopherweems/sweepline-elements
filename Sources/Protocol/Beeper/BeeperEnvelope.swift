public import struct Foundation.Date
@_exported public import SweeplineSigning

/// Protocol-owned content carried beside the APNS `aps` presentation projection.
public struct BeeperEnvelope: Codable, Hashable, Sendable {
  public static let currentVersion = 1

  public let version: Int
  public let artifact: SweeplineSignedArtifact
  public let delivery: BeeperDeliveryMetadata

  public init(
    version: Int = Self.currentVersion,
    artifact: SweeplineSignedArtifact,
    delivery: BeeperDeliveryMetadata
  ) {
    self.version = version
    self.artifact = artifact
    self.delivery = delivery
  }
}

/// Metadata assigned by the delivery service rather than asserted by the signer.
public struct BeeperDeliveryMetadata: Codable, Hashable, Sendable {
  public let messageID: String
  public let receivedAt: Date

  public init(messageID: String, receivedAt: Date) {
    self.messageID = messageID
    self.receivedAt = receivedAt
  }

  enum CodingKeys: String, CodingKey {
    case messageID = "message-id"
    case receivedAt = "received-at"
  }
}

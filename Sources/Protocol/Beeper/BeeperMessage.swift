@_exported public import BeeplineSigning
public import struct Foundation::Date

public struct BeeperMessage: Codable, Hashable, Sendable {
  public let title: String
  public let topic: String?
  public let message: String
  public let messageID: String
  public let date: Date
  public let timeSensitive: Bool?

  public init(
    title: String,
    topic: String? = nil,
    message: String,
    messageID: String,
    date: Date,
    timeSensitive: Bool? = nil
  ) {
    self.title = title
    self.topic = topic?.isEmpty == true ? nil : topic
    self.message = message
    self.messageID = messageID
    self.date = date
    self.timeSensitive = timeSensitive
  }

  enum CodingKeys: String, CodingKey {
    case title
    case topic
    case message
    case messageID = "message-id"
    case date
    case timeSensitive = "is-time-sensitive"
  }
}

public typealias BeeperRequest = BeeperMessage

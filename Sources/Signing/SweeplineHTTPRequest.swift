private import Foundation

/// Context taken from the final outgoing request or the actual incoming request.
/// The URL is an exact, ASCII HTTPS URL with an explicit path. Nothing is normalized.
public struct SweeplineHTTPRequest: Hashable, Sendable {
  public let method: String
  public let url: String
  public let contentType: String?

  public init(method: String, url: String, contentType: String? = nil) throws {
    let token = "!#$%&'*+-.^_`|~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    guard !method.isEmpty, method.utf8.count <= 32,
      method.utf8.allSatisfy({ token.utf8.contains($0) }) else {
      throw SweeplineHTTPAuthorizationError.invalidRequest
    }
    guard url.utf8.count <= 8192,
      url.utf8.allSatisfy({ (33...126).contains($0) && $0 != 92 }),
      let components = URLComponents(string: url), components.string == url,
      components.scheme == "https", let host = components.host, !host.isEmpty,
      components.user == nil, components.password == nil, components.fragment == nil,
      components.percentEncodedPath.hasPrefix("/"),
      components.port.map({ (1...65535).contains($0) }) ?? true else {
      throw SweeplineHTTPAuthorizationError.invalidRequest
    }
    if let contentType {
      guard !contentType.isEmpty, contentType.utf8.count <= 1024,
        contentType.utf8.allSatisfy({ (32...126).contains($0) }),
        contentType == contentType.trimmingCharacters(in: .whitespaces) else {
        throw SweeplineHTTPAuthorizationError.invalidRequest
      }
    }
    self.method = method
    self.url = url
    self.contentType = contentType
  }
}

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif

/// The capability check a service must perform before downloading an image
/// announced through a SweeplinePhoto endpoint.
public enum SweeplinePhotoEndpoint {
  public static let capabilityHeader = "Sweepline-Photo"
  public static let capabilityValue = "1"

  /// Creates the request used to confirm that an endpoint expects photo
  /// notifications for an asset.
  public static func optionsRequest(for endpointURL: URL) -> URLRequest {
    var request = URLRequest(url: endpointURL)
    request.httpMethod = "OPTIONS"
    return request
  }

  /// Returns whether an OPTIONS response authorizes the image download.
  ///
  /// Header names are case-insensitive, as required by HTTP. The capability
  /// value is intentionally exact: values other than `1` do not opt in.
  public static func permitsDownload(_ response: HTTPURLResponse) -> Bool {
    response.statusCode == 204
      && response.value(forHTTPHeaderField: capabilityHeader) == capabilityValue
  }
}

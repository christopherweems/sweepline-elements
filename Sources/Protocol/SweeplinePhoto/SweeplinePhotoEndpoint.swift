public import Foundation

#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif

public enum SweeplinePhotoEndpoint {
  /// Decimal count of raw image bytes accepted by POST.
  ///
  /// Zero permits description-and-attestation-only posts, including forwarded
  /// notifications from a server retaining the image bytes.
  public static let maximumUploadSizeHeader = "Sweepline-Photo-Max-Size"

  public static func optionsRequest(for endpointURL: URL) -> URLRequest {
    var request = URLRequest(url: endpointURL)
    request.httpMethod = "OPTIONS"
    return request
  }

  public static func maximumUploadSize(_ response: HTTPURLResponse) -> Int64? {
    guard response.statusCode == 204,
      let value = response.value(forHTTPHeaderField: maximumUploadSizeHeader),
      !value.isEmpty,
      value.allSatisfy({ $0.isASCII && $0.isNumber }),
      let byteCount = Int64(value)
    else { return nil }
    return byteCount
  }
}

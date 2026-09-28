import Foundation
import Testing
import Sweepline

@Test func errorResponsePreservesUnknownCodesAndVersion() throws {
  let data = Data(#"{"sweepline-version":"3.0","sweepline-error":"future-error","message":"Denied"}"#.utf8)
  let error = try JSONDecoder().decode(SweeplineErrorResponse.self, from: data)
  #expect(error.version == "3.0")
  #expect(error.error == "future-error")
  #expect(try JSONDecoder().decode(SweeplineErrorResponse.self, from: JSONEncoder().encode(error)) == error)
}

@Test func ordinaryErrorsDoNotIdentifyAsSweepline() {
  #expect(throws: (any Error).self) {
    try JSONDecoder().decode(SweeplineErrorResponse.self, from: Data(#"{"error":"Unauthorized"}"#.utf8))
  }
}

public import protocol Foundation::ContiguousBytes
/* private */ import struct Foundation::Data

public enum SweeplineHeader: String, Sendable {
    case signatureAlgorithm = "X-Sweepline-Signature-Algorithm"
    case keyID = "X-Sweepline-Key-ID"
    case publicKey = "X-Sweepline-Public-Key"
    case signature = "X-Sweepline-Signature"
    
}

public struct SweeplineSignedMessage: Hashable, Sendable {
    public static let algorithm = "ed25519"
    
    public let signatureAlgorithm: String
    public let keyID: SweeplineKeyID
    public let publicKeyBase64: String
    public let signatureBase64: String
    
    public init(
        signatureAlgorithm: String = Self.algorithm,
        keyID: SweeplineKeyID,
        publicKeyBase64: String,
        signatureBase64: String,
    ) {
        self.signatureAlgorithm = signatureAlgorithm
        self.keyID = keyID
        self.publicKeyBase64 = publicKeyBase64
        self.signatureBase64 = signatureBase64
        
    }
    
    public init(
        publicKeyRawRepresentation: some ContiguousBytes,
        signature: some ContiguousBytes,
    ) {
        self.init(
            keyID: SweeplineKeyID(publicKeyRawRepresentation: publicKeyRawRepresentation),
            publicKeyBase64: Self.base64EncodedString(publicKeyRawRepresentation),
            signatureBase64: Self.base64EncodedString(signature),
        )
    }
    
    public init(headers: [String: String]) throws {
        let normalizedHeaders = Dictionary(
            headers.map { key, value in
                (key.lowercased(), value)
            },
            uniquingKeysWith: { first, _ in first }
        )
        
        let signatureAlgorithm = try Self.headerValue(
            for: .signatureAlgorithm,
            in: normalizedHeaders,
        )
        let keyIDRawValue = try Self.headerValue(for: .keyID, in: normalizedHeaders)
        guard let keyID = SweeplineKeyID(rawValue: keyIDRawValue) else {
            throw SweeplineSignedMessageHeaderError.invalidKeyID(keyIDRawValue)
        }
        
        self.init(
            signatureAlgorithm: signatureAlgorithm,
            keyID: keyID,
            publicKeyBase64: try Self.headerValue(for: .publicKey, in: normalizedHeaders),
            signatureBase64: try Self.headerValue(for: .signature, in: normalizedHeaders),
        )
    }
    
    public var headers: [String: String] {
        [
            SweeplineHeader.signatureAlgorithm.rawValue: signatureAlgorithm,
            SweeplineHeader.keyID.rawValue: keyID.rawValue,
            SweeplineHeader.publicKey.rawValue: publicKeyBase64,
            SweeplineHeader.signature.rawValue: signatureBase64,
        ]
    }
    
    private static func headerValue(
        for header: SweeplineHeader,
        in normalizedHeaders: [String: String]
    ) throws -> String {
        guard let value = normalizedHeaders[header.rawValue.lowercased()] else {
            throw SweeplineSignedMessageHeaderError.missingHeader(header)
        }
        
        return value
    }
    
    private static func base64EncodedString(_ bytes: some ContiguousBytes) -> String {
        bytes.withUnsafeBytes { buffer in
            Data(buffer).base64EncodedString()
        }
    }
    
}


// MARK: - Errors

public enum SweeplineSignedMessageHeaderError: Error, Hashable, Sendable {
    case missingHeader(SweeplineHeader)
    case invalidKeyID(String)
    
}

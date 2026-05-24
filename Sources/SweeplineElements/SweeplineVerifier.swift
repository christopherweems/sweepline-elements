public import struct Foundation::Data
private import Crypto

public struct SweeplineVerifier: Sendable {
    public init() {}
    
}

extension SweeplineVerifier {
    public func verify(body: Data, signedMessage: SweeplineSignedMessage) throws -> Bool {
        try verificationResult(body: body, signedMessage: signedMessage) == .valid
    }
    
    public func verificationResult(
        body: Data,
        signedMessage: SweeplineSignedMessage
    ) throws(SweeplineVerificationError) -> SweeplineVerificationResult {
        guard signedMessage.signatureAlgorithm.lowercased() == SweeplineSignedMessage.algorithm else {
            throw .unsupportedSignatureAlgorithm(signedMessage.signatureAlgorithm)
        }
        
        guard let publicKeyData = Data(base64Encoded: signedMessage.publicKeyBase64) else {
            throw .invalidPublicKeyBase64
        }
        guard let signature = Data(base64Encoded: signedMessage.signatureBase64) else {
            throw .invalidSignatureBase64
        }
        
        let computedKeyID = SweeplineKeyID(publicKeyRawRepresentation: publicKeyData)
        guard computedKeyID == signedMessage.keyID else {
            throw .keyIDMismatch(expected: computedKeyID, actual: signedMessage.keyID)
        }
        
        do {
            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
            return publicKey.isValidSignature(signature, for: body) ? .valid : .invalidSignature
            
        } catch {
            throw .invalidPublicKey
        }
    }
    
}


// MARK: - Results

public enum SweeplineVerificationResult: Hashable, Sendable {
    case valid
    case invalidSignature
    
}


// MARK: - Errors

public enum SweeplineVerificationError: Error, Hashable, Sendable {
    case unsupportedSignatureAlgorithm(String)
    case invalidPublicKeyBase64
    case invalidSignatureBase64
    case invalidPublicKey
    case keyIDMismatch(expected: SweeplineKeyID, actual: SweeplineKeyID)
    
}

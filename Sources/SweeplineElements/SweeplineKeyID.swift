public import protocol Foundation::ContiguousBytes
/* private */ import struct Foundation::Data
private import Crypto

public struct SweeplineKeyID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    
    public init?(rawValue: String) {
        guard Self.isValid(rawValue) else {
            return nil
        }
        
        self.rawValue = rawValue
        
    }
    
    public init(publicKeyRawRepresentation: some ContiguousBytes) {
        self.rawValue = publicKeyRawRepresentation.withUnsafeBytes { buffer in
            SHA256.hash(data: Data(buffer))
                .prefix(8)
                .map { String(format: "%02x", $0) }
                .joined()
        }
    }
    
    private static func isValid(_ rawValue: String) -> Bool {
        guard rawValue.count == 16 else {
            return false
        }
        
        return rawValue.allSatisfy { character in
            character.isNumber || ("a"..."f").contains(character)
        }
    }
    
}

public struct SweeplineResponse: Codable, Hashable, Sendable {
    public let version: SweeplineVersion
    public let contactMode: SweeplineContactMode
    public let destinationURL: String?
    
    public init(
        version: SweeplineVersion = .v1_1,
        contactMode: SweeplineContactMode,
        destinationURL: String? = nil
    ) {
        self.version = version
        self.contactMode = contactMode
        self.destinationURL = destinationURL
    }
    
    enum CodingKeys: String, CodingKey {
        case version = "sweepline-version"
        case contactMode = "contact-mode"
        case destinationURL = "destination-url"
    }
}

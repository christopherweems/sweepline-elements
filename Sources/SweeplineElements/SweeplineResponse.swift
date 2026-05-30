public struct SweeplineResponse: Codable, Hashable, Sendable {
    public let version: SweeplineVersion
    public let contactMode: SweeplineContactMode
    public let isFirstContact: Bool?
    public let destinationURL: String?
    
    public init(
        version: SweeplineVersion = .v1_1,
        contactMode: SweeplineContactMode,
        isFirstContact: Bool? = nil,
        destinationURL: String? = nil
    ) {
        self.version = version
        self.contactMode = contactMode
        self.isFirstContact = isFirstContact
        self.destinationURL = destinationURL
    }
    
    enum CodingKeys: String, CodingKey {
        case version = "sweepline-version"
        case contactMode = "contact-mode"
        case isFirstContact = "is-first-contact"
        case destinationURL = "destination-url"
    }
}

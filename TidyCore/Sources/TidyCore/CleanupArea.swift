/// The areas Tidy cleans, in Home screen order.
public enum CleanupArea: String, CaseIterable, Identifiable, Sendable {
    case screenshots, bigVideos, duplicates, blurry, contacts, files

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .screenshots: "Screenshots"
        case .bigVideos: "Big Videos"
        case .duplicates: "Duplicates"
        case .blurry: "Blurry"
        case .contacts: "Contacts"
        case .files: "Files"
        }
    }

    /// SF Symbol name for the area's card.
    public var systemImage: String {
        switch self {
        case .screenshots: "camera.viewfinder"
        case .bigVideos: "video"
        case .duplicates: "square.on.square"
        case .blurry: "drop"
        case .contacts: "person.2"
        case .files: "folder"
        }
    }

    /// The build stage that delivers this area's scanner.
    public var stage: Int {
        switch self {
        case .screenshots, .bigVideos: 2
        case .duplicates, .blurry: 3
        case .contacts: 4
        case .files: 5
        }
    }
}

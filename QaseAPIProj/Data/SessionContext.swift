import Foundation

struct SessionStamp: Equatable, Sendable {
    let ownerID: String?
    let generation: UInt64
}

@MainActor
final class SessionContext {
    static let shared = SessionContext()
    private(set) var ownerID: String?
    private(set) var generation: UInt64 = 0

    init(ownerID: String? = nil) { self.ownerID = ownerID }
    func capture() -> SessionStamp { SessionStamp(ownerID: ownerID, generation: generation) }
    func isCurrent(_ stamp: SessionStamp) -> Bool { stamp == capture() && ownerID != nil }
    func activate(ownerID: String) {
        generation &+= 1
        self.ownerID = ownerID
    }

    func invalidate() {
        generation &+= 1
        ownerID = nil
        NotificationCenter.default.post(name: .didInvalidateSession, object: self)
    }
}

extension Notification.Name {
    static let didInvalidateSession = Notification.Name("didInvalidateSession")
}

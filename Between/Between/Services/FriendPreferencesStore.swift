import Foundation
import SwiftUI
import Combine

/// Per-user friend preferences — starred close friends and visibility toggles.
@MainActor
final class FriendPreferencesStore: ObservableObject {
    @Published private(set) var starredFriendIds: Set<String> = []
    @Published private(set) var shareFreeTimeWith: Set<String> = []

    private var userId: String?
    private var starredKey: String { "between.starred.\(userId ?? "guest")" }
    private var shareKey: String { "between.shareFree.\(userId ?? "guest")" }

    func bind(userId: String, friendIds: [String]) {
        self.userId = userId
        starredFriendIds = Set(loadIds(key: starredKey))
        let savedShare = Set(loadIds(key: shareKey))
        shareFreeTimeWith = savedShare.isEmpty ? Set(friendIds) : savedShare
    }

    func isStarred(_ friendId: String) -> Bool {
        starredFriendIds.contains(friendId)
    }

    func setStarred(_ friendId: String, starred: Bool) {
        if starred {
            starredFriendIds.insert(friendId)
        } else {
            starredFriendIds.remove(friendId)
        }
        save(starredFriendIds, key: starredKey)
    }

    func toggleStar(_ friendId: String) {
        setStarred(friendId, starred: !isStarred(friendId))
    }

    func sharesFreeTime(with friendId: String) -> Bool {
        shareFreeTimeWith.contains(friendId)
    }

    func setSharesFreeTime(_ allowed: Bool, with friendId: String) {
        if allowed {
            shareFreeTimeWith.insert(friendId)
        } else {
            shareFreeTimeWith.remove(friendId)
        }
        save(shareFreeTimeWith, key: shareKey)
    }

    func suggestStars(from overlaps: [FriendOverlap], limit: Int = 5) {
        guard starredFriendIds.isEmpty else { return }
        let top = overlaps
            .sorted { $0.totalMinutes > $1.totalMinutes }
            .prefix(limit)
            .map(\.friendId)
        starredFriendIds = Set(top)
        save(starredFriendIds, key: starredKey)
    }

    private func loadIds(key: String) -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    private func save(_ ids: Set<String>, key: String) {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}

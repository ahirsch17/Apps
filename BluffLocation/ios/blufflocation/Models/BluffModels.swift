import Foundation

struct Player: Identifiable, Codable, Equatable {
  var id: String { name }
  let name: String
}

struct RoomInfo: Codable, Equatable {
  let room: String?
  let users: [String]?
  let host: String?
  let timeLimitMinutes: Int?

  enum CodingKeys: String, CodingKey {
    case room
    case users
    case host
    case timeLimitMinutes = "time_limit_minutes"
  }
}

struct RoleAssignment: Codable, Equatable {
  let role: String?
  let location: String?
}

struct VoteResults: Codable, Equatable {
  let results: JSONValue?
}

struct SpyGuessResult: Codable, Equatable {
  let success: Bool?
  let location: String?
  let message: String?
}

struct ServerMessage: Codable, Equatable {
  let message: String?
}


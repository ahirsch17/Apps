import Foundation

#if canImport(SocketIO)
import SocketIO
#endif

/// Socket.IO client for BluffLocation.
///
/// Mirrors the contract in `Apps/client.js` (events + emits).
final class BluffLocationSocket {
  // MARK: - Callbacks (app-level events)
  var onConnected: (() -> Void)?
  var onDisconnected: (() -> Void)?
  var onError: ((String) -> Void)?
  var onAlreadyInRoom: ((String?) -> Void)?

  var onRoomCreated: ((RoomInfo) -> Void)?
  var onJoinedRoom: ((RoomInfo) -> Void)?
  var onPlayerJoined: ((JSONValue) -> Void)?
  var onPlayerLeft: ((JSONValue) -> Void)?
  var onGameStarted: ((JSONValue) -> Void)?
  var onRoleAssignment: ((RoleAssignment) -> Void)?
  var onGameEnded: ((JSONValue) -> Void)?
  var onVoteRecorded: ((JSONValue) -> Void)?
  var onVoteResults: ((JSONValue) -> Void)?
  var onSpyGuessResult: ((SpyGuessResult) -> Void)?
  var onStateSync: ((RoomInfo) -> Void)?
  var onRoomState: ((RoomInfo) -> Void)?
  var onTimeLimitUpdated: ((JSONValue) -> Void)?
  var onServerMessage: ((ServerMessage) -> Void)?

  // MARK: - Socket internals
#if canImport(SocketIO)
  private var manager: SocketManager?
  private var socket: SocketIOClient?
#endif

  func connect(serverUrl: String) {
#if canImport(SocketIO)
    guard let url = URL(string: serverUrl) else {
      onError?("Invalid server URL")
      return
    }

    // Recreate manager if URL changes
    if manager?.socketURL != url {
      manager = nil
      socket = nil
    }

    if manager == nil {
      manager = SocketManager(
        socketURL: url,
        config: [
          .log(false),
          .compress,
          .forceWebsockets(true),
          .reconnects(true),
          .reconnectAttempts(5),
          .reconnectWait(1)
        ]
      )
      socket = manager?.defaultSocket
      attachForwarders()
    }

    socket?.connect()
#else
    onError?("Missing Socket.IO dependency. Add Swift Package: socket.io-client-swift.")
#endif
  }

  func disconnect() {
#if canImport(SocketIO)
    socket?.disconnect()
#endif
  }

  // MARK: - Emits
  func createGame(user: String, timeLimitMinutes: Int) {
    emit("create_game", ["user": user, "time_limit_minutes": timeLimitMinutes])
  }

  func joinGame(room: String, user: String) {
    emit("join_game", ["room": room, "user": user])
  }

  func leaveGame(room: String, user: String) {
    emit("leave_game", ["room": room, "user": user])
  }

  func startGame(room: String, user: String, timeLimitMinutes: Int) {
    emit("start_game", ["room": room, "user": user, "time_limit_minutes": timeLimitMinutes])
  }

  func endGame(room: String, user: String, reason: String?) {
    var payload: [String: Any] = ["room": room, "user": user]
    if let reason { payload["reason"] = reason }
    emit("end_game", payload)
  }

  func voteSpy(room: String, user: String, voteFor: String, tentative: Bool) {
    emit("vote_spy", ["room": room, "user": user, "vote_for": voteFor, "tentative": tentative])
  }

  func guessLocation(room: String, user: String, location: String) {
    emit("guess_location", ["room": room, "user": user, "location": location])
  }

  func syncState(room: String, user: String) {
    emit("sync_state", ["room": room, "user": user])
  }

  func updateTimeLimit(room: String, minutes: Int, user: String) {
    emit("update_time_limit", ["room": room, "minutes": minutes, "user": user])
  }

  // MARK: - Helpers
  private func emit(_ event: String, _ payload: [String: Any]) {
#if canImport(SocketIO)
    socket?.emit(event, payload)
#else
    onError?("Socket.IO not available.")
#endif
  }

#if canImport(SocketIO)
  private func attachForwarders() {
    guard let socket else { return }

    socket.on(clientEvent: .connect) { [weak self] _, _ in
      self?.onConnected?()
    }

    socket.on(clientEvent: .disconnect) { [weak self] _, _ in
      self?.onDisconnected?()
    }

    socket.on(clientEvent: .error) { [weak self] data, _ in
      let msg = (data.first as? Error)?.localizedDescription ?? "Connection failed"
      self?.onError?(msg)
    }

    // App-level server emits "error"
    socket.on("error") { [weak self] data, _ in
      let payload = data.first
      let message = (payload as? [String: Any])?["message"] as? String
      let lower = (message ?? "").lowercased()
      if lower.contains("already in room") || lower.contains("already joined") {
        self?.onAlreadyInRoom?(message)
      } else {
        self?.onError?(message ?? "Server error")
      }
    }

    // Room events
    socket.on("room_created") { [weak self] data, _ in self?.decodeRoomInfo(data.first, handler: self?.onRoomCreated) }
    socket.on("joined_room") { [weak self] data, _ in self?.decodeRoomInfo(data.first, handler: self?.onJoinedRoom) }
    socket.on("player_joined") { [weak self] data, _ in self?.onPlayerJoined?(JSONValue.fromFoundation(data.first as Any)) }
    socket.on("player_left") { [weak self] data, _ in self?.onPlayerLeft?(JSONValue.fromFoundation(data.first as Any)) }

    // Game events
    socket.on("game_started") { [weak self] data, _ in self?.onGameStarted?(JSONValue.fromFoundation(data.first as Any)) }
    socket.on("role_assignment") { [weak self] data, _ in self?.decode(RoleAssignment.self, data.first, handler: self?.onRoleAssignment) }
    socket.on("game_ended") { [weak self] data, _ in self?.onGameEnded?(JSONValue.fromFoundation(data.first as Any)) }

    // Voting
    socket.on("vote_recorded") { [weak self] data, _ in self?.onVoteRecorded?(JSONValue.fromFoundation(data.first as Any)) }
    socket.on("vote_results") { [weak self] data, _ in self?.onVoteResults?(JSONValue.fromFoundation(data.first as Any)) }

    // Spy guess
    socket.on("spy_guess_result") { [weak self] data, _ in self?.decode(SpyGuessResult.self, data.first, handler: self?.onSpyGuessResult) }

    // State sync
    socket.on("state_sync") { [weak self] data, _ in self?.decodeRoomInfo(data.first, handler: self?.onStateSync) }
    socket.on("room_state") { [weak self] data, _ in self?.decodeRoomInfo(data.first, handler: self?.onRoomState) }

    socket.on("time_limit_updated") { [weak self] data, _ in self?.onTimeLimitUpdated?(JSONValue.fromFoundation(data.first as Any)) }
    socket.on("server_message") { [weak self] data, _ in self?.decode(ServerMessage.self, data.first, handler: self?.onServerMessage) }
  }

  private func decodeRoomInfo(_ any: Any?, handler: ((RoomInfo) -> Void)?) {
    decode(RoomInfo.self, any, handler: handler)
  }

  private func decode<T: Decodable>(_ type: T.Type, _ any: Any?, handler: ((T) -> Void)?) {
    guard let handler else { return }
    guard let any else { return }
    guard JSONSerialization.isValidJSONObject(any),
          let data = try? JSONSerialization.data(withJSONObject: any, options: [])
    else { return }
    guard let decoded = try? JSONDecoder().decode(T.self, from: data) else { return }
    handler(decoded)
  }
#endif
}


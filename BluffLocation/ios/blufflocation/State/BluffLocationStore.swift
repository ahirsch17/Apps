import Foundation
import SwiftUI

@MainActor
final class BluffLocationStore: ObservableObject {
  @Published var serverUrl: String = "http://localhost:3000"
  @Published var userName: String = ""

  @Published var isConnected: Bool = false
  @Published var activeRoom: String?
  @Published var players: [Player] = []
  @Published var host: String?
  @Published var timeLimitMinutes: Int = 8
  @Published var role: String?
  @Published var location: String?

  @Published var lastError: String?
  @Published var lastServerMessage: String?

  private var socket: BluffLocationSocket?

  func ensureSocket() -> BluffLocationSocket {
    if let socket { return socket }
    let s = BluffLocationSocket()
    self.socket = s
    bind(socket: s)
    return s
  }

  func connect() {
    guard !serverUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    ensureSocket().connect(serverUrl: serverUrl)
  }

  func disconnect() {
    socket?.disconnect()
    isConnected = false
  }

  func createGame() {
    guard !userName.isEmpty else { lastError = "Enter a username"; return }
    connect()
    ensureSocket().createGame(user: userName, timeLimitMinutes: timeLimitMinutes)
  }

  func joinGame(room: String) {
    guard !userName.isEmpty else { lastError = "Enter a username"; return }
    connect()
    ensureSocket().joinGame(room: room, user: userName)
  }

  func leaveGame() {
    guard let room = activeRoom else { return }
    ensureSocket().leaveGame(room: room, user: userName)
    activeRoom = nil
    players = []
    role = nil
    location = nil
  }

  func startGame() {
    guard let room = activeRoom else { return }
    ensureSocket().startGame(room: room, user: userName, timeLimitMinutes: timeLimitMinutes)
  }

  func voteSpy(voteFor: String, tentative: Bool = false) {
    guard let room = activeRoom else { return }
    ensureSocket().voteSpy(room: room, user: userName, voteFor: voteFor, tentative: tentative)
  }

  func guessLocation(_ guess: String) {
    guard let room = activeRoom else { return }
    ensureSocket().guessLocation(room: room, user: userName, location: guess)
  }

  func syncState() {
    guard let room = activeRoom else { return }
    ensureSocket().syncState(room: room, user: userName)
  }

  func updateTimeLimit(minutes: Int) {
    guard let room = activeRoom else { return }
    ensureSocket().updateTimeLimit(room: room, minutes: minutes, user: userName)
  }

  private func bind(socket s: BluffLocationSocket) {
    s.onConnected = { [weak self] in
      guard let self else { return }
      self.isConnected = true
      self.lastError = nil
    }
    s.onDisconnected = { [weak self] in
      guard let self else { return }
      self.isConnected = false
    }
    s.onError = { [weak self] message in
      self?.lastError = message
    }
    s.onAlreadyInRoom = { [weak self] message in
      self?.lastError = message ?? "Already in room"
    }
    s.onRoomCreated = { [weak self] info in
      self?.applyRoomInfo(info)
    }
    s.onJoinedRoom = { [weak self] info in
      self?.applyRoomInfo(info)
    }
    s.onRoomState = { [weak self] info in
      self?.applyRoomInfo(info)
    }
    s.onStateSync = { [weak self] info in
      self?.applyRoomInfo(info)
    }
    s.onRoleAssignment = { [weak self] assignment in
      self?.role = assignment.role
      self?.location = assignment.location
    }
    s.onServerMessage = { [weak self] msg in
      self?.lastServerMessage = msg.message
    }
  }

  private func applyRoomInfo(_ info: RoomInfo) {
    if let room = info.room { activeRoom = room }
    if let host = info.host { self.host = host }
    if let minutes = info.timeLimitMinutes { timeLimitMinutes = minutes }
    if let users = info.users {
      players = users.map { Player(name: $0) }.sorted { $0.name < $1.name }
    }
  }
}


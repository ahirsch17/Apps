import Foundation
import Combine
import UIKit

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case pairing
    case error(String)
}

@MainActor
final class ConnectionManager: ObservableObject {
    @Published private(set) var state: ConnectionState = .disconnected
    @Published private(set) var serverName: String = ""
    @Published private(set) var serverMacAddress: String = ""

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private var reconnectWorkItem: DispatchWorkItem?

    private var currentHost: String = ""
    private var currentPort: Int = 8765
    private var authToken: String?

    var isConnected: Bool {
        if case .connected = state { return true }
        return false
    }

    func connect(host: String, port: Int, token: String?) {
        teardownSockets()

        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .error("Missing PC IP")
            return
        }

        currentHost = trimmed
        currentPort = port
        authToken = token
        state = .connecting

        guard let url = URL(string: "ws://\(trimmed):\(port)") else {
            state = .error("Invalid host or port")
            return
        }

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()

        listen()
        sendAuthIfNeeded()
        startPingLoop()
    }

    func disconnect() {
        teardownSockets()
        state = .disconnected
        serverName = ""
        serverMacAddress = ""
    }

    func pair(host: String, port: Int, pin: String, deviceName: String) async -> String? {
        teardownSockets()
        state = .pairing

        guard let url = URL(string: "ws://\(host.trimmingCharacters(in: .whitespacesAndNewlines)):\(port)") else {
            state = .error("Invalid host or port")
            return nil
        }

        currentHost = host
        currentPort = port

        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config)
        webSocket = session?.webSocketTask(with: url)
        webSocket?.resume()
        listen()

        let message = RemoteCommand.pair(pin: pin, deviceName: deviceName)
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let text = String(data: data, encoding: .utf8) else {
            state = .error("Could not build pair request")
            return nil
        }

        do {
            try await send(text: text)
            let response = try await receiveOnce(timeout: 8)
            guard let json = try? JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any],
                  let type = json["type"] as? String else {
                state = .error("Invalid server response")
                return nil
            }

            if type == "pair_ok", let token = json["token"] as? String {
                authToken = token
                serverName = json["hostname"] as? String ?? host
                serverMacAddress = json["mac_address"] as? String ?? ""
                state = .connected
                startPingLoop()
                return token
            }

            let message = json["message"] as? String ?? "Pairing failed"
            state = .error(message)
            teardownSockets()
            return nil
        } catch {
            state = .error("Can't reach PC — run allow-firewall.bat on PC, same Wi‑Fi, Local Network ON")
            teardownSockets()
            return nil
        }
    }

    func send(command: [String: Any]) {
        guard isConnected || state == .pairing else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: command),
              let text = String(data: data, encoding: .utf8) else { return }

        Task {
            try? await send(text: text)
        }
    }

    /// Connect using saved token, or auto-pair with preset PC credentials.
    func bootstrap(settings: SettingsStore) async {
        state = .connecting

        if settings.isPaired, let token = settings.authToken {
            if await connectWithAuth(host: settings.host, port: settings.port, token: token) {
                return
            }
            settings.authToken = nil
        }

        if let token = await pair(
            host: settings.host,
            port: settings.port,
            pin: PCDefaults.pairPIN,
            deviceName: UIDevice.current.name
        ) {
            settings.authToken = token
            if !serverMacAddress.isEmpty {
                settings.macAddress = serverMacAddress
            }
            return
        }

        if case .error = state { return }
        state = .error("Tap banner to retry")
    }

    private func connectWithAuth(host: String, port: Int, token: String) async -> Bool {
        connect(host: host, port: port, token: token)
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        return isConnected
    }

    private func sendAuthIfNeeded() {
        guard let token = authToken, !token.isEmpty else {
            state = .error("Not paired — tap banner to retry")
            return
        }

        let auth: [String: Any] = ["type": "auth", "token": token]
        send(command: auth)
    }

    private func teardownSockets() {
        pingTimer?.invalidate()
        pingTimer = nil
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        session?.invalidateAndCancel()
        session = nil
    }

    private func send(text: String) async throws {
        guard let socket = webSocket else {
            throw URLError(.notConnectedToInternet)
        }
        try await WebSocketIO.send(text, on: socket)
    }

    private func receiveOnce(timeout: TimeInterval) async throws -> String {
        guard let socket = webSocket else {
            throw URLError(.notConnectedToInternet)
        }

        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await WebSocketIO.receive(from: socket)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw URLError(.timedOut)
            }

            guard let result = try await group.next() else {
                throw URLError(.timedOut)
            }
            group.cancelAll()
            return result
        }
    }

    private func listen() {
        guard let socket = webSocket else { return }

        WebSocketIO.receive(from: socket) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let message):
                    let text: String
                    switch message {
                    case .string(let s): text = s
                    case .data(let d): text = String(data: d, encoding: .utf8) ?? ""
                    @unknown default: text = ""
                    }

                    self.handleIncoming(text)
                    self.listen()

                case .failure:
                    if self.state != .disconnected && self.state != .pairing {
                        self.state = .error("Connection lost — tap banner to retry")
                        self.teardownSockets()
                    }
                }
            }
        }
    }

    private func handleIncoming(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "auth_ok":
            serverName = json["hostname"] as? String ?? currentHost
            if let mac = json["mac_address"] as? String, !mac.isEmpty {
                serverMacAddress = mac
            }
            state = .connected
        case "auth_fail":
            state = .error("Session expired — tap banner to retry")
            teardownSockets()
        case "pong":
            if case .connecting = state {
                state = .connected
            }
        case "error":
            let message = json["message"] as? String ?? "Server error"
            state = .error(message)
        default:
            break
        }
    }

    private func startPingLoop() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.send(command: RemoteCommand.ping())
            }
        }
    }
}

/// WebSocket I/O isolated from `@MainActor` so URLSession callbacks compile under strict concurrency.
private enum WebSocketIO {
    static func send(_ text: String, on socket: URLSessionWebSocketTask) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket.send(.string(text)) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    static func receive(from socket: URLSessionWebSocketTask) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            socket.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        continuation.resume(returning: text)
                    case .data(let data):
                        continuation.resume(returning: String(data: data, encoding: .utf8) ?? "")
                    @unknown default:
                        continuation.resume(returning: "")
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func receive(
        from socket: URLSessionWebSocketTask,
        completion: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void
    ) {
        socket.receive { result in
            completion(result)
        }
    }
}

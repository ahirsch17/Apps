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
    @Published private(set) var keyboardFocusRequestID = 0
    @Published private(set) var keyboardIsOpen = false
    @Published private(set) var wakeRoutineMessage = ""
    @Published private(set) var appLaunchMessage = ""

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private var reconnectWorkItem: DispatchWorkItem?
    private var reconnectAttempt = 0
    private var bootstrapTask: Task<Void, Never>?

    private var currentHost: String = ""
    private var currentPort: Int = 8765
    private var authToken: String?

    var isConnected: Bool {
        if case .connected = state { return true }
        return false
    }

    var isBusyConnecting: Bool {
        switch state {
        case .connecting, .pairing: return true
        default: return bootstrapTask != nil
        }
    }

    func requestKeyboard() {
        keyboardFocusRequestID += 1
    }

    func setKeyboardOpen(_ isOpen: Bool) {
        keyboardIsOpen = isOpen
    }

    func waitForConnection(timeout: TimeInterval, settings: SettingsStore) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isConnected { return true }
            await bootstrap(settings: settings, force: false)
            try? await Task.sleep(nanoseconds: 4_000_000_000)
        }
        return isConnected
    }

    func prepareForWakeReconnect() {
        cancelReconnect()
        reconnectAttempt = 0
        teardownSockets()
        state = .disconnected
        wakeRoutineMessage = ""
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
        bootstrapTask?.cancel()
        bootstrapTask = nil
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
                listen()
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
            do {
                try await send(text: text)
            } catch {
                if isConnected {
                    state = .error("Connection lost — tap banner to retry")
                    teardownSockets(keepReconnectPlan: true)
                    scheduleReconnect()
                }
            }
        }
    }

    func bootstrap(settings: SettingsStore, force: Bool = true) async {
        if !force, isConnected { return }

        if let existing = bootstrapTask {
            await existing.value
            return
        }

        let task = Task { @MainActor in
            await performBootstrap(settings: settings, force: force)
        }
        bootstrapTask = task
        await task.value
        bootstrapTask = nil
    }

    private func performBootstrap(settings: SettingsStore, force: Bool) async {
        if !force, isConnected { return }
        if !force, case .connecting = state { return }
        if !force, case .pairing = state { return }

        if settings.isPaired, let token = settings.authToken {
            state = .connecting
            if await connectWithAuth(host: settings.host, port: settings.port, token: token) {
                return
            }
            if case .error(let message) = state, message.contains("Session expired") {
                settings.authToken = nil
            }
        }

        state = .pairing
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

        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            if isConnected { return true }
            if case .error = state { return false }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        if case .connecting = state {
            state = .error("PC not responding — tap banner to retry")
            teardownSockets()
        }
        return false
    }

    private func sendAuthIfNeeded() {
        guard let token = authToken, !token.isEmpty else {
            state = .error("Not paired — tap banner to retry")
            return
        }

        let auth: [String: Any] = ["type": "auth", "token": token]
        send(command: auth)
    }

    private func teardownSockets(keepReconnectPlan: Bool = false) {
        pingTimer?.invalidate()
        pingTimer = nil
        if !keepReconnectPlan {
            cancelReconnect()
        }
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
                        self.state = .error("Connection lost — reconnecting…")
                        self.teardownSockets(keepReconnectPlan: true)
                        self.scheduleReconnect()
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
            reconnectAttempt = 0
            cancelReconnect()
        case "auth_fail":
            state = .error("Session expired — tap banner to retry")
            teardownSockets()
        case "pong":
            if case .connecting = state {
                state = .connected
                reconnectAttempt = 0
                cancelReconnect()
            }
        case "wake_routine_status":
            let status = json["status"] as? String ?? ""
            switch status {
            case "started":
                wakeRoutineMessage = "Signing in…"
            case "done":
                wakeRoutineMessage = "Signed in"
            case "error":
                wakeRoutineMessage = json["message"] as? String ?? "Wake routine failed"
            default:
                break
            }
        case "launch_app_status":
            let status = json["status"] as? String ?? ""
            if status == "done", let app = json["app"] as? String {
                appLaunchMessage = "Opened \(app)"
            } else {
                appLaunchMessage = json["message"] as? String ?? "Could not open app"
            }
        case "focus_text":
            if !keyboardIsOpen {
                keyboardFocusRequestID += 1
            }
        case "error":
            let message = json["message"] as? String ?? "Server error"
            state = .error(message)
        default:
            break
        }
    }

    private func cancelReconnect() {
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
    }

    private func scheduleReconnect() {
        cancelReconnect()
        guard !currentHost.isEmpty, let token = authToken, !token.isEmpty else { return }

        let delays: [TimeInterval] = [3, 5, 10, 15, 30]
        let delay = delays[min(reconnectAttempt, delays.count - 1)]
        reconnectAttempt += 1

        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, !self.isConnected else { return }
                self.connect(host: self.currentHost, port: self.currentPort, token: token)
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                if !self.isConnected {
                    self.scheduleReconnect()
                }
            }
        }
        reconnectWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
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

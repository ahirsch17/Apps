import Foundation

enum WakeOnLAN {
    /// Sends a standard magic packet to wake a PC on the local network.
    /// Works when the PC is asleep or soft-off — no DeskPilot server required.
    static func wake(macAddress: String, broadcastHost: String = "255.255.255.255", port: UInt16 = 9) throws {
        let bytes = try parseMAC(macAddress)
        var packet = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: bytes)
        }

        let socket = try createBroadcastSocket()
        defer { close(socket) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        inet_pton(AF_INET, broadcastHost, &addr.sin_addr)

        let result = packet.withUnsafeBytes { buffer in
            withUnsafePointer(to: &addr) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                    sendto(
                        socket,
                        buffer.baseAddress,
                        packet.count,
                        0,
                        sockaddrPointer,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }

        guard result == packet.count else {
            throw WakeError.sendFailed
        }
    }

    enum WakeError: LocalizedError {
        case invalidMAC
        case socketFailed
        case sendFailed

        var errorDescription: String? {
            switch self {
            case .invalidMAC: return "Invalid MAC address — use format AA:BB:CC:DD:EE:FF"
            case .socketFailed: return "Could not open network socket"
            case .sendFailed: return "Wake packet could not be sent"
            }
        }
    }

    private static func parseMAC(_ string: String) throws -> [UInt8] {
        let cleaned = string
            .uppercased()
            .replacingOccurrences(of: "-", with: ":")
            .split(separator: ":")
            .map { String($0) }

        guard cleaned.count == 6, cleaned.allSatisfy({ $0.count == 2 }) else {
            throw WakeError.invalidMAC
        }

        return try cleaned.map { pair in
            guard let value = UInt8(pair, radix: 16) else {
                throw WakeError.invalidMAC
            }
            return value
        }
    }

    private static func createBroadcastSocket() throws -> Int32 {
        let socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else { throw WakeError.socketFailed }

        var enable: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_BROADCAST, &enable, socklen_t(MemoryLayout<Int32>.size))

        return socket
    }
}

import Foundation

enum WakeOnLAN {
    /// Sends a standard magic packet to wake a PC on the local network.
    /// Works when the PC is asleep or soft-off — no DeskPilot server required.
    static func wake(
        macAddress: String,
        pcHost: String,
        broadcastHost: String? = nil
    ) throws {
        let packet = try buildPacket(macAddress: macAddress)
        let subnetBroadcast = Self.subnetBroadcast(for: pcHost)
        let configuredBroadcast = broadcastHost?.trimmingCharacters(in: .whitespacesAndNewlines)

        var targets: [String] = []
        func appendUnique(_ host: String) {
            let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !targets.contains(trimmed) else { return }
            targets.append(trimmed)
        }

        appendUnique(subnetBroadcast)
        if let configuredBroadcast, configuredBroadcast != subnetBroadcast {
            appendUnique(configuredBroadcast)
        }
        appendUnique("255.255.255.255")
        appendUnique(pcHost)

        let ports: [UInt16] = [9, 7]
        var sentAny = false

        for host in targets {
            for port in ports {
                if send(packet: packet, toHost: host, port: port) {
                    sentAny = true
                }
            }
        }

        guard sentAny else {
            throw WakeError.sendFailed
        }
    }

    enum WakeError: LocalizedError {
        case invalidMAC
        case socketFailed
        case sendFailed

        var errorDescription: String? {
            switch self {
            case .invalidMAC:
                return "Invalid MAC address — use format AA:BB:CC:DD:EE:FF"
            case .socketFailed:
                return "Could not open network socket"
            case .sendFailed:
                return """
                Wake packet could not be sent. Use the same Wi‑Fi as your PC, allow \
                Local Network for DeskPilot in iPhone Settings, and enable Wake-on-LAN \
                in your PC's network adapter settings.
                """
            }
        }
    }

    static func subnetBroadcast(for host: String) -> String {
        let parts = host.split(separator: ".")
        guard parts.count == 4 else { return "255.255.255.255" }
        return "\(parts[0]).\(parts[1]).\(parts[2]).255"
    }

    private static func buildPacket(macAddress: String) throws -> Data {
        let bytes = try parseMAC(macAddress)
        var packet = Data(repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: bytes)
        }
        return packet
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

    private static func send(packet: Data, toHost host: String, port: UInt16) -> Bool {
        let socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else { return false }
        defer { close(socket) }

        var broadcastEnable: Int32 = 1
        setsockopt(
            socket,
            SOL_SOCKET,
            SO_BROADCAST,
            &broadcastEnable,
            socklen_t(MemoryLayout<Int32>.size)
        )

        var bindAddress = sockaddr_in()
        bindAddress.sin_family = sa_family_t(AF_INET)
        bindAddress.sin_port = 0
        bindAddress.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &bindAddress) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                bind(socket, address, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { return false }

        var destination = sockaddr_in()
        destination.sin_family = sa_family_t(AF_INET)
        destination.sin_port = port.bigEndian
        guard inet_pton(AF_INET, host, &destination.sin_addr) == 1 else { return false }

        let bytesSent = packet.withUnsafeBytes { buffer in
            withUnsafePointer(to: &destination) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { address in
                    sendto(
                        socket,
                        buffer.baseAddress,
                        packet.count,
                        0,
                        address,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }

        return bytesSent == packet.count
    }
}

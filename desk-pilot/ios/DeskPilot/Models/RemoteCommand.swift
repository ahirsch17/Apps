import Foundation

enum RemoteCommand {
    static func mouseMove(dx: Double, dy: Double) -> [String: Any] {
        ["type": "mouse_move", "dx": dx, "dy": dy]
    }

    static func mouseClick(button: String, action: String = "click") -> [String: Any] {
        ["type": "mouse_click", "button": button, "action": action]
    }

    static func scroll(dx: Double, dy: Double) -> [String: Any] {
        ["type": "scroll", "dx": dx, "dy": dy]
    }

    static func key(_ key: String, modifiers: [String] = []) -> [String: Any] {
        ["type": "key", "key": key, "modifiers": modifiers]
    }

    static func text(_ content: String) -> [String: Any] {
        ["type": "text", "content": content]
    }

    static func volume(action: String, steps: Int = 1) -> [String: Any] {
        ["type": "volume", "action": action, "steps": steps]
    }

    static func media(action: String) -> [String: Any] {
        ["type": "media", "action": action]
    }

    static func shortcut(_ name: String) -> [String: Any] {
        ["type": "shortcut", "name": name]
    }

    static func pair(pin: String, deviceName: String) -> [String: Any] {
        ["type": "pair", "pin": pin, "deviceName": deviceName]
    }

    static func ping() -> [String: Any] {
        ["type": "ping"]
    }

    static func power(action: String) -> [String: Any] {
        ["type": "power", "action": action]
    }

    static func wakeRoutine() -> [String: Any] {
        ["type": "wake_routine"]
    }

    static func launchApp(_ name: String) -> [String: Any] {
        ["type": "launch_app", "name": name]
    }
}

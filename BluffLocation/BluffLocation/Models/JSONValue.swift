import Foundation

/// A lightweight JSON representation for unknown server payloads.
enum JSONValue: Codable, Equatable {
  case object([String: JSONValue])
  case array([JSONValue])
  case string(String)
  case number(Double)
  case bool(Bool)
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
      return
    }
    if let b = try? container.decode(Bool.self) {
      self = .bool(b)
      return
    }
    if let n = try? container.decode(Double.self) {
      self = .number(n)
      return
    }
    if let s = try? container.decode(String.self) {
      self = .string(s)
      return
    }
    if let a = try? container.decode([JSONValue].self) {
      self = .array(a)
      return
    }
    if let o = try? container.decode([String: JSONValue].self) {
      self = .object(o)
      return
    }
    throw DecodingError.typeMismatch(
      JSONValue.self,
      .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .null:
      try container.encodeNil()
    case .bool(let b):
      try container.encode(b)
    case .number(let n):
      try container.encode(n)
    case .string(let s):
      try container.encode(s)
    case .array(let a):
      try container.encode(a)
    case .object(let o):
      try container.encode(o)
    }
  }
}

extension JSONValue {
  static func fromFoundation(_ value: Any) -> JSONValue {
    switch value {
    case is NSNull:
      return .null
    case let b as Bool:
      return .bool(b)
    case let i as Int:
      return .number(Double(i))
    case let d as Double:
      return .number(d)
    case let f as Float:
      return .number(Double(f))
    case let s as String:
      return .string(s)
    case let a as [Any]:
      return .array(a.map(JSONValue.fromFoundation))
    case let o as [String: Any]:
      var mapped: [String: JSONValue] = [:]
      mapped.reserveCapacity(o.count)
      for (k, v) in o { mapped[k] = JSONValue.fromFoundation(v) }
      return .object(mapped)
    default:
      return .string(String(describing: value))
    }
  }

  var stringValue: String? {
    if case .string(let s) = self { return s }
    return nil
  }
}


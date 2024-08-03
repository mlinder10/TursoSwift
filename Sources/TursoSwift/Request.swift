import Foundation

struct RequestBody: Codable {
  var baton: String?
  var requests: [Request]
  
  init(baton: String? = nil, sql: String, args: [Arg], close: Bool = true) {
    self.baton = baton

    let splitSqls = sql.split(separator: ";")

    var splitArgs = [[Argument]]()
    var argIndex = 0

    for queryIndex in 0..<splitSqls.count {
      splitArgs.append([])
      let argCount = splitSqls[queryIndex].components(separatedBy: "?").count - 1
      for i in argIndex..<argIndex + argCount {
        splitArgs[queryIndex].append(args[i].toArgument())
      }
      argIndex += argCount
    }

    var requests = [Request]()

    for queryIndex in 0..<splitSqls.count {
      requests.append(
        Request(
          type: .execute,
          stmt: Statement(
            sql: String(splitSqls[queryIndex]),
            args: splitArgs[queryIndex],
            named_args: nil
          )
        )
      )
    }

    self.requests = requests
    
    if close {
      self.requests.append(Request(type: .close, stmt: nil))
    }
  }
}

struct Request: Codable {
  var type: RequestType
  var stmt: Statement?
}

enum RequestType: String, Codable {
  case execute = "execute"
  case close = "close"
}

struct Statement: Codable {
  var sql: String
  var args: [Argument]?
  var named_args: [Argument]?
}

enum ArgumentValue: Codable {
  case string(String?)
  case f64(Float64?)

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
      switch self {
      case .string(let stringValue):
        if let value = stringValue {
          try container.encode(value)
        } else {
          try container.encodeNil()
        }
    case .f64(let float64Value):
        if let value = float64Value {
          try container.encode(value)
        } else {
          try container.encodeNil()
        }
      }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    // Attempt to decode as a String
    if let stringValue = try? container.decode(String?.self) {
      self = .string(stringValue)
      return
    }

    // Attempt to decode as a Float64
    if let float64Value = try? container.decode(Float64?.self) {
      self = .f64(float64Value)
      return
    }

    // If neither type is decoded successfully, throw an error
    throw DecodingError.typeMismatch(
      ArgumentValue.self,
      DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type for ArgumentValue")
    )
  }
}

struct Argument: Codable {
  var type: ArgumentType
  var value: ArgumentValue?
  var base64: String?
}

enum ArgumentType: String, Codable {
  case null = "null"
  case integer = "integer"
  case float = "float"
  case text = "text"
  case blob = "blob"
}
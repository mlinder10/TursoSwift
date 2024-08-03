import Foundation

struct ResponseBody: Codable {
  let baton: String?
  let base_url: String?
  let results: [Result]
}

struct Result: Codable {
  let type: ResultType
  let response: Response?

  func getRowsAsAny() -> [[Any?]]? {
    return nil
  }

  func getRowsAsData(replacements: [String: String] = [:]) -> Data? {
    guard let rows = self.response?.result?.rows else {
      return nil
    }
    guard let cols = self.response?.result?.cols else {
      return nil
    }

    let objects = rows.map { row in
      Dictionary(uniqueKeysWithValues: zip(cols, row).map { (col, value) in
        if let key = replacements.key(forValue: col.name) {
            return (key, value.toValue())
        }
        return (col.name, value.toValue())
      })
    }
    
    return try? JSONSerialization.data(withJSONObject: objects)
  }

  func getRowsAsType<T: Queryable>(_ type: T.Type) -> T? {
    guard let data = self.getRowsAsData(replacements: T.query) else {
      return nil
    }

    return try? JSONDecoder().decode(type, from: data)
  }

  func getAffectedRows() -> Int? {
    return self.response?.result?.affected_row_count
  }
}

enum ResultType: String, Codable {
  case ok = "ok"
  case error = "error"
}

struct Response: Codable {
  let type: RequestType?
  let result: ResponseResult?
}

struct ResponseResult: Codable {
  let cols: [Column]?
  let rows: [[RowValue]]?
  let affected_row_count: Int?
  let last_insert_rowid: String?
}

struct Column: Codable {
  let name: String
  let decltype: String
}

struct RowValue: Codable {
  let type: ArgumentType
  let value: ArgumentValue
  
  func toValue() -> Any? {
    switch self.value {
    case .string(let value):
      switch self.type {
      case .null:
        return nil
      case .integer:
        return Int(value!)
      case .float:
        return Double(value!)
      case .text:
        return value
      case .blob:
        return Data(base64Encoded: value!)
      }
    case .f64(let value):
      return value
    }
  }
}
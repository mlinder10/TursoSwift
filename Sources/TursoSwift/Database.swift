import Foundation

/// Column types supported by Turso
public enum Arg {
  case text(String?)
  case integer((any Numeric)?)
  case float((any BinaryFloatingPoint)?)
  case blob(Data?)
  case null

  func toArgument() -> Argument {
    return switch self {
      case .null:
        Argument(type: .null, value: .string("null"))
      case .integer(let value):
      switch value {
        case .some(let value):
        Argument(type: .integer, value: .string("\(value)"))
        case .none:
        Argument(type: .null, value: .string("null"))
      }
      case .float(let value):
      switch value {
        case .some(let value):
        Argument(type: .float, value: .f64(Double(value)))
        case .none:
        Argument(type: .null, value: .string("null"))
      }
      case .text(let value):
      switch value {
        case .some(let value):
        Argument(type: .text, value: .string(value))
        case .none:
        Argument(type: .null, value: .string("null"))
      }
      case .blob(let value):
      switch value {
        case .some(let value):
        Argument(type: .blob, base64: value.base64EncodedString())
        case .none:
        Argument(type: .null, value: .string("null"))
      }
    }
  }
}

public enum DatabaseError: Error {
  case invalidURL(String)
  case invalidResponse
  case invalidRowCount
  case rowParseError
  case unsupportedType
  case missingValue
  case invalidValue
  case noRows
  case noColumns
  case invalidSql
}

public final class Database: Sendable {
  
  private let url: URL
  private let token: String
  private var headers: [String: String] {
    [
      "Content-Type": "application/json",
      "Authorization": "Bearer \(token)"
    ]
  }
  
  // INIT
  
  private init(url: URL, token: String) {
    self.url = url
    self.token = token
  }
  
  /// Used to connect to the database
  ///
  /// ```swift
  /// let db = Database.connect(
  ///   url: "https://<database_name>-<organization_name>.turso.io/v2/pipeline",
  ///   token: "<database_token>"
  /// )
  /// ```
  /// - Parameters:
  ///   - url: Turso Database URL
  ///   - token: Database authentication token
  /// - Throws: Invalid URL
  /// - Returns: Instance of database connection
  public static func connect(url urlString: String, token: String) throws -> Self {
    guard let url = URL(string: urlString) else {
      throw DatabaseError.invalidURL(urlString)
    }
    return Self(url: url, token: token)
  }
  
  // TEST
  
  /// Used to test connection (typically on initialization)
  /// - Throws: Url Session Error
  public func ping() async throws {
    let _ = try await request("")
  }
  
  ///
  /// - Parameters:
  ///   - sql: SQL string using ? for arguments
  ///   - args: Arguments in order
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error, Invalid Row Count Error
  /// - Returns: Number of rows affected
  public func execute(_ sql: String, _ args: [Arg] = []) async throws -> Int {
    let body = try await request(sql, args)
    return body.results.reduce(0, { $0 + ($1.response?.result?.affected_row_count ?? 0) })
  }
  
  // ============================MAC/LINUX=======================================
  
#if os(macOS) || os(Linux) || os(iOS)
  func request(_ sql: String, _ args: [Arg] = []) async throws -> ResponseBody {
    let body = RequestBody(sql: sql, args: args)
    let bodyData = try JSONEncoder().encode(body)
    
    var request = URLRequest(url: self.url)
    request.httpMethod = "POST"
    request.httpBody = bodyData
    request.allHTTPHeaderFields = headers
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw DatabaseError.invalidResponse
    }
    
    return try JSONDecoder().decode(ResponseBody.self, from: data)
  }
#endif
  
  // ==============================WINDOWS=======================================
  
#if os(Windows)
  func request(_ sql: String, _ args: [Arg] = []) async throws -> ResponseBody {
    let body = RequestBody(sql: sql, args: args)
    let bodyData = try JSONEncoder().encode(body)
    
    var request = URLRequest(url: self.url)
    request.httpMethod = "POST"
    request.httpBody = bodyData
    request.allHTTPHeaderFields = headers
    
    let (data, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        guard let data = data, let response = response else {
          continuation.resume(throwing: DatabaseError.invalidResponse)
          return
        }
        continuation.resume(returning: (data, response))
      }
      task.resume()
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw DatabaseError.invalidResponse
    }
    
    if httpResponse.statusCode != 200 {
      throw DatabaseError.invalidResponse
    }
    
    return try JSONDecoder().decode(ResponseBody.self, from: data)
  }
#endif
}

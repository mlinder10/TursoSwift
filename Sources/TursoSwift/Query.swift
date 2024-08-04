import Foundation

public protocol Queryable: Codable {
  static var query: [String: String] { get }
}

extension Array: Queryable where Element: Queryable {
  public static var query: [String: String] {
    return Element.query
  }
}

struct Query {
  let sql: String
  let args: [Arg]
}

public class MultiTableQuery {
  private var queries: [Query]

  public init() {
    self.queries = []
  }

  public func query(_ sql: String, _ args: [Arg]) -> Self {
    if sql.hasSuffix(";") {
      self.queries.append(Query(sql: sql, args: args))
    } else {
      self.queries.append(Query(sql: sql + ";", args: args))
    }
    return self
  }

  func getQueries() -> [Query] {
    return self.queries
  }
}

extension Database {
  ///
  /// - Parameters:
  ///   - sql: SQL string using ? for arguments
  ///   - args: Arguments in order
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error
  /// - Returns: An array of arrays of String?, Int64?, Float64?, and Data? (One row)
  public func query(_ sql: String, _ args: [Arg] = []) async throws -> [[Any?]] {
    let body = try await request(sql, args)
    guard let rows = body.results.first?.response?.result?.rows else {
      return []
    }
    return rows.map { $0.map { $0.toValue() } }
  }
  
  ///
  /// - Parameters:
  ///   - sql: SQL string using ? for arguments
  ///   - args: Arguments in order
  ///   - type: Type to serialize to
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error
  /// - Returns: One object of type T
  public func queryAs<T: Queryable>(_ sql: String, _ args: [Arg] = [], type: T.Type) async throws -> T? {
    let body = try await request(sql, args)
    guard let data = body.results.first?.getRowsAsData(replacements: type.query) else {
      return nil
    }

    if isArray(type) {
      return try JSONDecoder().decode(T.self, from: data)
    } else {
      return try JSONDecoder().decode([T].self, from: data).first
    }
  }
  
  ///
  /// - Parameters:
  ///   - sql: SQL string using ? for arguments
  ///   - args: Arguments in order
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error, Invalid Row Count Error
  /// - Returns: An array of String?, Int64?, Float64?, and Data? (One row)
  public func queryOne(_ sql: String, _ args: [Arg] = []) async throws -> [Any?]? {
    let rows = try await query(sql, args)
    if rows.count == 0 {
      return nil
    }
    guard rows.count == 1 else {
      throw DatabaseError.invalidRowCount
    }
    return rows[0]
  }
}

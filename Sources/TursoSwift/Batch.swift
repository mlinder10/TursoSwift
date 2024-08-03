import Foundation

enum BatchResponse {
  case query([[Any?]])
  case queryAs(Queryable)
  case insert(Int)
  case execute(Int)
  case error(String)
}

fileprivate enum BatchType {
  case query
  case queryAs
  case insert
  case execute
}

fileprivate struct BatchStatement {
  let sql: String
  let args: [Arg]
  let type: Queryable.Type?
  let batchType: BatchType
}

public final class Batch {
  private var statements: [BatchStatement]
  private let db: Database

  fileprivate init(db: Database) {
    self.statements = []
    self.db = db
  }

  func query(_ sql: String, _ args: [Arg]) throws -> Self {
    if sql.split(separator: ";").count > 1 {
      throw DatabaseError.invalidSql
    }
    self.statements.append(BatchStatement(sql: sql, args: args, type: nil, batchType: .query))
    return self
  }

  func queryAs<T: Queryable>(_ sql: String, _ args: [Arg] = [], type: T.Type) throws -> Self {
    if sql.split(separator: ";").count > 1 {
      throw DatabaseError.invalidSql
    }
    self.statements.append(BatchStatement(sql: sql, args: args, type: type, batchType: .queryAs))
    return self
  }

  func insert<T: Insertable>(_ object: T) -> Self {
    let keys = Array(object.insert.keys)
    let args = keys.map { object.insert[$0]! }
    let sql =
    """
        INSERT INTO \(T.table)
            (\(keys.joined(separator: ", ")))
        VALUES
            (\(keys.map({ _ in "?" }).joined(separator: ", ")))
    """
    self.statements.append(BatchStatement(sql: sql, args: args, type: nil, batchType: .insert))
    return self
  }

  func insert<T: Insertable>(_ objects: [T]) -> Self {
    if objects.isEmpty { return self }
    let keys = Array(objects.first!.insert.keys)
    let args = objects.flatMap { obj in keys.map { obj.insert[$0]! } }
    let sql =
    """
      INSERT INTO \(T.table)
        (\(keys.joined(separator: ", ")))
      VALUES
        \(objects.map({ "(" + $0.insert.keys.map({ _ in "?" }).joined(separator: ", ")  + ")" }).joined(separator: ", "))
    """
    self.statements.append(BatchStatement(sql: sql, args: args, type: nil, batchType: .insert))
    return self
  }

  func execute(_ sql: String, _ args: [Arg] = []) throws -> Self {
    if sql.split(separator: ";").count > 1 {
      throw DatabaseError.invalidSql
    }
    self.statements.append(BatchStatement(sql: sql, args: args, type: nil, batchType: .execute))
    return self
  }

  func run() async throws -> [BatchResponse] {
    let sql = self.statements.map { $0.sql }.joined(separator: "; ")
    let args = self.statements.flatMap { $0.args }
    let res = try await self.db.request(sql, args)

    var responses = [BatchResponse]()
    for (result, stmt) in zip(res.results, self.statements) {
      switch stmt.batchType {
      case .query:
        if let rows = result.getRowsAsAny() {
          responses.append(.query(rows))
        } else {
          responses.append(.error("Invalid Response"))
        }
        break
      case .queryAs:
        if let data = result.getRowsAsType(stmt.type!) {
          responses.append(.queryAs(data))
        } else {
          responses.append(.error("Invalid Response"))
        }
        break
      case .insert:
        if let count = result.getAffectedRows() {
          responses.append(.insert(count))
        } else {
          responses.append(.error("Invalid Response"))
        }
        break
      case .execute:
        if let count = result.getAffectedRows() {
          responses.append(.execute(count))
        } else {
          responses.append(.error("Invalid Response"))
        }
        break
      }
    }

    return responses
  }
}

extension Database {
  public func batch() -> Batch {
    return Batch(db: self)
  }
}

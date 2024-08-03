public protocol Insertable: Queryable {
  static var table: String { get }

  var insert: [String: Arg] { get }
}

extension Insertable {
  fileprivate func getTable() -> String {
    return Self.table
  }
}

/// Used with Database().multiTableInsert to
/// insert values into multiple tables with
/// one HTTP request
///
/// Use the `.add()` method to add insertables
public class MultiTableInsert {
  private var objects: [[Any]]

  public init() {
    self.objects = []
  }

  ///
  /// - Parameter objects: List of insertable objects
  /// - Returns: This object to chain `.add()` method calls
  public func add<T: Insertable>(_ objects: [T]) -> Self {
    if objects.isEmpty { return self }
    self.objects.append(objects)
    return self
  }

  func getObjects() -> [[Insertable]] {
    return self.objects as! [[Insertable]]
  }
}

extension Database {
  ///
  /// - Parameter object: Object to insert into the database
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error
  /// - Returns: Number of rows affected
  public func insert<T: Insertable>(_ object: T) async throws -> Int {
    let keys = Array(object.insert.keys)
    let args = keys.map { object.insert[$0]! }
    let sql =
    """
        INSERT INTO \(T.table)
            (\(keys.joined(separator: ", ")))
        VALUES
            (\(keys.map({ _ in "?" }).joined(separator: ", ")))
    """
    return try await execute(sql, args)
  }
  
  ///
  /// - Parameter objects: Objects to insert into database
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error
  /// - Returns: Number of rows affected
  public func insert<T: Insertable>(_ objects: [T]) async throws -> Int {
    if objects.isEmpty { return 0 }
    let keys = Array(objects.first!.insert.keys)
    let args = objects.flatMap { obj in keys.map { obj.insert[$0]! } }
    let sql =
    """
        INSERT INTO \(T.table)
            (\(keys.joined(separator: ", ")))
        VALUES
            \(objects.map({ "(" + $0.insert.keys.map({ _ in "?" }).joined(separator: ", ")  + ")" }).joined(separator: ", "))
    """
    return try await execute(sql, args)
  }
  
  ///
  ///
  /// ```swift
  /// struct User: Insertable { ... }
  /// struct Order: Insertable { ... }
  ///
  /// let users = [User(), User()]
  /// let orders = [Order(), Order()]
  ///
  /// let db = try Database.connect(url: "...", token: "...")
  /// let rowsAffected = try await db.multiTableInsert(
  ///   MultiTableInsert()
  ///     .add(users)
  ///     .add(orders)
  /// )
  /// ```
  /// - Parameter inserts: Class used to store multiple lists of different types of insertables
  /// - Throws: Json Encode Error, Url Session Error, Json Decode Error
  /// - Returns: Number of rows affected
  public func multiTableInsert(_ inserts: MultiTableInsert) async throws -> Int {
    if inserts.getObjects().isEmpty { return 0 }
    var sql =
    """
      BEGIN TRANSACTION;
    
    """
    var args = [Arg]()
    
    for objects in inserts.getObjects() {
      let keys = objects.first!.insert.keys
      args += objects.flatMap { obj in keys.map { obj.insert[$0]! } }
      sql +=
      """
        INSERT INTO \(objects.first!.getTable())
            (\(keys.joined(separator: ", ")))
        VALUES
            \(objects.map({ "(" + $0.insert.keys.map({ _ in "?" }).joined(separator: ", ")  + ")" }).joined(separator: ", "));
      
      """
    }
    
    sql += "COMMIT;"
    
    return try await execute(sql, args)
  }
}
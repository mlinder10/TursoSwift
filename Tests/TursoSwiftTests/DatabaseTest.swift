import XCTest
@testable import TursoSwift
import SwiftDotenv

// Definitions
struct User: Insertable {
    var identify: String
    var name: String
    var emailAddress: String

    // Database
    static var table: String { "users" }
    static var query: [String: String] {[
        "identify": "id",
        "name": "username",
        "emailAddress": "email"
    ]}
    var insert: [String: Arg] {[
        "id": .text(identify),
        "username": .text(name),
        "email": .text(emailAddress)
    ]}
}

struct Post: Insertable {
    var id: String
    var title: String
    var likes: Int
    var rating: Double

    // Database
    static var table: String { "posts" }
    static var query: [String: String] {[:]}
    var insert: [String: Arg] {[
        "id": .text(id),
        "title": .text(title),
        "likes": .integer(likes),
        "rating": .float(rating)
    ]}
}

fileprivate func loadEnv() throws {
  try Dotenv.configure()
}

class DB {
  static let shared = try! connect()
  
  private static func connect() throws -> Database {
    try loadEnv()
    let url = Dotenv.values["DB_URL"] ?? ""
    let token = Dotenv.values["DB_TOKEN"] ?? ""

    return try Database.connect(
      url: url,
      token: token
    )
  }
}

final class DatabaseTest: XCTestCase {
  func testConnectAndPing() async throws {
    // given
    try loadEnv()

    let url = Dotenv.values["DB_URL"] ?? ""
    let token = Dotenv.values["DB_TOKEN"] ?? ""

    let db = try Database.connect(
      url: url,
      token: token
    )
    
    // then
    try await db.ping()
  }
  
  func testInvalidUrl() throws {
    XCTAssertThrowsError(
      try Database.connect(
        url: "",
        token: ""
      )
    )
  }
}

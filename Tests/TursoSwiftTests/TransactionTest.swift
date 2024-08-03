import XCTest
@testable import TursoSwift

final class TransactionTest: XCTestCase {
  func testTransaction() async throws {
    // given
    let users = [
      User(identify: "1", name: "John", emailAddress: "j@j.com"),
      User(identify: "2", name: "Jane", emailAddress: "j@j.com"),
    ]
    let posts = [
      Post(id: UUID().uuidString, title: "Hello", likes: 4, rating: 2.3),
      Post(id: UUID().uuidString, title: "World", likes: 2, rating: 4.2),
      Post(id: UUID().uuidString, title: "Swift", likes: 8, rating: 5.0),
    ]

    let _ = try await DB.shared.insert(users)
    let _ = try await DB.shared.insert(posts)

    // when
    let res = try await DB.shared.transaction()
      .queryAs("SELECT * FROM users", type: [User].self)
      .queryAs("SELECT * FROM posts", type: [Post].self)
      .run()

    // then
    XCTAssertEqual(res.count, 2)
    switch res[0] {
      case .queryAs(let data):
        let users = data as! [User]
        XCTAssertEqual(users.count, 2)
        break
      default:
        XCTFail("Incorrect response type")
    }

    switch res[1] {
      case .queryAs(let data):
        let posts = data as! [Post]
        XCTAssertEqual(posts.count, 3)
        break
      case .query(_):
        XCTFail("Incorrect response type")
        break
      case .execute(_):
        XCTFail("Incorrect response type")
        break
      case .insert(_):
        XCTFail("Incorrect response type")
        break
      case .error(_):
        XCTFail("Failed transaction")
        break
    }
    
    // cleanup
    let _ = try await DB.shared.transaction()
      .execute(
        "DELETE FROM users WHERE id IN (?, ?)",
        [.text(users[0].identify), .text(users[1].identify)]
      )
      .execute(
        "DELETE FROM posts WHERE id IN (?, ?, ?)",
        [.text(posts[0].id), .text(posts[1].id), .text(posts[2].id)]
      )
      .run()
  }
}
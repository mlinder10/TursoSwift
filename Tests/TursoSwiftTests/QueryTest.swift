import XCTest
@testable import TursoSwift

final class QueryTest: XCTestCase {
  func testQuery() async throws {
    // given
    let posts = [
      Post(id: UUID().uuidString, title: "Hello", likes: 4, rating: 2.3),
      Post(id: UUID().uuidString, title: "World", likes: 2, rating: 4.2),
      Post(id: UUID().uuidString, title: "Swift", likes: 8, rating: 5.0),
    ]

    let _ = try await DB.shared.insert(posts)

    // when
    let res = try await DB.shared.query(
      """
        SELECT
          id, title, likes, rating
        FROM
          posts
        WHERE
          id IN (?, ?, ?)
      """,
      [.text(posts[0].id), .text(posts[1].id), .text(posts[2].id)]
    )

    // then
    XCTAssertNotNil(res)
    XCTAssertEqual(res.count, 3)

    let parsed = res.map {
      Post(
        id: $0[0] as! String,
        title: $0[1] as! String,
        likes: $0[2] as! Int,
        rating: $0[3] as! Double
      )
    }

    let first = parsed.first { $0.id == posts.first!.id }

    XCTAssertNotNil(first)
    XCTAssertEqual(first?.title, "Hello")
    XCTAssertEqual(first?.likes, 4)
    XCTAssertEqual(first?.rating, 2.3)

    // cleanup
    let _ = try await DB.shared.execute(
      "DELETE FROM posts WHERE id IN (?, ?, ?)",
      [.text(posts[0].id), .text(posts[1].id), .text(posts[2].id)]
    )
  }

  func testQueryOne() async throws {
    // given
    let posts = [
      Post(id: UUID().uuidString, title: "Hello", likes: 4, rating: 2.3),
      Post(id: UUID().uuidString, title: "World", likes: 2, rating: 4.2),
      Post(id: UUID().uuidString, title: "Swift", likes: 8, rating: 5.0),
    ]

    let _ = try await DB.shared.insert(posts)

    // when
    let res = try await DB.shared.queryOne(
      "SELECT id, title, likes, rating FROM posts WHERE id = ?",
      [.text(posts[0].id)]
    )

    // then
    XCTAssertNotNil(res)

    let parsed = Post(
      id: res![0] as! String,
      title: res![1] as! String,
      likes: res![2] as! Int,
      rating: res![3] as! Double
    )

    XCTAssertEqual(parsed.id, posts[0].id)
    XCTAssertEqual(parsed.title, "Hello")
    XCTAssertEqual(parsed.likes, 4)
    XCTAssertEqual(parsed.rating, 2.3)

    // cleanup
    let _ = try await DB.shared.execute(
      "DELETE FROM posts WHERE id IN (?, ?, ?)",
      [.text(posts[0].id), .text(posts[1].id), .text(posts[2].id)]
    )
  }

  func testQueryAs() async throws {
    // given
    let posts = [
      Post(id: UUID().uuidString, title: "Hello", likes: 4, rating: 2.3),
      Post(id: UUID().uuidString, title: "World", likes: 2, rating: 4.2),
      Post(id: UUID().uuidString, title: "Swift", likes: 8, rating: 5.0),
    ]

    let _ = try await DB.shared.insert(posts)

    // when
    let res = try await DB.shared.queryAs(
      """
        SELECT 
          *
        FROM
          posts
        WHERE
          id IN (?, ?, ?)
      """,
      [.text(posts[0].id), .text(posts[1].id), .text(posts[2].id)],
      type: [Post].self
    )

    // then
    XCTAssertNotNil(res)
    XCTAssertEqual(res?.count, 3)

    let first = res?.first { $0.id == posts.first!.id }

    XCTAssertNotNil(first)
    XCTAssertEqual(first?.title, "Hello")
    XCTAssertEqual(first?.likes, 4)
    XCTAssertEqual(first?.rating, 2.3)

    // cleanup
    let _ = try await DB.shared.execute(
      "DELETE FROM posts WHERE id IN (?, ?, ?)",
      [.text(posts[0].id), .text(posts[1].id), .text(posts[2].id)]
    )
  }
}
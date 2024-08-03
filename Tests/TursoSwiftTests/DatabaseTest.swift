import XCTest
@testable import TursoSwift


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

class DB {
    static let shared = try! Database.connect(
        url: "https://word-catching-journal-mlinder10.turso.io/v2/pipeline",
        token: "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3MjI0NDIxMDQsImlkIjoiNGEyMDNhNGYtYzA4NS00YzE4LWI3ODktYWFjYTJiMjIxZjJhIn0.V5wUTuGqlXGKMeiOo4MPi4lp2U9gwbMrHw-H4iSFEsCnsau1kd2GGx28xAHCaFvuVKueaEcr_5i5AUen0mxFCQ"
    )
}

final class DatabaseTest: XCTestCase {
    func testConnectAndPing() async throws {
        // given
        let db = try Database.connect(
          url: "https://word-catching-journal-mlinder10.turso.io/v2/pipeline",
          token: "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3MjI0NDIxMDQsImlkIjoiNGEyMDNhNGYtYzA4NS00YzE4LWI3ODktYWFjYTJiMjIxZjJhIn0.V5wUTuGqlXGKMeiOo4MPi4lp2U9gwbMrHw-H4iSFEsCnsau1kd2GGx28xAHCaFvuVKueaEcr_5i5AUen0mxFCQ"
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

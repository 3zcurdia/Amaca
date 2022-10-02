import XCTest
@testable import Amaca

final class AmacaTests: XCTestCase {
    struct Fish: Codable, Identifiable {
        let id: String
    }
    func testClientRequest() async {
        let apiClient = Amaca.Client("https://plasticfishes.herokuapp.com")
        let endpoint = Amaca.Endpoint<Fish>(client: apiClient, route: "/api/fishes")
        let fishes = try! await endpoint.show()
        XCTAssertEqual(14, fishes.count)
    }

    struct Character: Codable, Identifiable {
        let id: Int
        let name: String
    }
    func testClientRequestRnM() async {
        let apiClient = Amaca.Client("https://rickandmortyapi.com/")
        let endpoint = Amaca.Endpoint<Character>(client: apiClient, route: "/api/character/")
        let result = try! await endpoint.show(Character(id: 1, name: ""))
        XCTAssertEqual("Rick Sanchez", result!.name)
    }
}

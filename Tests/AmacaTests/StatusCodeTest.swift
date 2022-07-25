import Foundation
import XCTest
@testable import Amaca

final class StatusCodeTests: XCTestCase {
    func testInfo() throws {
        XCTAssertEqual(Amaca.StatusCode(rawValue: 100), Amaca.StatusCode.info)
    }
    
    func testSuccess() throws {
        XCTAssertEqual(Amaca.StatusCode(rawValue: 200), Amaca.StatusCode.success)
    }
    
    func testRedirect() throws {
        XCTAssertEqual(Amaca.StatusCode(rawValue: 300), Amaca.StatusCode.redirection)
    }
    
    func testClientError() throws {
        XCTAssertEqual(Amaca.StatusCode(rawValue: 400), Amaca.StatusCode.clientError)
    }
    
    func testServerError() throws {
        XCTAssertEqual(Amaca.StatusCode(rawValue: 500), Amaca.StatusCode.serverError)
    }
}

//
//  Client.swift
//  FishApp
//
//  Created by Luis Ezcurdia on 23/07/22.
//

import Foundation

extension Amaca {
    public enum NetworkError: Error {
        case invalidRequest(String)
        case invalidResponse(String)
        case clientError(String)
        case serverError(String)
    }

    public struct Client {
        let baseUrl: String
        let session: URLSession
        public var cacheDelegate: CacheResponseDelegate?
        var contentMode = Request.ContentMode.json

        public init(_ baseUrl: String, session: URLSession = URLSession.shared) {
            self.baseUrl = baseUrl
            self.session = session
        }

        public func get(path: String = "/", queryItems: [String: String]? = nil, headers: [String: String]? = nil) async throws -> Data? {
            return try await request(method: "get", path: path, queryItems: queryItems, headers: headers)
        }

        public func post(path: String = "/", body: Data? = nil, queryItems: [String: String]? = nil, headers: [String: String]? = nil) async throws -> Data? {
            return try await request(method: "post", path: path, body: body, queryItems: queryItems, headers: headers)
        }

        public func put(path: String = "/", body: Data? = nil, queryItems: [String: String]? = nil, headers: [String: String]? = nil) async throws -> Data? {
            return try await request(method: "put", path: path, body: body, queryItems: queryItems, headers: headers)
        }

        public func patch(path: String = "/", body: Data? = nil, queryItems: [String: String]? = nil, headers: [String: String]? = nil) async throws -> Data? {
            return try await request(method: "patch", path: path, body: body, queryItems: queryItems, headers: headers)
        }

        public func delete(path: String = "/", queryItems: [String: String]? = nil, headers: [String: String]? = nil) async throws -> Data? {
            return try await request(method: "delete", path: path, queryItems: queryItems, headers: headers)
        }

        public func request(method: String, path: String = "/", body: Data? = nil,
                     queryItems: [String: String]? = nil, headers: [String: String]? = nil) async throws -> Data? {
            var req = Request(baseUrl: self.baseUrl)
            req.method = method
            req.path = path
            req.body = body
            req.queryItems = queryItems
            req.contentMode = contentMode
            req.headers = headers
            guard let urlRequest = req.urlRequest else {
                throw NetworkError.invalidRequest("Invalid \(method) request for \(path)")
            }
            return try await request(urlRequest)
        }

        public func request(_ req: URLRequest) async throws -> Data? {
            cacheDelegate?.willMakeRequest(urlRequest: req)
            if let data = cacheDelegate?.fetchCachedRequest(urlRequest: req) {
                return data
            }
            let (data, response) = try await session.data(for: req)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse("Invalid http url response")
            }

            switch StatusCode(rawValue: httpResponse.statusCode) {
            case .success:
                cacheDelegate?.didFinishRequestSuccessful(data: data)
                return data
            case .clientError:
                cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: req, data: data)
                throw NetworkError.clientError("Client error code: \(httpResponse.statusCode)")
            case .serverError:
                cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: req, data: data)
                throw NetworkError.serverError("Server error code: \(httpResponse.statusCode)")
            default:
                cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: req, data: data)
                #if DEBUG
                debugPrint(httpResponse)
                debugPrint(data)
                #endif
                return nil
            }
        }
    }
}

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
        let auth: Authenticable?
        public var defaultHeaders: [String: String]
        let session: URLSession
        public var cacheDelegate: CacheResponseDelegate?

        public init(_ baseUrl: String, auth: Authenticable? = nil, defaultHeaders: [String: String] = [:], session: URLSession = URLSession.shared) {
            self.baseUrl = baseUrl
            self.session = session
            self.auth = auth
            self.defaultHeaders = defaultHeaders
        }

        public func get(path: String = "/",
                 queryItems: [String: String] = [:],
                 headers: [String: String] = [:]) async throws -> Data? {
            return try await request(method: "get", path: path, queryItems: queryItems, headers: headers)
        }

        public func post(path: String = "/",
                  queryItems: [String: String] = [:],
                  headers: [String: String] = [:],
                  body: Data? = nil) async throws -> Data? {
            return try await request(method: "post", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func put(path: String = "/",
                 queryItems: [String: String] = [:],
                 headers: [String: String] = [:],
                 body: Data? = nil) async throws -> Data? {
            return try await request(method: "put", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func patch(path: String = "/",
                   queryItems: [String: String] = [:],
                   headers: [String: String] = [:],
                   body: Data? = nil) async throws -> Data? {
            return try await request(method: "patch", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func delete(path: String = "/",
                    queryItems: [String: String] = [:],
                    headers: [String: String] = [:]) async throws -> Data? {
            return try await request(method: "delete", path: path, queryItems: queryItems, headers: headers)
        }

        func request(method: String,
                     path: String,
                     queryItems: [String: String] = [:],
                     headers: [String: String] = [:],
                     body: Data? = nil) async throws -> Data? {
            guard var urlComponents = URLComponents(string: baseUrl) else {
                throw NetworkError.invalidRequest("URL invalid for: \(baseUrl)")
            }
            urlComponents.path = path

            var query: [URLQueryItem] = []
            queryItems.forEach { (key, value) in
                query.append(URLQueryItem(name: key, value: value))
            }

            if let queryAuth = auth?.queryItems() {
                queryAuth.forEach { (key, value) in
                    query.append(URLQueryItem(name: key, value: value))
                }
            }
            urlComponents.queryItems = query

            guard let url = urlComponents.url else {
                throw NetworkError.invalidRequest("URL invalid for '\(baseUrl)' with method '\(method)' and path '\(path)'")
            }

            return try await request(method: method, url: url, headers: headers, body: body)
        }

        public func request(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) async throws -> Data? {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method
            if let body = body {
                urlRequest.httpBody = body
            }
            defaultHeaders.forEach { (key, value) in
                urlRequest.setValue(key, forHTTPHeaderField: value)
            }
            headers.forEach { (key, value) in
                urlRequest.setValue(key, forHTTPHeaderField: value)
            }
            auth?.headers().forEach { (key, value) in
                urlRequest.setValue(key, forHTTPHeaderField: value)
            }

            return try await request(urlRequest: urlRequest)
        }

        public func request(urlRequest: URLRequest) async throws -> Data? {
            cacheDelegate?.willMakeRequest(urlRequest: urlRequest)
            if let cachedData = cacheDelegate?.fetchCachedRequest(urlRequest: urlRequest) {
                return cachedData
            }
            let (data, response) = try await session.data(for: urlRequest)
            let httpResponse = response as! HTTPURLResponse

            switch StatusCode(rawValue: httpResponse.statusCode) {
            case .success:
                cacheDelegate?.didFinishRequestSuccessful(data: data)
                return data
            case .clientError:
                cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: urlRequest, data: data)
                throw NetworkError.clientError("Client error with status code: \(httpResponse.statusCode)")
            case .serverError:
                cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: urlRequest, data: data)
                throw NetworkError.serverError("Server error with status code: \(httpResponse.statusCode)")
            default:
                cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: urlRequest, data: data)
                #if DEBUG
                debugPrint(httpResponse)
                debugPrint(data)
                #endif
                return nil
            }
        }
    }
}

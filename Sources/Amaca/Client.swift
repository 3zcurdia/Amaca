//
//  Client.swift
//  FishApp
//
//  Created by Luis Ezcurdia on 23/07/22.
//

import Foundation
import Combine

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

        public func getPublisher(path: String = "/",
                 queryItems: [String: String] = [:],
                 headers: [String: String] = [:]) -> AnyPublisher<Data, URLError> {
            return requestPublisher(method: "get", path: path, queryItems: queryItems, headers: headers)
        }

        public func post(path: String = "/",
                  queryItems: [String: String] = [:],
                  headers: [String: String] = [:],
                  body: Data? = nil) async throws -> Data? {
            return try await request(method: "post", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func postPublisher(path: String = "/",
                  queryItems: [String: String] = [:],
                  headers: [String: String] = [:],
                  body: Data? = nil) -> AnyPublisher<Data, URLError> {
            return requestPublisher(method: "post", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func put(path: String = "/",
                 queryItems: [String: String] = [:],
                 headers: [String: String] = [:],
                 body: Data? = nil) async throws -> Data? {
            return try await request(method: "put", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func putPublisher(path: String = "/",
                 queryItems: [String: String] = [:],
                 headers: [String: String] = [:],
                 body: Data? = nil) -> AnyPublisher<Data, URLError> {
            return requestPublisher(method: "put", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func patch(path: String = "/",
                   queryItems: [String: String] = [:],
                   headers: [String: String] = [:],
                   body: Data? = nil) async throws -> Data? {
            return try await request(method: "patch", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func patchPublisher(path: String = "/",
                   queryItems: [String: String] = [:],
                   headers: [String: String] = [:],
                   body: Data? = nil) -> AnyPublisher<Data, URLError> {
            return requestPublisher(method: "patch", path: path, queryItems: queryItems, headers: headers, body: body)
        }

        public func delete(path: String = "/",
                    queryItems: [String: String] = [:],
                    headers: [String: String] = [:]) async throws -> Data? {
            return try await request(method: "delete", path: path, queryItems: queryItems, headers: headers)
        }

        public func deletePublisher(path: String = "/",
                    queryItems: [String: String] = [:],
                    headers: [String: String] = [:]) -> AnyPublisher<Data, URLError> {
            return requestPublisher(method: "delete", path: path, queryItems: queryItems, headers: headers)
        }

        func requestPublisher(method: String,
                     path: String,
                     queryItems: [String: String] = [:],
                     headers: [String: String] = [:],
                     body: Data? = nil) -> AnyPublisher<Data, URLError> {
            guard let url = try? buildUrl(method: method, path: path, queryItems: queryItems) else {
                return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
            }
            return requestPublisher(method: method, url: url, headers: headers, body: body)
        }

        func request(method: String,
                     path: String,
                     queryItems: [String: String] = [:],
                     headers: [String: String] = [:],
                     body: Data? = nil) async throws -> Data? {
            let url = try buildUrl(method: method, path: path, queryItems: queryItems)
            return try await request(method: method, url: url, headers: headers, body: body)
        }

        private func buildUrl(method: String, path: String, queryItems: [String: String] = [:]) throws -> URL {
            guard var urlComponents = URLComponents(string: baseUrl) else {
                throw NetworkError.invalidRequest("URL invalid for: \(baseUrl)")
            }
            urlComponents.path = path

            var query: [URLQueryItem] = []
            queryItems.forEach { (key, value) in
                query.append(URLQueryItem(name: key, value: value))
            }

            if let queryAuth = auth?.queryItems() {
                queryAuth.forEach { query.append(URLQueryItem(name: $0, value: $1)) }
            }
            urlComponents.queryItems = query

            if let url = urlComponents.url {
                return url
            } else {
                throw NetworkError.invalidRequest("URL invalid for '\(baseUrl)' with method '\(method)' and path '\(path)'")
            }
        }

        public func requestPublisher(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) -> AnyPublisher<Data, URLError> {
            return requestPublisher(for: buildRequest(method: method, url: url, headers: headers, body: body))
        }

        public func request(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) async throws -> Data? {
            return try await request(urlRequest: buildRequest(method: method, url: url, headers: headers, body: body))
        }

        private func buildRequest(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil) -> URLRequest {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method
            if let body = body {
                urlRequest.httpBody = body
            }
            defaultHeaders.forEach { (key, value) in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            headers.forEach { (key, value) in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            auth?.headers().forEach { (key, value) in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            return urlRequest
        }

        public func requestPublisher(for urlRequest: URLRequest) -> AnyPublisher<Data, URLError> {
            return URLSession
                .shared
                .dataTaskPublisher(for: urlRequest)
                .map { (data, response) in
                    let httpResponse = response as! HTTPURLResponse

                    if StatusCode(rawValue: httpResponse.statusCode) == .success {
                        cacheDelegate?.didFinishRequestSuccessful(data: data)
                    } else {
                        cacheDelegate?.didFinishRequestUnsuccessful(urlRequest: urlRequest, data: data)
                        #if DEBUG
                        debugPrint(httpResponse)
                        debugPrint(data)
                        #endif
                    }
                    return data

                }
                .eraseToAnyPublisher()
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

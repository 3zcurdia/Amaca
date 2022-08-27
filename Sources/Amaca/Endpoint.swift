//
//  Endpoint.swift
//  FishApp
//
//  Created by Luis Ezcurdia on 24/07/22.
//

import Foundation

extension Amaca {
    public enum EndpointError: Error {
        case invalidEncoding(String)
        case invalidDecoding(String)
    }
    enum ContentMode {
        case json

        func headers() -> [String:String] {
            switch self {
            case .json:
                return [
                    "Accept": "application/json",
                    "Content-Type": "application/json"
                ]
            }
        }
    }

    public struct Endpoint<T> where T: Codable, T: Identifiable {
        var client: Client
        let route: String
        public var encoder: JSONEncoder
        public var decoder: JSONDecoder

        public init(client: Client, route: String) {
            self.client = client
            self.client.defaultHeaders.merge(ContentMode.json.headers()) { (_current, other) in other }
            self.route = route
            self.encoder = JSONEncoder()
            self.encoder.keyEncodingStrategy = .convertToSnakeCase
            self.decoder = JSONDecoder()
            self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        }

        public func show(params: [String: String] = [:]) async throws -> [T] {
            let data = try await client.get(path: route, queryItems: params)
            guard let data = data else { return [] }

            do {
                let json = try decoder.decode([T].self, from: data)
                return json
            } catch let err {
                #if DEBUG
                debugPrint(err)
                debugPrint(String(data: data, encoding: .utf8) ?? "")
                #endif
                throw EndpointError.invalidDecoding("Unable to decode response")
            }
        }

        public func show(_ model: T, params: [String: String] = [:]) async throws -> T? {
            let data = try await client.get(path: "\(route)/\(model.id)", queryItems: params)
            guard let data = data else { return nil }

            do {
                let json = try decoder.decode(T.self, from: data)
                return json
            } catch let err {
                #if DEBUG
                debugPrint(err)
                debugPrint(String(data: data, encoding: .utf8) ?? "")
                #endif
                throw EndpointError.invalidDecoding("Unable to decode response")
            }
        }

        public func create(_ model: T, params: [String: String] = [:]) async throws -> T? {
            var body: Data?
            do {
                body = try encoder.encode(model)
            } catch let err {
                #if DEBUG
                debugPrint(err)
                #endif
                throw EndpointError.invalidEncoding("Unable to encode request")
            }
            let data = try await client.post(path: route, queryItems: params, body: body)
            guard let data = data else { return nil }

            do {
                let json = try decoder.decode(T.self, from: data)
                return json
            } catch let err {
                #if DEBUG
                debugPrint(err)
                debugPrint(String(data: data, encoding: .utf8) ?? "")
                #endif
                throw EndpointError.invalidDecoding("Unable to decode response")
            }
        }

        public func update(_ model: T, params: [String: String] = [:]) async throws -> T? {
            var body: Data?
            do {
                body = try encoder.encode(model)
            } catch let err {
                #if DEBUG
                debugPrint(err)
                #endif
                throw EndpointError.invalidEncoding("Unable to encode request")
            }
            let data = try await client.patch(path: "\(route)/\(model.id)", queryItems: params, body: body)
            guard let data = data else { return nil }

            do {
                let json = try decoder.decode(T.self, from: data)
                return json
            } catch let err {
                #if DEBUG
                debugPrint(err)
                debugPrint(String(data: data, encoding: .utf8) ?? "")
                #endif
                throw EndpointError.invalidDecoding("Unable to decode response")
            }
        }

        public func destroy(_ model: T, params: [String: String] = [:]) async throws -> T? {
            let data = try await client.delete(path: "\(route)/\(model.id)", queryItems: params)
            guard let data = data else { return nil }

            do {
                let json = try decoder.decode(T.self, from: data)
                return json
            } catch let err {
                #if DEBUG
                debugPrint(err)
                debugPrint(String(data: data, encoding: .utf8) ?? "")
                #endif
                throw EndpointError.invalidDecoding("Unable to decode response")
            }
        }
    }
}

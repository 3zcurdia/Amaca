//
//  Endpoint.swift
//  FishApp
//
//  Created by Luis Ezcurdia on 24/07/22.
//

import Foundation

public enum EndpointError: Error {
    case invalidEncoding(String)
    case invalidDecoding(String)
}

public struct Endpoint<T> where T: Codable, T: Identifiable {
    let client: Client
    let route: String
    let auth: Authenticable?
    public var encoder: JSONEncoder
    public var decoder: JSONDecoder

    public init(client: Client, route: String, auth: Authenticable? =  nil) {
        self.client = client
        self.route = route
        self.auth = auth
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    public func show(params: [String: String]? = nil) async throws -> [T] {
        var query = params ?? [:]
        query.merge(auth?.queryItems() ?? [:]) { (_, other) in other }
        let data = try await client.get(path: route, queryItems: query, headers: auth?.headers())
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

    public func show(_ model: T, params: [String: String]? = nil) async throws -> T? {
        var query = params ?? [:]
        query.merge(auth?.queryItems() ?? [:]) { (_, other) in other }
        let data = try await client.get(path: "\(route)/\(model.id)", queryItems: query, headers: auth?.headers())
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

    public func create(_ model: T, params: [String: String]? = nil) async throws -> T? {
        var body: Data?
        do {
            body = try encoder.encode(model)
        } catch let err {
            #if DEBUG
            debugPrint(err)
            #endif
            throw EndpointError.invalidEncoding("Unable to encode request")
        }
        var query = params ?? [:]
        query.merge(auth?.queryItems() ?? [:]) { (_, other) in other }
        let data = try await client.post(path: route, body: body, queryItems: query, headers: auth?.headers())
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

    public func update(_ model: T, params: [String: String]? = nil) async throws -> T? {
        var body: Data?
        do {
            body = try encoder.encode(model)
        } catch let err {
            #if DEBUG
            debugPrint(err)
            #endif
            throw EndpointError.invalidEncoding("Unable to encode request")
        }
        var query = params ?? [:]
        query.merge(auth?.queryItems() ?? [:]) { (_, other) in other }
        let data = try await client.patch(path: "\(route)/\(model.id)", body: body, queryItems: query, headers: auth?.headers())
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

    public func destroy(_ model: T, params: [String: String]? = nil) async throws -> T? {
        var query = params ?? [:]
        query.merge(auth?.queryItems() ?? [:]) { (_, other) in other }
        let data = try await client.delete(path: "\(route)/\(model.id)", queryItems: query, headers: auth?.headers())
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

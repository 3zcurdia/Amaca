//
//  Authenticable.swift
//  FishApp
//
//  Created by Luis Ezcurdia on 24/07/22.
//

import Foundation

public protocol Authenticable {
    func headers() -> [String: String]
    func queryItems() -> [String: String]
}

extension Amaca {
    public struct HeaderAuthentication: Authenticable {
        let method: String
        let token: String

        public init(token: String, method: String = "Bearer") {
            self.token = token
            self.method = method
        }

        public func headers() -> [String: String] {
            return ["Authentication": "\(method) \(token)"]
        }

        public func queryItems() -> [String: String] {
            return [:]
        }
    }

    public struct QueryAuthentication: Authenticable {
        let key: String
        let token: String

        public init(token: String, key: String = "token") {
            self.token = token
            self.key = key
        }

        public func headers() -> [String: String] {
            return [:]
        }

        public func queryItems() -> [String: String] {
            return [key: token]
        }
    }
}

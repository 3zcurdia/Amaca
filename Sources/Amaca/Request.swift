//
//  Request.swift
//  FishApp
//
//  Created by Luis Ezcurdia on 23/07/22.
//

import Foundation

struct Request {
    enum ContentMode {
        case json

        func accept() -> String {
            switch self {
            case .json:
                return "application/json"
            }
        }

        func contentType() -> String {
            switch self {
            case .json:
                return "application/json"
            }
        }
    }
    private let urlComponents: URLComponents
    public var scheme: String = "https"
    public var method: String = "get"
    public var path: String = "/"
    public var body: Data?
    public var queryItems: [String: String]?
    public var headers: [String: String]?
    public var contentMode: ContentMode = .json

    init(baseUrl: String) {
        self.urlComponents = URLComponents(string: baseUrl)!
    }

    var urlRequest: URLRequest? {
        get {
            return buildUrlRequest()
        }
    }

    func buildUrlRequest() -> URLRequest? {
        guard let url = buildUrl() else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.httpBody = body
        req.addValue(contentMode.accept(), forHTTPHeaderField: "Accept")
        req.addValue(contentMode.contentType(), forHTTPHeaderField: "Content-Type")
        if let headers = self.headers {
            for (key, value) in headers {
                req.addValue(value, forHTTPHeaderField: key)
            }
        }
        return req
    }

    private func buildUrl() -> URL? {
        var comps = self.urlComponents
        comps.scheme = scheme
        comps.path = path
        if let items = queryItems {
            var queryItems: [URLQueryItem] = []
            for (key, value) in items {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            comps.queryItems = queryItems
        }
        return comps.url
    }
}

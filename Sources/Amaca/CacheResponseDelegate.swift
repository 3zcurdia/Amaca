//
//  File.swift
//  
//
//  Created by Luis Ezcurdia on 20/08/22.
//

import Foundation

public protocol CacheResponseDelegate {
    func willMakeRequest(urlRequest: URLRequest)
    func fetchCachedRequest(urlRequest: URLRequest) -> Data?
    func didFinishRequestSuccessful(data: Data?)
    func didFinishRequestUnsuccessful(urlRequest: URLRequest, data: Data?)
}

//
//  URLRequestExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import Foundation

enum HTTPMethod: String {
    case GET, HEAD, POST, PUT
}

extension URLRequest {
    /// Creates an instance with the specified `url`, `method`, and `headers`.
    ///
    /// - Parameters:
    ///   - url:     The `URLConvertible` value.
    ///   - method:  The `HTTPMethod`.
    ///   - headers: The `HTTPHeaders`, `nil` by default.
    /// - Throws:    Any error thrown while converting the `URLConvertible` to a `URL`.
    init(url: URL, method: HTTPMethod, headers: [String: String] = [:]) {

        self.init(url: url)

        httpMethod = method.rawValue
        allHTTPHeaderFields = headers
    }
}

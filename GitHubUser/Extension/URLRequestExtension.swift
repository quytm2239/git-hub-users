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
    init(url: URL, method: HTTPMethod, headers: [String: String] = [:]) {

        self.init(url: url)

        httpMethod = method.rawValue
        allHTTPHeaderFields = headers
    }
}

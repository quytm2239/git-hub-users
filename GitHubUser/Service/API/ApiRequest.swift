//
//  ApiRequest.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

/// Rest API methods (GET/PUT/POST/DELETE)
public enum ApiMethod: String {
    case get = "GET", put = "PUT", post = "POST", delete = "DELETE"
}

/// Rest API protocol
protocol ApiRequest {
    /// Default is nil and we will call Viivio endpoint, override it when call external endpoint
    var externalUrl: String? { get }
    var method: ApiMethod { get }
    var path: String { get }
    var parameters: [String : String] { get }
    var body: [String: Any] { get }
    
    func headerForRequest() -> [String: String]
}

extension ApiRequest {
    func request(with baseURL: URL) -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            fatalError("Unable to create URL components")
        }
        
        components.queryItems = parameters.map {
            URLQueryItem(name: String($0), value: String($1))
        }
        
        guard let url = components.url else {
            fatalError("Could not get url")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if method == .post || method == .put {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        request.allHTTPHeaderFields = headerForRequest()
        request.timeoutInterval = 10
        return request
    }
    
    func headerForRequest() -> [String:String] {
        var headers = [String:String]()
        headers["Content-Type"] = "application/json; charset=utf-8"
        headers["time-zone"] = TimeZone.current.identifier
        // headers["Authorization"] = Please input your GitHub Personal Access Token here. From Developer Setting menu, we can use github public api as Guest but it will be limited

        return headers
    }
}

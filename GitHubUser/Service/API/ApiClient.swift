//
//  ApiClient.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import Foundation
import Combine

let baseUrl = "https://api.github.com"

struct ApiClient {
    private static let baseURL = URL(string: baseUrl)!
    private static let AUTH_ERROR_LIMIT = 7
    private static var authErrorCount = 0
    
    private static let retryQueue = DispatchQueue.init(label: "API_CLIENT_RETRY_QUEUE")
    
    static let maxExponentialBackOff: TimeInterval = 32
    static func getExponentialWaitingTime(retry: Int) -> TimeInterval {
        return pow(2, Double(retry)) + (Double.random(in: 0...1000) / 1000)
    }
    
    // MARK: - ApiClient
    // retry = 0 means new request, not failed yet
    // retry = nil means no retry for this one, avoid duplication
    static func execute<T: Codable>(apiRequest: ApiRequest, retry: Int? = nil, completionHandler: @escaping (Result<T, CommonError>) -> Void) {
        
        let retryBlock: (Int) -> Void = { newRetry in
            ApiClient.execute(apiRequest: apiRequest, retry: newRetry, completionHandler: completionHandler)
        }
        
        var restUrl = ApiClient.baseURL
        if let urlStr = apiRequest.externalUrl,
           let url = URL(string: urlStr) {
            restUrl = url
        }

        let request = apiRequest.request(with: restUrl)
//        let session = URLSession(configuration: URLSessionConfiguration.default)
        
//        let headerJson = request.allHTTPHeaderFields?.json ?? [String:String]().json
//        let bodyJson = apiRequest.body.json
//        let paramsJson = apiRequest.parameters.json
        // The default is already Serial queue here.
        URLSession.shared.delegateQueue.maxConcurrentOperationCount = 1
                
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let e = error {
                
                // Exponential backoff retrier
                if needRetry(retry: retry, retryBlock: retryBlock) { return }
                
                if (e as NSError).code == NSURLErrorNotConnectedToInternet {
                    completionHandler(.failure(CommonError.noInternetAccess))
                } else {
                    completionHandler(.failure(CommonError.custom(message: e.localizedDescription)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                // Exponential backoff retrier
                if needRetry(retry: retry, retryBlock: retryBlock) { return }
                
                completionHandler(.failure(CommonError.unknow))
                return
            }
            
            if httpResponse.statusCode == -1001  {
                
                // Exponential backoff retrier
                if needRetry(retry: retry, retryBlock: retryBlock) { return }
                completionHandler(.failure(CommonError.requestTimeOut))

            } else if httpResponse.statusCode >= 400 {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {

                    completionHandler(.failure(CommonError.unAuthorized))
                    return
                }
                do {
                    let dict = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String : Any]
                    let response = try JSONDecoder().decode(ErrorResponse.self, from: data ?? Data())
                    let error = CommonError.serverError(message: response)
                    
                    completionHandler(.failure(error))

                } catch let error {
                    let dict = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String : Any]
                    completionHandler(.failure(.custom(message: error.localizedDescription)))

                }
            } else {
                do {
                    let dict = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String : Any]
                    let response = try JSONDecoder().decode(T.self, from: data ?? Data())
                    completionHandler(.success(response))

                } catch let error {
                    let dict = try? JSONSerialization.jsonObject(with: data ?? Data(), options: []) as? [String : Any]
                    completionHandler(.failure(.invalidJSON(error)))
                }
            }
        }
        dataTask.resume()
    }
    
    private static func needRetry(retry: Int?, retryBlock: @escaping (Int) -> Void) -> Bool {
        let needRetry = retry != nil
        if needRetry {
            let retryDelay = ApiClient.getExponentialWaitingTime(retry: retry!)
            if retryDelay < ApiClient.maxExponentialBackOff {
                Logger.d("API_CLIENT", "Retry [\(retry!)] after delay [\(retryDelay)]", #fileID, #line)
                retryQueue.asyncAfter(deadline: DispatchTime.now() + retryDelay) {
                    retryBlock(retry! + 1)
                }
                return true
            }
        }
        return false
    }
}

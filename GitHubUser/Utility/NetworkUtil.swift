//
//  NetworkUtil.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import Foundation
import Combine

class NetworkUtil {
    
    static let KeyNetworkStatus = "KeyNetworkStatus"
    
    static let current = NetworkUtil()
    private init() {}
    
    private var currentConnectionStatus = true
    private var lastConnectionRequest: Date?
    
    static var connectionStatus: Bool {
        return current.currentConnectionStatus
    }
    
    private var _onConnectionChange = PassthroughSubject<Bool, Never>()
    static var onConnectionChange: PassthroughSubject<Bool, Never> {
        return current._onConnectionChange
    }
    
    private var _isDisconnectedBefore = false
    static func isDisconnectedBefore() -> Bool {
        let isDisconnectedBefore = current._isDisconnectedBefore
        current._isDisconnectedBefore = !current.currentConnectionStatus
        return isDisconnectedBefore
    }
    static func checkConnect(_ completion: @escaping (Bool) -> Void) {
        
        if let last = current.lastConnectionRequest, abs(last.timeIntervalSinceNow) <= 3 {
            completion(current.currentConnectionStatus)
            return
        }
        
        guard let url = URL(string: "https://www.google.com/") else {
            current._onConnectionChange.send(false)
            return completion(false)
        }
        
        var urlRequest = URLRequest(url: url, method: .HEAD)
        urlRequest.timeoutInterval = 2
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, err in
            let statusCode = ((response as? HTTPURLResponse)?.statusCode ?? 200)
            current.currentConnectionStatus = statusCode == 200 && err == nil
            if !current.currentConnectionStatus {
                current._isDisconnectedBefore = true
            }
            current.lastConnectionRequest = Date()
            current._onConnectionChange.send(current.currentConnectionStatus)
            switchToMain {
                completion(current.currentConnectionStatus)
            }
        }.resume()
    }
}

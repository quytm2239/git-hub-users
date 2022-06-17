//
//  ErrorDefinition.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

enum CommonError: Error {
    /// The request timed out
    case requestTimeOut
    
    case noInternetAccess
    
    /// Server Error
    case serverError(message: ErrorResponse)
    
    /// Unknow error
    case unknow
    
    /// Parse json fail
    case invalidJSON(Swift.Error)
    
    case unAuthorized
    
    case custom(message: String)
}

extension CommonError: LocalizedError {
    private var tn: String {
        return "CommonError"
    }
    
    public var errorDescription: String? {
        switch self {
        case .requestTimeOut:
            return "Request timedout!!!"
        case .serverError(let message):
            return message.errorMessage
        case .unknow:
            return "Unknown error!!!"
        case .custom(let message):
            return message
        case .noInternetAccess:
            return "No internet access!!!"
        case .invalidJSON(let err):
            return err.localizedDescription
        case .unAuthorized:
            return "Request unAuthorized!!!"
        }
    }
}

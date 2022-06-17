//
//  CommonEntity.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

struct GenericResponse<T : Codable>: Codable {
    
    let success: Bool
    let messageCode: Int
    let message: String?
    let data: T?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case messageCode = "code"
        case message
        case data
    }
    
    internal init(success: Bool = true, messageCode: Int = 200, message: String? = nil, data: T? = nil) {
        self.success = success
        self.messageCode = messageCode
        self.message = message
        self.data = data
    }
    
    static func buildEmpty() -> GenericResponse<T> {
        return .init(success: true, messageCode: 200, message: nil, data: nil)
    }
    
    static func build(data: T?) -> GenericResponse<T> {
        return .init(success: true, messageCode: 200, message: nil, data: data)
    }
}

struct EmptyResponse: Codable { }


struct CommonResponse: Codable {
    let success: Bool
    let messageCode: Int
    let message: String?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case messageCode = "code"
        case message
    }
}

struct ErrorResponse: Codable {
    let success: Bool
    let errorCode: String
    let errorMessage: String
    
    private enum CodingKeys: String, CodingKey {
        case success
        case errorCode = "code"
        case errorMessage = "message"
    }
}

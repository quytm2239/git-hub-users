//
//  Logger.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import Foundation

enum LoggerType: String {
    case debug = "DEBUG", info = "INFO",
         error = "ERROR", warning = "WARNING"
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "💡"
        case .error: return "🚫"
        case .warning: return "⚠️"
        }
    }
}

class Logger {
    /**
     Write log about [DEBUG]
     * file = #fileID
     * line = #line
     */
    static func d(_ tag: String, _ message: String, _ file: String, _ line: Int) {
        log(LoggerType.debug, tag, message, file, line)
    }
    /**
     Write log about [INFO]
     * file = #fileID
     * line = #line
     */
    static func i(_ tag: String, _ message: String, _ file: String, _ line: Int) {
        log(LoggerType.info, tag, message, file, line)
    }
    /**
     Write log about [ERROR]
     * file = #fileID
     * line = #line
     */
    static func error(_ tag: String, _ message: String, _ file: String, _ line: Int) {
        log(LoggerType.error, tag, message, file, line)
    }

    /**
     Write log about [WARNING]
     * file = #fileID
     * line = #line
     */
    static func warning(_ tag: String, _ message: String, _ file: String, _ line: Int) {
        log(LoggerType.warning, tag, message, file, line)
    }

    private static func log(_ type: LoggerType = .debug, _ tag: String, _ message: String, _ file: String, _ line: Int) {
        #if DEBUG
        print("\(Date()): \(file):\(line) [\(type.emoji)][\(tag)]: \"\(message)\"")
        #endif
    }
}


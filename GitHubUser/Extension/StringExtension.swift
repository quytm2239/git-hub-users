//
//  StringExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import Foundation

extension String {
    func substring(_ from: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: from)
        let newStr = String(self.suffix(from: index)) // Swift 4
        return newStr
    }

    func substringTo(_ endIndex: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: endIndex)
        let mySubstring = self.prefix(upTo: index) //
        return String(mySubstring)
    }
}

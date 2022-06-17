//
//  DictionaryExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    
    func jsonPresentation() {
        print(json)
    }
}

extension IndexPath {
    func isSame(_ another: IndexPath) -> Bool {
        return another.section == self.section
        && (another.row == self.row || another.item == self.item)
    }
}

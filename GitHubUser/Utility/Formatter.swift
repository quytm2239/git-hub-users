//
//  Formatter.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import Foundation

class Formatter {
    
    static let current = Formatter()
    private init() {}
    
    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .none
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    static func formatNumber(_ value: Double, maxFrac: Int = 3) -> String {
        return current.numberFormatter.string(from: value as NSNumber)!
    }
}

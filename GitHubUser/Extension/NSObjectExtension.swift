//
//  NSObjectExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

extension NSObject{
    
    static var typeName: String {
        return String(describing: self)
    }
    var objectName: String {
        return String(describing: type(of: self))
    }
    
    static func getClassName()->String
    {
        let className = "\(self)"
        return className
    }
    
    func getClassName()->String{
        
        let className = "\(self.classForCoder)"
        
        let objStrings = className.components(separatedBy: ".")
        
        if objStrings.count > 1
        {
            return objStrings[0]
        }
        return className
    }
    
    static func cancel(target: Any, selector: Selector, object: Any? = nil) {
        NSObject.cancelPreviousPerformRequests(withTarget: target, selector: selector, object: nil)
    }
}

func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType)
    -> ValueType {
        if let associated = objc_getAssociatedObject(base, key)
            as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject(base, key, associated,
                                 .OBJC_ASSOCIATION_RETAIN)
        return associated
}
func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType) {
    objc_setAssociatedObject(base, key, value,
                             .OBJC_ASSOCIATION_RETAIN)
}

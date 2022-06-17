//
//  NotificationCenterExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import Foundation

extension NotificationCenter {
    
    class func add(_ observer:AnyObject, selector:Selector!, name:String, object:AnyObject?){
        NotificationCenter.default.addObserver(observer, selector: selector, name: NSNotification.Name(rawValue: name), object: object)
    }
    
    class func remove(_ observer:AnyObject, name:String) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: name), object: nil)
    }
    
    class func post(_ name:String, object:AnyObject?){
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: name), object: object)
    }
    
    class func remove(_ observer:AnyObject) {
        NotificationCenter.default.removeObserver(observer)
    }
}

//
//  Macros.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import Foundation

func delayOnMain(_ time: TimeInterval, handler: @escaping () -> Void) {
    if time == 0 {
        switchToMain(handler: handler)
        return
    }
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time, execute: handler)
}

func switchToMain(handler: @escaping () -> Void) {
    if Thread.isMainThread {
        handler()
        return
    }
    DispatchQueue.main.async(execute: handler)
}

func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}

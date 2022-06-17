//
//  UIInputExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 17/06/2022.
//

import UIKit

extension UITextView {
    
    func setupDoneDismiss() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(title: "DONE",
                                            style: .plain, target: self, action: #selector(self.dismissKeyboard))
        doneBarButton.tintColor = UIColor.blue
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        self.inputAccessoryView = keyboardToolbar
    }
    
    @objc func dismissKeyboard() {
        if self.isFirstResponder {
            self.resignFirstResponder()
        }
    }
}

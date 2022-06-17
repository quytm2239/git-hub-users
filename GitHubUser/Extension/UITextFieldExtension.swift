//
//  UITextFieldExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import UIKit

class BaseTextField: UITextField {
    private var debounceHandler: ((String) -> Void)?
    private var debounceTime: TimeInterval = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(handlerEdittingChanged(_:)), for: .editingChanged)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addTarget(self, action: #selector(handlerEdittingChanged(_:)), for: .editingChanged)
    }
    
    // MARK: Debounce setup
    public func debounce(_ time: TimeInterval = 0.5, _ handler: @escaping (String) -> Void) {
        self.debounceTime = time
        self.debounceHandler = handler
    }
    
    @objc private func handlerEdittingChanged(_ sender: UITextField) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(triggerDebounce), object: nil)
        self.perform(#selector(triggerDebounce), with: nil, afterDelay: debounceTime)
    }
    
    @objc private func triggerDebounce() {
        debounceHandler?(self.text ?? "")
    }

    deinit {
        self.removeTarget(self, action: #selector(handlerEdittingChanged(_:)), for: .editingChanged)
    }
}

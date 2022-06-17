//
//  CustomLoading.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 15/06/2022.
//

import UIKit

class CustomLoading: UIView {

    private unowned var currentWindow: UIWindow!

    private static let shared = CustomLoading(frame: CGRect.zero)
    private let loading = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    private let text = UILabel(frame: .zero)
    private var loadingCount = 0
    private let viewContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        currentWindow = NavigationCenter.currentWindow
        backgroundColor = .clear // UIColor.black.alpha(0.3)
        viewContainer.translatesAutoresizingMaskIntoConstraints = false
        viewContainer.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        viewContainer.layer.cornerRadius = 15
        viewContainer.layer.cornerCurve = .continuous
        
        addSubview(viewContainer)
        let constraintsOfBackground = [
            viewContainer.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            viewContainer.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 10),
            viewContainer.widthAnchor.constraint(equalToConstant: 140),
            viewContainer.heightAnchor.constraint(equalToConstant: 100),
        ]
        NSLayoutConstraint.activate(constraintsOfBackground)

        addSubview(loading)
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.color = .white
        let constraintsOfLoading = [
            loading.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            loading.widthAnchor.constraint(equalToConstant: 50),
            loading.heightAnchor.constraint(equalToConstant: 50),
        ]
        NSLayoutConstraint.activate(constraintsOfLoading)
        
        addSubview(text)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.font = UIFont.boldSystemFont(ofSize: 14)
        text.textColor = .white
        
        let constraintsOfText = [
            text.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            text.topAnchor.constraint(equalTo: loading.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraintsOfText)
    }

    private func attach() {
        switchToMain {
            if self.superview != nil { return }
            self.text.text = "Loading..."
            self.currentWindow.addSubview(self)
            self.frame = self.currentWindow.bounds
            self.loading.startAnimating()
        }
    }

    private func detach() {
        switchToMain {
            if self.superview == nil { return }
            self.loading.stopAnimating()
            self.removeFromSuperview()
        }
    }

    class func show(_ dismissAfter: TimeInterval = 0) {
        switchToMain {
            shared.isUserInteractionEnabled = true
            shared.loadingCount += 1
            if dismissAfter > 0 {
                shared.attach()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + dismissAfter) {
                    shared.detach()
                }
            } else {
                shared.attach()
            }
        }
    }
    
    class func showNonBlock(_ dismissAfter: TimeInterval = 0) {
        switchToMain {
            shared.isUserInteractionEnabled = false
            shared.loadingCount += 1
            if dismissAfter > 0 {
                shared.attach()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + dismissAfter) {
                    shared.detach()
                }
            } else {
                shared.attach()
            }
        }
    }

    class func hide() {
        shared.loadingCount -= 1
        if shared.loadingCount <= 0 { shared.loadingCount = 0 }
        if shared.loadingCount == 0 { shared.detach() }
    }
    
    class func forceHide() {
        shared.loadingCount = 0
        shared.detach()
    }
}

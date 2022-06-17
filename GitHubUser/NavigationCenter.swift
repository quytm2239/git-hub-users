//
//  NavigationCenter.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 14/06/2022.
//

import UIKit
import Combine

class NavigationCenter: NSObject {
    static let current = NavigationCenter()
    private var cancellable = Set<AnyCancellable>()
    private override init() {
        super.init()
        NetworkUtil.onConnectionChange
            .receive(on: DispatchQueue.main)
            .sink { _ in
                NavigationCenter.showConnectionStatus()
            }.store(in: &cancellable)
    }
    
    fileprivate var _window: UIWindow!
    static var currentWindow: UIWindow {
        get { return current._window }
//        set { current._window = newValue }
    }
    
    fileprivate var _rootNav: UINavigationController!
    static var rootNav: UINavigationController {
        get { return current._rootNav }
//        set { current._rootNav = newValue }
    }
    
    static func moveToMain() {
        
    }
    
    static func moveToSub() {
        
    }
    
    static func showLoading() {
//        self.rootNav.viewControllers[0].view.alpha = 0.2
    }
    
    static func showErrorView() {
    }
    
    private lazy var viewErrorConnection: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        view.isUserInteractionEnabled = false

        let imageView = UIImageView(image: UIImage(named: "ic_no_wifi_colored"))
        view.addSubview(imageView)
        imageView.center = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        imageView.tintColor = .red
        
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.backgroundColor = .white
        view.dropCommonShadow()
        
        return view
    }()
    
    static func showConnectionStatus() {
        if NetworkUtil.connectionStatus {
            current.viewErrorConnection.removeFromSuperview()
        } else {
            current._window.addSubview(current.viewErrorConnection)
            var x = currentWindow.bounds.width / 2
            x += (x - current.viewErrorConnection.frame.width / 2 - 20)
            let y = currentWindow.bounds.height - currentWindow.safeAreaInsets.bottom - 20
            current.viewErrorConnection.center = CGPoint.init(x: x, y: y)
            current._window.bringSubviewToFront(current.viewErrorConnection)
        }
    }
    
    static func showToast(error: String, success: Bool) {
        showToast(error: error, bgColor: success ? .systemGreen : .systemRed)
    }
    
    static func showToast(error: String, bgColor: UIColor = .systemRed) {
        let view = UIView()
        currentWindow.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let constraintForToast = [
            view.leadingAnchor.constraint(equalTo: currentWindow.leadingAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: currentWindow.trailingAnchor, constant: -20),
            view.bottomAnchor.constraint(equalTo: currentWindow.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ]
        NSLayoutConstraint.activate(constraintForToast)

        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.text = error
        label.textColor = .white
        view.addSubview(label)
        
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        let constraintForText = [
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 10)
        ]
        NSLayoutConstraint.activate(constraintForText)
        
        view.layoutIfNeeded()
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 10
        view.dropCommonShadow()
        view.backgroundColor = bgColor
        
        view.transform = .init(translationX: 0, y: 500)
        UIView.animate(withDuration: 0.5) {
            view.transform = .identity
            view.alpha = 1
        }

        delayOnMain(3) {
            view.removeFromSuperview()
        }
    }
}

extension NavigationCenter {
    
    private func initView() -> UIViewController {
        return ListUserScreen.build()
    }
    
    static func startNavigation() {
        current._rootNav = UINavigationController(rootViewController: current.initView())
        current._window = UIWindow(frame: UIScreen.main.bounds)
        current._window.rootViewController = rootNav
        current._window.makeKeyAndVisible()
    }
    
    static func openUserProfile(user: RUserItem) {
        let module = UserProfileScreen.build(user: user)
        self.rootNav.pushViewController(module, animated: true)
    }
}

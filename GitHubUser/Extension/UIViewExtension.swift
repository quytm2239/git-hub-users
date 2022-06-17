//
//  UIViewExtension.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 16/06/2022.
//

import UIKit

extension UIView {
    func startHeartbeat(needRemove: Bool = true) {
        if let _ = self.layer.animation(forKey: "hearbeatAnimation") {
            return
        }
        
        let pulse1 = CABasicAnimation(keyPath: "transform.scale")
        pulse1.duration = 0.5
        pulse1.fromValue = 1.0
        pulse1.toValue = 1.10
        pulse1.autoreverses = true
        pulse1.repeatCount = .infinity
        pulse1.isRemovedOnCompletion = true
        pulse1.setValue("hearbeatAnimation", forKey: "animationID")
        self.layer.add(pulse1, forKey: "hearbeatAnimation")
    }

    func endHeartbeat() {
        self.layer.removeAnimation(forKey: "hearbeatAnimation")
    }
    
    func dropCommonShadow() {
        self.dropShadow(color: UIColor.black.withAlphaComponent(0.1), offSet: CGSize.zero, radius: 6, isRouned: true)
    }
    
    func dropShadow(color: UIColor, opacity: Float = 1, offSet: CGSize, radius: CGFloat, scale: Bool = true, isRouned: Bool = false) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        if isRouned {
            layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: layer.cornerRadius).cgPath
        } else {
            layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        }
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func makeSketelon(corner: CGFloat = 0) {
        let grayView = UIView()
        grayView.backgroundColor = .systemGray5
        grayView.translatesAutoresizingMaskIntoConstraints = false
        grayView.tag = 100000
        self.addSubview(grayView)
        let constraint = [
            grayView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            grayView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            grayView.widthAnchor.constraint(equalTo: self.widthAnchor),
            grayView.heightAnchor.constraint(equalTo: self.heightAnchor),
        ]
        grayView.layer.cornerRadius = corner
        NSLayoutConstraint.activate(constraint)
        grayView.layoutIfNeeded()
    }
    
    func hideSkeleton() {
        self.viewWithTag(100000)?.removeFromSuperview()
    }
}

// MARK: - For handler onlick
class ViewClickListener: NSObject, CAAnimationDelegate {
    fileprivate weak var view: UIView?
    fileprivate var handler: Closure_View_Void?
    fileprivate var handlerAnimation: Closure_View_Void?

    var finishSetup = false

    @objc private func trigger() {
        if handlerAnimation != nil { self.view?.isUserInteractionEnabled = false }
        handler?(view)
    }
    
    func clearHandler() {
        view?.gestureRecognizers?.forEach({ view?.removeGestureRecognizer($0) })
        handler = nil
        handlerAnimation = nil
    }

    fileprivate func set(_ target: UIView, _ handler: @escaping Closure_View_Void) {
        self.view = target
        self.handler = handler
        if !finishSetup {
            if self.view is UIButton {
                (self.view as! UIButton).removeTarget(self, action: #selector(trigger), for: .touchUpInside)
                (self.view as! UIButton).addTarget(self, action: #selector(trigger), for: .touchUpInside)
            } else {
                self.view?.gestureRecognizers?.forEach({ self.view?.removeGestureRecognizer($0) })
                let ges = UITapGestureRecognizer(target: self, action: #selector(trigger))
                ges.cancelsTouchesInView = true
                self.view?.addGestureRecognizer(ges)
            }
            finishSetup = true
        }
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let animationID = anim.value(forKey: "animationID") as? String, animationID == "touchAnimation" {
            handlerAnimation?(view)
            if handlerAnimation != nil { self.view?.isUserInteractionEnabled = true }
        }
    }
}

private var listenerKey: UInt8 = 0 // We still need this boilerplate
extension UIView {
    private var listener: ViewClickListener { // listener is *effectively* a stored property
        get {
            return associatedObject(base: self, key: &listenerKey) { return ViewClickListener() } // Set the initial value of the var
        }
        set { associateObject(base: self, key: &listenerKey, value: newValue) }
    }
    
    func triggerOnClick() {
        listener.handler?(self)
    }
    
    func clearOnClick() {
        listener.clearHandler()
    }

    @objc func onClick(_ handler: @escaping Closure_View_Void) {
        self.isUserInteractionEnabled = true
        listener.set(self, handler)
    }

    @objc func onMotionClick(_ handler: @escaping Closure_View_Void) {
        self.isUserInteractionEnabled = true
        listener.set(self, { [weak self] _ in self?.startTouchAnimation(UIView.defaultTouchAnimationDuration, delegate: self?.listener) })
        listener.handlerAnimation = handler
    }
}

// MARK: - Touch animation
extension UIView: CAAnimationDelegate {
    static var defaultTouchAnimationDuration = TimeInterval(0.4)

    @objc func startTouchAnimation(_ duration: TimeInterval = UIView.defaultTouchAnimationDuration, delegate: CAAnimationDelegate? = nil) {
        self.layer.removeAllAnimations()

        let pulse1 = CABasicAnimation(keyPath: "transform.scale")
        pulse1.duration = duration / 2
        pulse1.fromValue = 1.0
        pulse1.toValue = 1.05
        pulse1.autoreverses = true
        pulse1.repeatCount = 1
        pulse1.isRemovedOnCompletion = true
        pulse1.delegate = delegate
        pulse1.setValue("touchAnimation", forKey: "animationID")

        self.layer.add(pulse1, forKey: "pulse")
    }

    @objc func endTouchAnimation() {
        self.layer.removeAllAnimations()
    }
}

//
//  SmoothCornerView.swift
//  GitHubUser
//
//  Created by Tran Manh Quy on 17/06/2022.
//

import UIKit

class SmoothCornerView: UIView {
    
    @IBInspectable var hexColor: String = "#FFFFFF" {
        didSet {
            self.backgroundColor = UIColor(hex: hexColor)
        }
    }
    
    @IBInspectable var isRounded: Bool = false {
        didSet {
            layer.cornerRadius = isRounded ? intrinsicContentSize.height / 2 : corner
            clipsToBounds = isRounded
        }
    }
    
    @IBInspectable var needClipToBound: Bool = true {
        didSet {
            clipsToBounds = needClipToBound
        }
    }

    @IBInspectable var corner: CGFloat = 0 {
        didSet {
            layer.cornerRadius = corner
            clipsToBounds = needClipToBound
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.lightGray {
        didSet {
            self.layer.borderWidth = hasBorder ? 1 : 0
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var hasBorder: Bool = false {
        didSet {
            self.layer.borderWidth = hasBorder ? 1 : 0
            self.layer.borderColor = UIColor.systemGray5.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = isRounded ? bounds.height / 2 : corner
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerCurve = .continuous
        layer.cornerRadius = corner
        clipsToBounds = needClipToBound
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.cornerCurve = .continuous
        layer.cornerRadius = corner
        clipsToBounds = needClipToBound
    }
}

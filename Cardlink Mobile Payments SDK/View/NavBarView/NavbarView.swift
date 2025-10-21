//
//  NavbarView.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 18/9/22.
//  Copyright © 2022 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

@IBDesignable class NavbarView: IBPreviewableView {
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        leftButton?.isHidden = !showLeftButton
        titleLabel.text = title
        rightButton?.isHidden = !showRightButton
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) { } else {
            topConstraint.constant += 20
        }
    }
    
    @IBInspectable var title: String = "Title" {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBInspectable var showLeftButton: Bool = true {
        didSet {
            leftButton?.isHidden = !showLeftButton
            #if TARGET_INTERFACE_BUILDER
            prepareForInterfaceBuilder()
            #endif
        }
    }
    
    @IBInspectable var showRightButton: Bool = true {
        didSet {
            rightButton?.isHidden = !showRightButton
            #if TARGET_INTERFACE_BUILDER
            prepareForInterfaceBuilder()
            #endif
        }
    }
}

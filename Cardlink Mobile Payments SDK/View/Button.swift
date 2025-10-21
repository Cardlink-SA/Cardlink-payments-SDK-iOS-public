//
//  Button.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 2/12/22.
//

import UIKit

class Button: UIButton {
    private var regularBgColor: UIColor? = nil
    
    override var backgroundColor: UIColor? {
        didSet {
            if isHighlighted {
                return
            }
            
            regularBgColor = backgroundColor
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            titleLabel?.textColor = titleColor(for: .normal)
            tintColor = titleColor(for: .normal)
            titleLabel?.tintColor = titleColor(for: .normal)
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = self.isHighlighted
                ? self.regularBgColor?.withAlphaComponent(0.8)
                : self.regularBgColor
            }
        }
    }
}

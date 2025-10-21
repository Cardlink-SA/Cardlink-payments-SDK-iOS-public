//
//  Button2.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/3/23.
//

import UIKit

class Button2: UIButton {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.backgroundColor = self.isHighlighted ? UIColor(white: 0, alpha: 0.05) : .white
            }
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let _ = window else { return }
        
        layer.masksToBounds = false
        layer.cornerRadius = 15
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 2
    }
}

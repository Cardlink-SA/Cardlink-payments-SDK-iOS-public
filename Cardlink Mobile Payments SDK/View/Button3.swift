//
//  Button3.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/3/23.
//

import UIKit

class Button3: UIButton {
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.backgroundColor = self.isHighlighted ? UIColor(white: 0, alpha: 0.05) : .white
            }
        }
    }
}

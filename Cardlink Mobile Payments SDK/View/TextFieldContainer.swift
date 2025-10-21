//
//  TextFieldContainer.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

import UIKit

class TextFieldContainer: UIView {
    var isValid: Bool = true {
        didSet {
            if isValid == oldValue {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
        }
    }
}

private extension TextFieldContainer {
    func updateUI() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.layer.borderWidth = self.isValid ? 0 : 2
            self.layer.borderColor = self.isValid
            ? UIColor.clear.cgColor
            : UIColor.red.cgColor
        })
    }
}

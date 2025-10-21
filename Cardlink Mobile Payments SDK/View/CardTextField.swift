//
//  CardTextField.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 23/11/22.
//

import UIKit

class CardTextField: UITextField {
    override func drawPlaceholder(in rect: CGRect) {
        guard let placeholder = placeholder as? NSString else {
            return
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Roboto-Regular", size: 13)!,
            .foregroundColor: UIColor(hex: "#ACB1C0")!
        ]

        let textSize = placeholder.size(withAttributes: attributes)
        let hDif = max(0, rect.size.height - textSize.height)
        var rect = rect
        rect.origin.y += ceil(hDif / 2)
        placeholder.draw(in: rect, withAttributes: attributes)
    }
}

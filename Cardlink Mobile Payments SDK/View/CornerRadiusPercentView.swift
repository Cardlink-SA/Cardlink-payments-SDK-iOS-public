//
//  CornerRadiusPercentView.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 26/11/22.
//

import UIKit

class CornerRadiusPercentView: UIView {
    @IBInspectable var cornerPercentHeight: CGFloat = 0.18
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height * cornerPercentHeight
        updateShadow()
    }
    
    private lazy var shadowLayer: CAShapeLayer? = nil
    
    var showShadow: Bool = false {
        didSet {
            updateShadow()
        }
    }
}

private extension CornerRadiusPercentView {
    func updateShadow() {
        if !showShadow {
            return
        }
        
        layer.shadowPath = UIBezierPath(
            roundedRect: layer.bounds.insetBy(dx: layer.cornerRadius / 4, dy: 0),
            cornerRadius: layer.cornerRadius
        ).cgPath
        layer.shadowOpacity = 1
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowRadius = bounds.size.height * 0.03
        layer.shadowOffset = CGSize(width: 0, height: bounds.size.height * 0.02)
    }
}

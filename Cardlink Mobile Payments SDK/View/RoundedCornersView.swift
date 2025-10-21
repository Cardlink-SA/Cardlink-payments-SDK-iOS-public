//
//  RoundedCornersView.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/3/23.
//

import UIKit

class RoundedCornersView: UIView {
    var radius = 40.0 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var roundedCorners: UIRectCorner = [.allCorners] {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(corners: roundedCorners, radius: radius)
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

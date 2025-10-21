//
//  UIView+.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 18/9/22.
//  Copyright © 2022 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

extension UIView {
    static var AnimationDuration: TimeInterval = 0.3
    
    static func loadFromNib() -> Self {
        let bundle = Bundle(for: self)
        let name = String(describing: self)
        let selfObject = self.init(frame: .zero)
        let view = bundle.loadNibNamed(
            name,
            owner: selfObject,
            options: nil)?.first as! UIView
        
        view.addToContainer(selfObject)
        selfObject.awakeFromNib()
        
        return selfObject
    }
    
    func loadFromNib() -> UIView? {
        let thisType = type(of: self)
        let bundle = Bundle(for: thisType)
        let nibName = String(describing: thisType)
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func pinToEdgesOfSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: 0).isActive = true
        leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0).isActive = true
    }
    
    /// Adds to container and makes edges equal to superview
    func addToContainer(_ container: UIView) {
        container.addSubview(self)
        pinToEdgesOfSuperview()
    }
    
    func asImage(scale: CGFloat) -> UIImage {
        if #available(iOS 10.0, *) {
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(self.frame.size, true, scale)
            self.layer.render(in:UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImage(cgImage: image!.cgImage!)
        }
    }
    
    func fadeIn(_ duration: TimeInterval? = nil) {
        fadeIn(duration, completion: nil)
    }
    
    func fadeIn(_ duration: TimeInterval? = nil, completion: ((Bool) -> Swift.Void)? = nil) {
        let animationDuration = duration ?? Self.AnimationDuration
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.alpha = 1
        }, completion: completion)
    }
    
    func fadeOut(_ duration: TimeInterval? = nil) {
        fadeOut(duration, completion: nil)
    }
    
    func fadeOut(_ duration: TimeInterval? = nil, completion: ((Bool) -> Swift.Void)? = nil) {
        let animationDuration = duration ?? Self.AnimationDuration
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.alpha = 0
        }, completion: completion)
    }
}

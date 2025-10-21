//
//  NavbarView.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 18/9/22.
//  Copyright © 2022 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

class IBPreviewableView: UIView {
    override func prepareForInterfaceBuilder() {
        initializeAndAddToHierarchy()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        #if !TARGET_INTERFACE_BUILDER
        initializeAndAddToHierarchy()
        #endif
    }
    
    override class func setValue(_ value: Any?, forKey key: String) {
        #if !TARGET_INTERFACE_BUILDER
        super.setValue(value, forKey: key)
        #endif
    }
    
    override class func setValue(_ value: Any?, forUndefinedKey key: String) {
        #if !TARGET_INTERFACE_BUILDER
        super.setValue(value, forUndefinedKey: key)
        #endif
    }
    
    var designableSelf: UIView? {
        #if TARGET_INTERFACE_BUILDER
        return subviews.first
        #endif
        
        return self
    }
}

private extension IBPreviewableView {
    func initializeAndAddToHierarchy() {
        guard let view = loadFromNib() else { return }
        view.addToContainer(self)
    }
}

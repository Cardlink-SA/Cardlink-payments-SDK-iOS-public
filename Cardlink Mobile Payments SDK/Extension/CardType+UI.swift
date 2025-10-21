//
//  CardType+UI.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

import UIKit

extension CardType {
    func color() -> UIColor {
        switch self {
        case .unknown:
            return UIColor(hex: "#7D858D")!
        case .visa:
            return UIColor(hex: "#FF8900")!
        case .mastercard:
            return UIColor(hex: "#414447")!
        case .amex:
            return UIColor(red:0.17, green: 0.4, blue:0.75, alpha: 1)
        case .diners:
            return UIColor(red: 0.46, green: 0.46, blue: 0.48, alpha: 1)
        case .discover:
            return UIColor(red: 0.85, green: 0.36, blue: 0.15, alpha: 1)
        case .maestro:
            return UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        case .visaElectron:
            return UIColor(red: 0.94, green: 0.56, blue: 0.21, alpha: 1)
        }
    }
    
    func image() -> String {
        if self == .unknown {
            return "empty"
        }
        
        return self.rawValue
    }
    
    func imageSmall() -> String {
        if self == .unknown {
            return "empty"
        }
        
        return "\(self.rawValue)_small"
    }
}

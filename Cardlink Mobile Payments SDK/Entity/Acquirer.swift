//
//  Acquirer.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 20/3/23.
//

import UIKit

enum Acquirer: String, Codable {
    case unknown
    case cardlink
    case nexi
    case worldline
    
    init(from decoder: Decoder) throws {
        self = try Acquirer(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
    
    func smallImage() -> String? {
        switch self {
        case .unknown:
            return nil
        case .cardlink:
            return "ic_cardlink_logo"
        case .nexi:
            return "ic_nexi_logo"
        case .worldline:
            return "ic_worldline_logo"
        }
    }
    
    func color() -> UIColor {
        switch self {
        case .unknown:
            return UIColor.gray
        case .cardlink:
            return UIColor(hex: "#20426D")!
        case .nexi:
            return UIColor(hex: "#20426D")!
        case .worldline:
            return UIColor(hex: "#46BEAA")!
        }
    }
}

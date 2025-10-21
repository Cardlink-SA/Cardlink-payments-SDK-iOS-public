//
//  PaymentMethod.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 8/4/23.
//

enum PaymentMethod: String, Codable {
    case unknown
    case card
    case iris
    case paypal
    
    init(from decoder: Decoder) throws {
        self = try PaymentMethod(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

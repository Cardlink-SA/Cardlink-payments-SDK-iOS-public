//
//  Settings.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 20/3/23.
//

struct Settings: Codable {
    let currency: String?
    let tokenization: Bool?
    let acquirer: Acquirer?
    let installments: Bool?
    let max_installments: Int?
    let installments_variations: [InstallmentsVariation]?
    let accepted_card_types: [CardType]?
    let accepted_payment_methods: [PaymentMethod]?
    let routes: SettingsRoutes?
}

struct SettingsRoutes: Codable {
    let card_payment_request: String?
    let card_payment_success: String?
    let card_payment_failed: String?
    
    let iris_payment_request: String?
    let iris_payment_success: String?
    let iris_payment_failed: String?
    
    let paypal_payment_request: String?
    let paypal_payment_success: String?
    let paypal_payment_failed: String?
}

struct InstallmentsVariation: Codable {
    let amount: Int64?
    let installments: Int?
}

struct SettingsResponse: Codable {
    let settings: Settings?
}

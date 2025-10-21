//
//  Card.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 1/12/22.
//

class Card: Codable {
    var card_type: CardType
    var last4: String
    var expiry_month: Int
    var expiry_year: Int
    
    // Either the token OR a pan+cvv+cardholder_name must be available
    // to be able to make payments with this card.
    var token: String? = nil // ONLY returned by the API
    // Fields not returned by the API
    var pan: String? = nil
    var cvv: String? = nil
    var cardholder_name: String? = nil
    
    init(
        card_type: CardType,
        last4: String,
        expiry_month: Int,
        expiry_year: Int,
        pan: String? = nil,
        cvv: String? = nil,
        cardholder_name: String? = nil
    ) {
        self.card_type = card_type
        self.last4 = last4
        self.expiry_month = expiry_month
        self.expiry_year = expiry_year
        self.token = nil
        self.pan = pan
        self.cvv = cvv
        self.cardholder_name = cardholder_name
    }
    
    init(
        card_type: CardType,
        last4: String,
        expiry_month: Int,
        expiry_year: Int,
        token: String? = nil
    ) {
        self.card_type = card_type
        self.last4 = last4
        self.expiry_month = expiry_month
        self.expiry_year = expiry_year
        self.token = token
        self.pan = nil
        self.cvv = nil
        self.cardholder_name = nil
    }
}

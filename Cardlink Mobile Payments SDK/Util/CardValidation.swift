//
//  CardValidation.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

enum CardType: String, Codable {
    case unknown
    case visa
    case mastercard
    case amex
    case diners
    case discover
    case maestro
    case visaElectron
    
    func name() -> String {
        switch self {
        case .unknown:
            return "-"
        case .visa:
            return "Visa"
        case .mastercard:
            return "Mastercard"
        case .amex:
            return "Amex"
        case .diners:
            return "Diners"
        case .discover:
            return "Discover"
        case .maestro:
            return "Maestro"
        case .visaElectron:
            return "Visa Electon"
        }
    }
    
    func maxCVVDigits() -> Int {
        switch self {
        case .unknown:
            return 4
        case .visa:
            return 3
        case .mastercard:
            return 3
        case .amex:
            return 4
        case .diners:
            return 3
        case .discover:
            return 3
        case .maestro:
            return 3
        case .visaElectron:
            return 3
        }
    }
    
    func minDigits() -> Int {
        switch self {
        case .unknown:
            return 12
        case .visa:
            return 13
        case .mastercard:
            return 16
        case .amex:
            return 15
        case .diners:
            return 14
        case .discover:
            return 16
        case .maestro:
            return 12
        case .visaElectron:
            return 16
        }
    }
    
    func maxDigits() -> Int {
        switch self {
        case .unknown:
            return 19
        case .visa:
            return 16
        case .mastercard:
            return 16
        case .amex:
            return 15
        case .diners:
            return 19
        case .discover:
            return 19
        case .maestro:
            return 19
        case .visaElectron:
            return 16
        }
    }
    
    init(from decoder: Decoder) throws {
        self = try CardType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

class CardValidation {
    static let CVV_MIN_CHARACTERS = 3
//    static let CVV_MAX_CHARACTERS = 4
    
    static let CARDHOLDER_MIN_CHARACTERS = 2
    static let CARDHOLDER_MAX_CHARACTERS = 40
    
    static func isPanValid(_ pan: String, cardType: CardType) -> Bool {
        let panClean = pan.removeNonDigits()
        return panClean.count >= cardType.minDigits() && panClean.count <= cardType.maxDigits()
    }
    
    static func isExpirationValid(_ expiration: String) -> Bool {
        let yyyy = expirationYYYY(expiration)
        let mm = expirationMM(expiration)
        
        let calendar = Calendar.current
        let date = Date()
        guard
            let yyyy = yyyy,
            let mm = mm,
            let cardYear = Int(yyyy),
            let cardMonth = Int(mm)
        else {
            return false
        }
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return year < cardYear || year == cardYear && month <= cardMonth
    }
    
    static func isCardHolderValid(_ cardHolder: String) -> Bool {
        let cardHolderClear = cardHolder.trimWhiteSpace()
        return cardHolderClear.count >= CARDHOLDER_MIN_CHARACTERS && cardHolderClear.count <= CARDHOLDER_MAX_CHARACTERS
    }
    
    static func isCVVValid(_ cvv: String, cardType: CardType) -> Bool {
        let cvvClear = cvv.removeNonDigits()
        return cvvClear.count >= CVV_MIN_CHARACTERS && cvvClear.count <= cardType.maxCVVDigits()
    }
    
    static func expirationYYYY(_ expiration: String) -> String? {
        let characters = expiration.removeNonDigits()
        if characters.count != 4 {
            return nil
        }
        
        let lastTwoDigits = Int(characters.dropFirst(2)) ?? 0
        if lastTwoDigits <= 0 {
            return nil
        }
        
        let year = 2000 + lastTwoDigits
        return String(year)
    }
    
    static func expirationMM(_ expiration: String) -> String? {
        let characters = expiration.removeNonDigits()
        if characters.count != 4 {
            return nil
        }
        
        let firstTwoDigits = Int(characters.dropLast(2)) ?? 0
        if firstTwoDigits < 1 || firstTwoDigits > 12 {
            return nil
        }
        
        let firstTwoDigitsString = firstTwoDigits < 10
        ? "0\(firstTwoDigits)"
        : "\(firstTwoDigits)"
        
        return firstTwoDigitsString
    }
}

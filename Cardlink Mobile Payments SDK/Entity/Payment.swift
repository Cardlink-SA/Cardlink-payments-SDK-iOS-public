//
//  Payment.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

class Payment {
    var amount: UInt
    var description: String
    var TDS2CardHolderName: String
    var TDS2BillAddrCity: String
    var TDS2BillAddrLine1: String
    var TDS2BillAddrPostCode: String
    
    var installments: UInt?
    var shouldStoreCard = false
    
    var cardType: CardType
    
    let currency: String = "978"
    let country: String = "300"
    
    // TODO: Make UI 
    let recurFreq: Int? // Unit type Days
    let recurEnd: String // YYYYMMDD
    
    init(amount: UInt,
         description: String,
         TDS2CardHolderName: String,
         TDS2BillAddrCity: String,
         TDS2BillAddrLine1: String,
         TDS2BillAddrPostCode: String,
         installments: UInt? = nil,
         cardType: CardType,
         shouldStoreCard: Bool,
         recurFreq: Int? = nil,
         recurEnd: String = "") {
        self.amount = amount
        self.description = description
        self.TDS2CardHolderName = TDS2CardHolderName
        self.TDS2BillAddrCity = TDS2BillAddrCity
        self.TDS2BillAddrLine1 = TDS2BillAddrLine1
        self.TDS2BillAddrPostCode = TDS2BillAddrPostCode
        self.installments = installments
        self.shouldStoreCard = shouldStoreCard
        self.cardType = cardType
        self.recurFreq = recurFreq
        self.recurEnd = recurEnd
    }
}

extension Payment {
    func amountString() -> String {
        //        let integer = UInt(amount / 100)
        //        var decimal = String(amount - integer * 100)
        //        if decimal.count < 2 {
        //            decimal = "0" + decimal
        //        }
        //        let separator = Locale.current.decimalSeparator ?? "."
        //        return "\(integer)\(separator)\(decimal)"
        Formatters.formatAmount(amount)
    }
    
    func makeActiveWithCardEncData(_ cardEncData: String, storeCard: Bool) -> ActivePayment {
        ActivePayment(
            cardEncData: cardEncData,
            cardType: cardType,
            amount: amount,
            description: description,
            TDS2CardHolderName: TDS2CardHolderName,
            TDS2BillAddrCity: TDS2BillAddrCity,
            TDS2BillAddrLine1: TDS2BillAddrLine1,
            TDS2BillAddrPostCode: TDS2BillAddrPostCode,
            installments: installments,
            shouldStoreCard: storeCard,
            recurFreq: recurFreq,
            recurEnd: recurEnd
        )
    }
    
    func makeActiveWithCardTokenType(_ cardToken: String, type: CardType) -> ActivePayment {
        ActivePayment(
            cardToken: cardToken,
            cardType: type,
            amount: amount,
            description: description,
            TDS2CardHolderName: TDS2CardHolderName,
            TDS2BillAddrCity: TDS2BillAddrCity,
            TDS2BillAddrLine1: TDS2BillAddrLine1,
            TDS2BillAddrPostCode: TDS2BillAddrPostCode,
            installments: installments,
            shouldStoreCard: shouldStoreCard,
            recurFreq: recurFreq,
            recurEnd: recurEnd
        )
    }
    
    func makeWebPaymentDictionaryFor(_ service: PaymentMethod) -> [String : Codable] {
        switch service {
        case .unknown:
            return [:]
        case .card:
            return [:]
        case .iris, .paypal:
            return [
                "purchAmount": amount,
                "billAddress": TDS2BillAddrLine1,
                "billCity": TDS2BillAddrCity,
                "billZip": TDS2BillAddrPostCode
            ]
        }
    }
}

class ActivePayment: Payment {
    private var paymentType: PaymentType
    
    private enum PaymentType: Codable {
        case viaCardEncData(String)
        case viaToken(String, CardType)
    }
    
    init(
        cardEncData: String,
        cardType: CardType,
        amount: UInt,
        description: String,
        TDS2CardHolderName: String,
        TDS2BillAddrCity: String,
        TDS2BillAddrLine1: String,
        TDS2BillAddrPostCode: String,
        installments: UInt?,
        shouldStoreCard: Bool,
        recurFreq: Int? = nil,
        recurEnd: String = ""
    ) {
        self.paymentType = .viaCardEncData(cardEncData)
        super.init(
            amount: amount,
            description: description,
            TDS2CardHolderName: TDS2CardHolderName,
            TDS2BillAddrCity: TDS2BillAddrCity,
            TDS2BillAddrLine1: TDS2BillAddrLine1,
            TDS2BillAddrPostCode: TDS2BillAddrPostCode,
            installments: installments,
            cardType: cardType,
            shouldStoreCard: shouldStoreCard,
            recurFreq: recurFreq,
            recurEnd: recurEnd
        )
    }
    
    init(
        cardToken: String,
        cardType: CardType,
        amount: UInt,
        description: String,
        TDS2CardHolderName: String,
        TDS2BillAddrCity: String,
        TDS2BillAddrLine1: String,
        TDS2BillAddrPostCode: String,
        installments: UInt?,
        shouldStoreCard: Bool,
        recurFreq: Int? = nil,
        recurEnd: String = ""
    ) {
        self.paymentType = .viaToken(cardToken, cardType)
        super.init(
            amount: amount,
            description: description,
            TDS2CardHolderName: TDS2CardHolderName,
            TDS2BillAddrCity: TDS2BillAddrCity,
            TDS2BillAddrLine1: TDS2BillAddrLine1,
            TDS2BillAddrPostCode: TDS2BillAddrPostCode,
            installments: installments,
            cardType: cardType,
            shouldStoreCard: shouldStoreCard,
            recurFreq: recurFreq,
            recurEnd: recurEnd
        )
    }
    
    func dictionary() -> [String : Encodable] {
        var dict: [String : Encodable] = [
            "purchAmount": amount,
            "description": description,
            "currency": currency,
            "cardType": cardType.rawValue,
            "TDS2CardholderName": TDS2CardHolderName,
            "TDS2BillAddrCity": TDS2BillAddrCity,
            "TDS2BillAddrLine1": TDS2BillAddrLine1,
            "TDS2BillAddrCountry": country,
            "TDS2BillAddrPostCode": TDS2BillAddrPostCode,
            "installments": installments,
            "recurFreq": recurFreq,
            "recurEnd": recurEnd
        ]
        
        switch paymentType {
        case .viaToken(let token, let cardType):
            dict["extToken"] = token
            dict["extTokenOptions"] = "110"
        case .viaCardEncData(let cardEncData):
            dict["cardEncData"] = cardEncData
            if shouldStoreCard {
                dict["extTokenOptions"] = "100"
            }
        }
        
        return dict
    }
}

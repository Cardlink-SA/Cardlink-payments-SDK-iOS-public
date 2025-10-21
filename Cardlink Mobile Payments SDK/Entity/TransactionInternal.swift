//
//  TransactionInternal.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 2/12/22.
//

struct TransactionInternal: Codable, Equatable {
    let OrderId: String?
    let OrderAmount: String?
    let Currency: String?
    let PaymentTotal: String?
    let Status: TransactionStatus?
    let TxId: String?
    let PaymentRef: String?
    let RiskScore: String?
    let ExtToken: String?
    let ExtTokenPanEnd: String?
    let ExtTokenExp: String?
    let Description: String?
}

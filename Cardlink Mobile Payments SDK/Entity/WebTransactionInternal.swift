//
//  WebTransactionInternal.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 23/3/23.
//

public struct WebTransactionInternal: Codable {
    let version: String?
    let mid: String?
    let orderid: String?
    let status: TransactionStatus?
    let orderAmount: String?
    let currency: String?
    let paymentTotal: String?
    let message: String?
    let riskScore: String?
    let txId: String?
    let digest: String?
}

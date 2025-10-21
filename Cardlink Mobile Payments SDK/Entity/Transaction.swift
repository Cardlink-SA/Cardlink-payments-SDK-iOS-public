//
//  Transaction.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/3/23.
//

public struct Transaction {
    // The id of this order.
    let orderId: String
    // The payment amount.
    let amount: String
    // The currency of this transaction.
    let currency: String
    // The description of this transaction.
    let description: String
}

extension Transaction {
    static func fromInternalTransaction(_ internalTransaction: TransactionInternal) -> Transaction {
        return Transaction(
            orderId: internalTransaction.OrderId ?? "",
            amount: internalTransaction.OrderAmount ?? "0",
            currency: internalTransaction.Currency ?? "EUR",
//            total: internalTransaction.PaymentTotal ?? internalTransaction.OrderAmount ?? "0",
            description: internalTransaction.Description ?? ""
        )
    }
    
    static func fromWebInternalTransaction(_ webInternalTransaction: WebTransactionInternal) -> Transaction {
        return Transaction(
            orderId: webInternalTransaction.orderid ?? "",
            amount: webInternalTransaction.orderAmount ?? "0",
            currency: webInternalTransaction.currency ?? "EUR",
//            total: webInternalTransaction.paymentTotal ?? webInternalTransaction.orderAmount ?? "0",
            description: webInternalTransaction.message ?? ""
        )
    }
}

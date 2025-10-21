//
//  TransactionStatus.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 28/11/22.
//

enum TransactionStatus: String, Codable, Equatable {
    case AUTHORIZED
    case CAPTURED
    case REFUSED
    case REFUSEDRISK
    case CANCELED
    case ERROR
}

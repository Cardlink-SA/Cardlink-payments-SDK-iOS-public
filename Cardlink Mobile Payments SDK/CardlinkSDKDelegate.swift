//
//  CardlinkSDKDelegate.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/3/23.
//

public protocol CardlinkSDKDelegate: AnyObject {
    // Called when the payment was successful. The payment transaction is included.
    func paymentCompleted(_ transaction: Transaction) 
}

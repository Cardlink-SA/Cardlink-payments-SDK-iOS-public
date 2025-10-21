//
//  ErrorMessage.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 2/12/22.
//

class ErrorMessage {
    static let networkError = NSLocalizedString("There was an error while contacting the server. Please try again later.", comment: "")
    
    static let networkOffline = NSLocalizedString("Connection is offline.\nPlease make sure you are connected to the internet and try again.", comment: "")
    
    static let jsError = NSLocalizedString("The server response is invalid", comment: "")
    
    static let paymentResponseError = NSLocalizedString("The payment response was invalid", comment: "")
    static let invalidState = NSLocalizedString("Invalid state", comment: "")
}

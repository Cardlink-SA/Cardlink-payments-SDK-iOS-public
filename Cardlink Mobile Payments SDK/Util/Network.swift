//
//  Network.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 27/11/22.
//

protocol Network {
    func getSettings(_ result: @escaping (RequestResult) -> Void)
    func getCards(_ result: @escaping (RequestResult) -> Void)
    func deleteCard(cardToken: String, _ result: @escaping (RequestResult) -> Void)
    func getJS(_ result: @escaping (RequestResult) -> Void)
    func makePayment(payment: ActivePayment, result: @escaping (RequestResult) -> Void)
    func makeIrisPayment(dictionary: [String : Codable], result: @escaping (RequestResult) -> Void)
    func makePayPalPayment(dictionary: [String : Codable], result: @escaping (RequestResult) -> Void)
}

enum RequestResult {
    case success(_ response: String?)
    case failure(Error)
}

enum ApiPath: String {
    case settings = "/wp-json/app-payments/settings"
    case js = "/wp-json/app-payments/get-js"
    case payment = "/wp-json/app-payments/payment"
    case paymentIris = "/wp-json/app-payments/payment/iris/"
    case paymentIrisResponse = "/wp-json/app-payments/payment/iris/response"
    case paymentPaypal = "/wp-json/app-payments/payment/paypal/"
    case paymentPaypalResponse = "/wp-json/app-payments/payment/paypal/response"
    case success3DS = "/wp-json/app-payments/payment/success"
    case fail3DS = "/wp-json/app-payments/payment/fail"
    case userCards = "/wp-json/app-payments/user-cards"
    case userCardDelete = "/wp-json/app-payments/user-cards/delete"
}

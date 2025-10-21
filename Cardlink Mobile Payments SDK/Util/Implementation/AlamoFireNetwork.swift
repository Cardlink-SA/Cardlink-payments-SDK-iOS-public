//
//  AlamoFireNetwork.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 27/11/22.
//

import Alamofire

class AlamoFireNetwork: Network {
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    let baseURL: URL
    
    func getSettings(_ result: @escaping (RequestResult) -> Void) {
        request(
            .settings,
            method: .post,
            result: result
        )
    }
    
    func getCards(_ result: @escaping (RequestResult) -> Void) {
        request(
            .userCards,
            method: .post,
            result: result
        )
    }
    
    func deleteCard(cardToken: String, _ result: @escaping (RequestResult) -> Void) {
        request(
            .userCardDelete,
            method: .post,
            parameters: ["card_token": cardToken],
            result: result
        )
    }
    
    func getJS(_ result: @escaping (RequestResult) -> Void) {
        request(
            .js,
            method: .post,
            result: result
        )
    }
    
    func makePayment(
        payment: ActivePayment,
        result: @escaping (RequestResult) -> Void
    ) {
        request(
            .payment,
            method: .post,
            parameters: payment.dictionary(),
            encoding: JSONEncoding.default,
            result: result
        )
    }
    
    func makeIrisPayment(dictionary: [String : Codable], result: @escaping (RequestResult) -> Void) {
        request(
            .paymentIris,
            method: .post,
            parameters: dictionary,
            result: result
        )
    }
    
    func makePayPalPayment(dictionary: [String : Codable], result: @escaping (RequestResult) -> Void) {
        request(
            .paymentPaypal,
            method: .post,
            parameters: dictionary,
            result: result
        )
    }
}

private extension AlamoFireNetwork {
    func request(
        _ path: ApiPath,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        result: @escaping (RequestResult) -> Void
    ) {
        let base = baseURL.absoluteURL.description.trimTrailing("/")
        let path = path.rawValue.trimLeading("/")
        let url = "\(base)/\(path)"
        print(url, parameters)
        print("-------------------------------------")
        Alamofire.request(url, method: .post, parameters: parameters, encoding: encoding)
            .responseString(completionHandler: { response in
                switch response.result {
                case let .success(string):
                    result(.success(string))
                case let .failure(error):
                    result(.failure(error))
                }
            })
    }
}

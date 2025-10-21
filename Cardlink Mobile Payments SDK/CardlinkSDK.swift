//
//  CardlinkSDK.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 23/11/22.
//

import UIKit

public class CardlinkSDK {
    public let serverURL: URL
    public init(serverURL: URL) {
        self.serverURL = serverURL
        UIFont.registerFonts()
    }
    
    public weak var delegate: CardlinkSDKDelegate? = nil
    
    lazy var module: LibraryModule = LibraryModule(sdk: self)
    
    private lazy var log = module.log
    private lazy var network = module.network
        
    public func makePayment(
        // The host controller for the actual payment controller
        present hostViewController: UIViewController,
        // A positive integer representing how much to charge in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100).
        amount: UInt,
        // A description for this payment transaction.
        description: String,
        // The Card Holder name (for Card payments).
        TDS2CardHolderName: String,
        // The Card Holder city (for Card payments).
        TDS2BillAddrCity: String,
        // The Card Holder address (for Card payments).
        TDS2BillAddrLine1: String,
        // The Card Holder postal code (for Card payments).
        TDS2BillAddrPostCode: String,
        installments: UInt? = nil,
        frequency: Int?,
        frequencyEndDate: String
    ) {
        retrieveSettings()
        retrieveJS()
        retrieveUserCards()
        
        payment = Payment(
            amount: amount,
            description: description,
            TDS2CardHolderName: TDS2CardHolderName,
            TDS2BillAddrCity: TDS2BillAddrCity,
            TDS2BillAddrLine1: TDS2BillAddrLine1,
            TDS2BillAddrPostCode: TDS2BillAddrPostCode,
            installments: installments,
            cardType: .unknown,
            shouldStoreCard: false,
            recurFreq: frequency,
            recurEnd: frequencyEndDate
        )
        
        let vc = MainViewController.loadFromNib(sdk: self)
        hostViewController.present(vc, animated: true)
    }
    
    enum PayError: Error {
        case html3DSEmpty
        case invalidState
    }
    
    enum PayResult {
        case success3DS(html3DS: String)
        case successNo3DS(transaction: TransactionInternal?)
        case failure(error: Error)
    }
    
    func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    func pay(
        cardEncData: String,
        cardType: CardType,
        result: @escaping ((PayResult) -> Void)
    ) {
        guard let payment = payment else {
            self.log.e("Invalid state: No payment object in CardlinkSDK.")
            result(.failure(error: PayError.invalidState))
            return
        }
        
        payment.cardType = cardType
        let activePayment = payment.makeActiveWithCardEncData(cardEncData, storeCard: payment.shouldStoreCard)
        makePayment(activePayment, result: result)
    }
    
    func pay(
        cardToken: String,
        cardType: CardType,
        result: @escaping ((PayResult) -> Void)
    ) {
        guard let payment = payment else {
            self.log.e("Invalid state: No payment object in CardlinkSDK.")
            result(.failure(error: PayError.invalidState))
            return
        }
        
        payment.cardType = cardType
        let activePayment = payment.makeActiveWithCardTokenType(cardToken, type: cardType)
        makePayment(activePayment, result: result)
    }
    
    func payIris(
        result: @escaping ((PayResult) -> Void)
    ) {
        guard let payment = payment else {
            self.log.e("Invalid state: No payment object in CardlinkSDK.")
            result(.failure(error: PayError.invalidState))
            return
        }
        
        network.makeIrisPayment(dictionary: payment.makeWebPaymentDictionaryFor(.iris), result: { [weak self] requestResult in
            self?.clearCache()
            guard let self = self else { return }
            switch requestResult {
            case let .success(response):
                guard let response = response, !response.isEmpty else {
                    // TODO
                    result(.failure(error: NSError()))
                    return
                }
                
                result(.success3DS(html3DS: response))
                break
            case let .failure(error):
                result(.failure(error: error))
                self.log.e("Payment error (\(error)")
            }
        })
    }
    
    func payPaypal(
        result: @escaping ((PayResult) -> Void)
    ) {
        guard let payment = payment else {
            self.log.e("Invalid state: No payment object in CardlinkSDK.")
            result(.failure(error: PayError.invalidState))
            return
        }
        
        network.makePayPalPayment(dictionary: payment.makeWebPaymentDictionaryFor(.iris), result: { [weak self] requestResult in
            self?.clearCache()
            guard let self = self else { return }
            switch requestResult {
            case let .success(response):
                guard let response = response, !response.isEmpty else {
                    // TODO
                    result(.failure(error: NSError()))
                    return
                }
                
                result(.success3DS(html3DS: response))
                break
            case let .failure(error):
                result(.failure(error: error))
                self.log.e("Payment error (\(error)")
            }
        })
    }
    
    func deleteCard(
        token: String,
        result: @escaping ((Bool) -> Void)
    ) {
        network.deleteCard(cardToken: token) { response in
            result(true)
        }
    }
    
    enum SDKError: Error {
        case emptyResponse
        case couldNotParseJSON
    }
    
    enum FetchStatus<Data>: Equatable {
        static func == (lhs: CardlinkSDK.FetchStatus<Data>, rhs: CardlinkSDK.FetchStatus<Data>) -> Bool {
            switch (lhs, rhs) {
            case (.idle,.idle):
                return true
            case (.isRetrieving,.isRetrieving):
                return true
            case (.available,.available):
                return true
            case (.error,.error):
                return true
            default:
                return false
            }
        }
        
        case idle
        case isRetrieving
        case available(Data)
        case error(Error)
    }
    
    var settingsObserver: ((FetchStatus<Settings?>) -> Void)? = nil {
        didSet {
            settingsObserver?(settingsStatus)
        }
    }
    
    private var settingsStatus: FetchStatus<Settings?> = .idle {
        didSet {
            settingsObserver?(settingsStatus)
        }
    }
    
    var jsStatusObserver: ((FetchStatus<String>) -> Void)? = nil {
        didSet {
            jsStatusObserver?(jsStatus)
        }
    }
    
    private var jsStatus: FetchStatus<String> = .idle {
        didSet {
            jsStatusObserver?(jsStatus)
        }
    }
    
    var userCardsObserver: ((FetchStatus<[Card]>) -> Void)? = nil {
        didSet {
            userCardsObserver?(userCardsStatus)
        }
    }
    
    private var userCardsStatus: FetchStatus<[Card]> = .idle {
        didSet {
            userCardsObserver?(userCardsStatus)
        }
    }
    
    private(set) var settings: Settings? = nil
    private(set) var userCards: [Card] = []
    private var isRetrievingCards = false
    private var didFailToRetrieveCards = false
    
    private(set) var jsCode: String? = nil
    private var isRetrievingJS = false
    private var didFailToRetrieveJS = false
    private var shouldRetrieveJS: Bool {
        get {
            return !isRetrievingJS && didFailToRetrieveJS
        }
    }
    
    private(set) var payment: Payment? = nil
    
    func retrieveJS() {
        if jsStatus == .isRetrieving {
            return
        }
        
        jsStatus = .isRetrieving
        if let cachedJS = self.retrieveJSFromCache(), !cachedJS.isEmpty {
            self.jsStatus = .available(cachedJS)
        }
        
        network.getJS { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(jsCode):
                guard let jsCode = jsCode, !jsCode.isEmpty else {
                    self.jsStatus = .error(SDKError.emptyResponse)
                    return
                }
                
                self.didRetrieveJSFromServer(jsCode)
            case let .failure(error):
                if case .available = self.jsStatus {
                    break
                } else {
                    self.jsStatus = .error(error)
                }
            }
        }
    }
    
    func retrieveSettings() {
        if settingsStatus == .isRetrieving {
            settingsStatus = .isRetrieving // To notify the observer.
            return
        }
        
        if let settings = settings {
            settingsStatus = .available(settings)
        } else {
            settingsStatus = .isRetrieving
        }
        
        network.getSettings { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(json):
                do {
                    guard let data = (json ?? "").data(using: .utf8) else {
                        self.userCardsStatus = .error(SDKError.emptyResponse)
                        self.log.e("Could not decode settings (empty response)")
                        return
                    }
                    
                    let response = try JSONDecoder().decode(SettingsResponse.self, from: data)
                    self.settings = response.settings
                    self.settingsStatus = .available(response.settings)
                } catch {
                    self.settingsStatus = .error(SDKError.couldNotParseJSON)
                    self.log.e("Could not decode settings (\(error.localizedDescription))")
                }
            case let .failure(error):
                if case .available = self.userCardsStatus {
                    self.settingsStatus = .available(self.settings) // To notify the observer.
                    break
                } else {
                    self.settingsStatus = .error(error)
                }
            }
        }
    }
    
    func retrieveUserCards() {
        if userCardsStatus == .isRetrieving {
            userCardsStatus = .isRetrieving // To notify the observer.
            return
        }
        
        userCardsStatus = .isRetrieving
        network.getCards { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(json):
                do {
                    guard let data = (json ?? "").data(using: .utf8) else {
                        self.userCardsStatus = .error(SDKError.emptyResponse)
                        self.log.e("Could not decode user cards (empty response)")
                        return
                    }
                    
                    let response = try JSONDecoder().decode(CardsResponse.self, from: data)
                    self.userCards = response.cards
                    self.userCardsStatus = .available(self.userCards)
                } catch {
                    self.userCardsStatus = .error(SDKError.couldNotParseJSON)
                    self.log.e("Could not decode user cards (\(error.localizedDescription))")
                }
            case let .failure(error):
                if case .available = self.userCardsStatus {
                    self.userCardsStatus = .available(self.userCards) // To notify the observer.
                    break
                } else {
                    self.userCardsStatus = .error(error)
                }
            }
        }
    }
}

private extension CardlinkSDK {
    func initDI() {
        module = LibraryModule(sdk: self)
        
        log = module.log
        network = module.network
    }
    
    func didRetrieveJSFromServer(_ js: String) {
        if
            let jsonObject = js.jsonDictionary(),
            let js = jsonObject["body"] as? String,
            !js.isEmpty
        {
            self.jsStatus = .available(js)
            self.cacheJS(js)
            return
        }
        
        self.jsStatus = .error(SDKError.couldNotParseJSON)
    }
    
    func cacheURL() -> URL? {
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("gr.cardlink.mobilepayments.sdk.js")
    }
    
    func retrieveJSFromCache() -> String? {
        guard let cacheURL = cacheURL() else {
            log.e("Cannot retrieve cache path for loading cache.")
            return nil
        }
        
        do {
            let string = try String(contentsOf: cacheURL)
            return string
        } catch {
            log.e("Cannot retrieve local cache (\(error)")
        }
        
        return nil
    }
    
    func cacheJS(_ jsCode: String) {
        guard let cacheURL = cacheURL() else {
            log.e("Cannot retrieve cache path for saving cache.")
            return
        }
        
        do {
            try jsCode.write(to: cacheURL, atomically: true, encoding: .utf8)
        } catch {
            log.e("Cannot write cached JS File (\(error)")
        }
    }
    
    private func makePayment(_ activePayment: ActivePayment, result: @escaping ((PayResult) -> Void)) {
        network.makePayment(payment: activePayment) { [weak self] requestResult in
            self?.clearCache()
            guard let self = self else { return }
            switch requestResult {
            case let .success(response):
                guard
                    let response = response,
                    let html3DS = response.jsonDictionary()?["body"] as? String,
                    !html3DS.isEmpty
                else {
                    guard
                        let response = response,
                        let paymentResponse: PaymentResponse = response.jsonType()
                    else {
                        self.log.e("Invalid 3DS response:\n\n \(response)")
                        result(.failure(error: PayError.html3DSEmpty))
                        return
                    }
                    
                    result(.successNo3DS(transaction: paymentResponse.transaction))
                    return
                }
                
                result(.success3DS(html3DS: html3DS))
                break
            case let .failure(error):
                result(.failure(error: error))
                self.log.e("Payment error (\(error)")
            }
        }
    }
}

extension UIFont {
    static func registerFonts() {
        let fonts = Bundle(for: CardlinkSDK.self).urls(forResourcesWithExtension: "ttf", subdirectory: nil)
        fonts?.forEach({ url in
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        })
        
        //        UIFont.familyNames.forEach { (font) in
        //            print("Family Name: \(font)")
        //            UIFont.fontNames(forFamilyName: font).forEach({
        //                print("--Font Name: \($0)")
        //            })
        //        }
    }
}

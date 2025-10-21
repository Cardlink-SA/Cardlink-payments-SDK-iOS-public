//
//  Model.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/1/23.
//

enum State: Equatable {
    case idle
    case userCards
    // User enters card information.
    case cardEntry
    // App is contacting the SDK backend.
    case contactingAPI
    // Cardlink SDK backend has responded, 3DS WebView is shown.
    case payment3DS
    // 3DS has reached the success URL, WebView is hidden.
    // No UI is shown, but it only lasts a few milliseconds, until the WebView content is processed.
    case payment3DSResponded
    // Response parsed from WebView, proceed to the success or failure states automatically.
    case payment3DSCompleted
    // Payment was a success.
    case success(TransactionInternal?)
    // Payment was a failure.
    case failure(TransactionInternal?)
    // Error during the process.
    case error(ErrorState)
}

enum ErrorState: Error, Equatable {
    static func == (lhs: ErrorState, rhs: ErrorState) -> Bool {
        switch (lhs, rhs) {
        case (.errorLoadingJS,.errorLoadingJS):
            return true
        case (.sdkAPI,.sdkAPI):
            return true
        case (.server3DS,.server3DS):
            return true
        case (.response3DSJavaScriptError,.response3DSJavaScriptError):
            return true
        case (.response3DSJavaScriptResponseEmpty,.response3DSJavaScriptResponseEmpty):
            return true
        case (.noTransactionStatusAvailable,.noTransactionStatusAvailable):
            return true
        case (.cardNoPanOrToken,.cardNoPanOrToken):
            return true
        default:
            return false
        }
    }
    
    case errorLoadingJS(Error)
    case sdkAPI(Error)
    case server3DS(Error)
    case response3DSJavaScriptError
    case response3DSJavaScriptResponseEmpty
    case noTransactionStatusAvailable
    case cardNoPanOrToken
    
    var message: String {
        get {
            switch self {
            case .errorLoadingJS(let error):
                return networkErrorMessageForError(error)
            case .sdkAPI(let error):
                return networkErrorMessageForError(error)
            case .server3DS(let error):
                return networkErrorMessageForError(error)
            case .response3DSJavaScriptError:
                return ErrorMessage.jsError
            case .response3DSJavaScriptResponseEmpty:
                return ErrorMessage.jsError
            case .noTransactionStatusAvailable:
                return ErrorMessage.paymentResponseError
            case .cardNoPanOrToken:
                return ErrorMessage.invalidState
            }
        }
    }
    
    private func networkErrorMessageForError(_ error: Error) -> String {
        if error.isNetworkOffline() {
            return ErrorMessage.networkOffline
        }
        
        return ErrorMessage.networkError
    }
}

//
//  WKWebview+.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 11/1/23.
//

import WebKit

extension WKWebView {
    func evalJSSafe(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
        }
    }
    
    func fixScaleViaJS() {
        let js = """
var meta = document.createElement('meta');
meta.setAttribute( 'name', 'viewport' );
meta.setAttribute( 'content', 'width = device-width, initial-scale = 1.0, user-scalable = yes' );
document.getElementsByTagName('head')[0]?.appendChild(meta);
"""
        evaluateJavaScript(js) { _, error in
            if let error = error {
                SimpleLog().e("Cannot fix scale of WKWebView page (\(error)")
            }
        }
    }
    
    func transactionFromContent<T:Codable>(type: T.Type, _ result: @escaping (Optional<T>) -> Void) {
        transactionFromContentWithJS("document.body.firstChild.innerHTML", type: type) { [weak self] transaction in
            guard let self = self else { return }
            guard let transaction = transaction else {
                // Could not parse JSON from WebView as dictionary.
                // Let's retry by getting the entire page <body>.
                self.transactionFromContentWithJS("document.body.innerHTML", type:type, result: result)
                return
            }
            
            result(transaction)
        }
    }
    
    private func transactionFromContentWithJS<T:Codable>(_ js: String, type: T.Type, result: @escaping (Optional<T>) -> Void) {
        evalJSSafe(js) { [weak self] value, error -> Void in
            guard let _ = self else { return }
            if error != nil {
                SimpleLog().e("JS Error while retrieving success URL body (\(error?.localizedDescription ?? ""))")
                result(nil)
                return
            }
            
            guard
                let valueString = value as? String,
                let paymentResponse: T = valueString.jsonType()
            else {
                SimpleLog().e("Error while parsing success URL body as PaymentResponse JSON")
                result(nil)
                return
            }
            
            result(paymentResponse)
        }
    }
}

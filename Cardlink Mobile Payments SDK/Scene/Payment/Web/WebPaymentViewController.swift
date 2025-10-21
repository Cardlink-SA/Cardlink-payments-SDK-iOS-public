//
//  WebPaymentViewController.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 23/3/23.
//

import Lottie
import UIKit
import WebKit

class WebPaymentViewController: ViewControllerBase {
    @IBOutlet private weak var loadingView: UIView!
    @IBOutlet private weak var loaderAnimation: AnimationView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bottomButton: UIButton!
    @IBOutlet private weak var resultContainer: AnimationContainer!
    
    enum State {
        case idle
        case working
        case dataEntry
        case success
        case failure
        case error(Error?)
    }
    
    enum PaymentType {
        case iris
        case paypal
    }
    
    var paymentType: PaymentType? {
        didSet {
            if let _ = webView.window {
                makePayment()
            }
        }
    }
    
    private var state = State.idle {
        didSet {
            switch state {
            case .idle, .dataEntry:
                showNavBarButton(true)
            case .working, .success, .failure, .error(_):
                showNavBarButton(false)
            }
        }
    }
        
    private let webView = WKWebView()
    private var paymentRequest: URL!
    private var paymentSuccess: URL!
    private var paymentFailure: URL!
    
    private var hasStartedPayment = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Animations.prepareLoaderAnim(loaderAnimation)
        prepareWebView()
        
        makePayment()
    }
}

private extension WebPaymentViewController {
    @IBAction func bottomButtonPressed() {
        switch state {
        case .idle,.working, .dataEntry:
            break
        case .success:
            dismiss(animated: true)
            // TODO: Delegate
        case .failure:
            state = .idle
            makePayment()
        case .error(_):
            state = .idle
            makePayment()
        }
    }
    
    func prepareWebView() {
        webView.addToContainer(view)
        view.bringSubviewToFront(loadingView)
        webView.navigationDelegate = self
    }
    
    func setLoading(_ isLoading: Bool) {
        loadingView.alpha = isLoading ? 1 : 0
    }
    
    func makePayment() {
        guard !hasStartedPayment else { return }
        
        hasStartedPayment = true
        setLoading(true)
        guard let paymentType = paymentType else {
            return
        }
        
        switch paymentType {
        case .iris:
            showNavBarButton(false)
            sdk.payIris(result: { [weak self] result in
                self?.handlePaymentResult(result: result)
            })
        case .paypal:
            sdk.payPaypal(result: { [weak self] result in
                self?.handlePaymentResult(result: result)
            })
        }
    }
    
    func handlePaymentResult(result: CardlinkSDK.PayResult) {
        switch result {
        case .success3DS(let html3DS):
            self.state = .dataEntry
            self.showHTML(html3DS)
        case .failure(let error):
            self.state = .error(error)
            self.setLoading(true)
            break
        default:
            break
        }
    }
    
    func showHTML(_ html: String) {
        DispatchQueue.main.async { [weak self] in
            self?.setLoading(false)
            self?.webView.loadHTMLString(html.properHtmlStructure(), baseURL: nil)
        }
    }
    
    func showNavBarButton(_ shouldShow: Bool) {
        (navigationController?.parent as? MainViewController)?.navBar?.showLeftButton = shouldShow
    }
    
    func success(_ webTransaction: WebTransactionInternal) {
        self.state = .success
        setLoading(false)
        var message = ""
        if let transactionId = webTransaction.txId {
            message = String(format: NSLocalizedString("\nTransaction id: (%@)", comment: ""), transactionId)
        }
        titleLabel.text = NSLocalizedString("Your payment was successful!\(message)", comment: "")
        bottomButton.setTitle(NSLocalizedString("Back to shop", comment: ""), for: .normal)
        
        Animations.prepareSuccessAnim(resultContainer)
        resultContainer.fadeIn()
    }
    
    func failure(_ webTransaction: WebTransactionInternal) {
        let transaction = Transaction.fromWebInternalTransaction(webTransaction)
        if webTransaction.status == .CANCELED {
            navigationController?.popViewController(animated: true)
            return
        }
        
        self.state = .failure
        var message = ""
        if !transaction.description.isEmpty {
            message = String(format: NSLocalizedString("\nError: (%@)", comment: ""), transaction.description)
        }
        setLoading(false)
        titleLabel.text = NSLocalizedString("Payment failed\(message)", comment: "")
        bottomButton.setTitle(NSLocalizedString("Retry", comment: ""), for: .normal)
        
        Animations.prepareErrorAnim(resultContainer)
        resultContainer.fadeIn()
    }
    
    func error() {
        // TODO
    }
}

extension WebPaymentViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        sdk.clearCache()
        
        let isResultURL =
        (paymentType == .iris && webView.url?.path.starts(with: ApiPath.paymentIrisResponse.rawValue) == true) ||
        (paymentType == .paypal && webView.url?.path.starts(with: ApiPath.paymentPaypalResponse.rawValue) == true)
        
        if isResultURL {
            webView.isHidden = true
            webView.transactionFromContent(type: WebPaymentResponse.self) { [weak self] response in
                guard
                    let transaction = response?.data,
                    let status = transaction.status
//                        ,
//                    (status == .AUTHORIZED || status == .CAPTURED)
                else {
                    DispatchQueue.main.async { [weak self] in
                        guard let transactionInternal = response?.data else {
                            self?.error()
                            return
                        }
                        
                        self?.failure(transactionInternal)
                    }
                    
                    return
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.success(transaction)
                }
            }
        } else {
            webView.isHidden = false
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        log.e("WebView: Did fail provisional navigation. Error \(error)")
        sdk.clearCache()
        setLoading(false)
        // TODO
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        sdk.clearCache()
        // TODO: Check success fail
        decisionHandler(.allow)
    }
}

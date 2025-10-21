//
//  SelectMethodViewController.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 4/3/23.
//

import Lottie
import UIKit

class SelectMethodViewController: ViewControllerBase {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private var cardButton: UIView!
    @IBOutlet private var irisButton: UIView!
    @IBOutlet private var paypalButton: UIView!
    
    @IBOutlet private var cardLogosStackView: UIStackView!
    
    @IBOutlet private weak var loaderAnimation: AnimationView!
    
    @IBOutlet private weak var errorView: UIView!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var errorRetryButton: Button!
    
    var selectCallback: ((PaymentMethod, Bool) -> ())? = nil
    
    private static let BUTTON_SPACING: CGFloat = 17
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareLiterals()
        clearStackView()
        
        showError(false)
        setLoading(false)
        
        prepareSettingsObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sdk.retrieveSettings()
    }
}

private extension SelectMethodViewController {
    @IBAction private func selectCard() {
        selectCallback?(.card, true)
    }
    
    @IBAction private func selectIris() {
        selectCallback?(.iris, true)
    }
    
    @IBAction private func selectPaypal() {
        selectCallback?(.paypal, true)
    }
    
    @IBAction private func retry() {
        errorView.isHidden = true
        sdk.retrieveSettings()
    }
    
    func prepareLiterals() {
        titleLabel.text = NSLocalizedString("Please select a payment method", comment: "")
        
        errorLabel.text = NSLocalizedString("There was an error contacting the server.", comment: "")
        errorRetryButton.setTitle(NSLocalizedString("Retry", comment: ""), for: .normal)
    }
    
    func showError(_ shouldShow: Bool) {
        if (shouldShow) {
            setLoading(false)
        }
        
        titleLabel.isHidden = shouldShow
        errorView.isHidden = !shouldShow
        stackView.isHidden = shouldShow
    }
    
    func setLoading(_ isLoading: Bool) {
        if (isLoading) {
            showError(false)
            Animations.prepareLoaderAnim(loaderAnimation)
        }
        
        stackView.isHidden = isLoading
        titleLabel.isHidden = isLoading
        cardLogosStackView.isHidden = isLoading
        loaderAnimation.isHidden = !isLoading
    }
    
    func prepareSettingsObserver() {
        sdk.settingsObserver = { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .idle:
                break
            case .isRetrieving:
                self.setLoading(true)
            case let .available(settings):
                self.setLoading(false)
                guard let _ = settings else {
                    self.showError(true)
                    return
                }
                
                self.populateButtons()
                self.populateCardLogos()
                self.prepareAcquirer()
                
                // TODO: Call payment delegate when done or on error
            case .error(_):
                self.setLoading(false)
                self.showError(true)
            }
        }
    }
    
    func clearStackView() {
        for view in stackView.arrangedSubviews {
            view.removeFromSuperview()
        }
    }
    
    func lastColumnStackView() -> UIStackView? {
        return stackView.arrangedSubviews.last?.subviews.first as? UIStackView
    }
    
    func addOrGetLastColumnStackView() -> UIStackView {
        var row = stackView.arrangedSubviews.last
        if row == nil {
            row = UIView()
            stackView.addArrangedSubview(row!)
        }
        
        var columnsStackView = row?.subviews.first as? UIStackView
        if columnsStackView == nil {
            columnsStackView = UIStackView()
            columnsStackView?.spacing = Self.BUTTON_SPACING
            columnsStackView?.addToContainer(row!)
        }
        
        if columnsStackView!.arrangedSubviews.count > 1 {
            stackView.addArrangedSubview(UIView())
            return addOrGetLastColumnStackView()
        }
        
        return columnsStackView!
    }
    
    func addButton(_ view: UIView) {
        let columnsStackView = addOrGetLastColumnStackView()
        columnsStackView.addArrangedSubview(view)
    }
    
    // If button row contains only one button, a second empty view is required
    // to fix alignment issues.
    func addEmptyButtonViewIfRequired() {
        guard
            let columnsStackView = lastColumnStackView(),
            columnsStackView.arrangedSubviews.count < 2,
            let leftView = columnsStackView.arrangedSubviews.first
        else {
            return
        }
        
        let rightView = UIView()
        columnsStackView.addArrangedSubview(rightView)
        rightView.widthAnchor.constraint(equalTo:  leftView.widthAnchor).isActive = true
    }
    
    func populateButtons() {
        clearStackView()
        let methods = (sdk.settings?.accepted_payment_methods ?? []).toSet()
        if methods.count == 1 {
            if let method = methods.first {
                selectCallback?(method, false)
                return
            }
        }
        
        for method in methods {
            switch method {
            case .card:
                addButton(cardButton)
            case .iris:
                addButton(irisButton)
            case .paypal:
                addButton(paypalButton)
            case .unknown:
                continue
            }
        }
        
        addEmptyButtonViewIfRequired()
    }
    
    func populateCardLogos() {
        for view in cardLogosStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        let cards = (sdk.settings?.accepted_card_types ?? []).toSet()
        for card in cards {
            if card == .unknown {
                continue
            }
            
            let image = UIImage(
                named: card.imageSmall(),
                in: Bundle(for: type(of: self)),
                compatibleWith: nil
            )
            
            let cardView = UIView()
            cardView.layer.cornerRadius = 5
            cardView.layer.masksToBounds = true
            cardView.layer.borderWidth = 1
            cardView.layer.borderColor = UIColor(white: 0, alpha: 0.1).cgColor
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.addToContainer(cardView)
            
            cardLogosStackView.addArrangedSubview(cardView)
            cardView.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
            cardView.heightAnchor.constraint(equalToConstant:  26.0).isActive = true
        }
    }
}

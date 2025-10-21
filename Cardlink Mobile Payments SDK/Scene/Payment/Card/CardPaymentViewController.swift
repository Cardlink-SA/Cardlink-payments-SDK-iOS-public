//
//  CardPaymentViewController.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 23/11/22.
//

import Lottie
import UIKit
import WebKit

class CardPaymentViewController: ViewControllerBase {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleImage: UIImageView!
    
    @IBOutlet private weak var userCardsContainer: UIView!
    
    @IBOutlet private weak var installmentsZeroHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var installmentsContainer: UIView!
    @IBOutlet private weak var installmentsTitleLabel: UILabel!
    @IBOutlet private weak var installmentsInputTitleLabel: UILabel!
    
    @IBOutlet private weak var installmentsBox: UIView!
    @IBOutlet private weak var installmentsSelectionLabel: UILabel!
    
    @IBOutlet private weak var cardContainer: UIView!
    
    @IBOutlet private weak var scrollView: KeyboardAvoidingScrollView!
    @IBOutlet private weak var panContainer: TextFieldContainer!
    @IBOutlet private weak var expirationDateContainer: TextFieldContainer!
    @IBOutlet private weak var cvvContainer: TextFieldContainer!
    @IBOutlet private weak var cardHolderNameContainer: TextFieldContainer!
    
    @IBOutlet private weak var cardInfoStack: UIStackView!
    @IBOutlet private weak var panTextField: CardTextField!
    @IBOutlet private weak var cardHolderNameTextField: CardTextField!
    @IBOutlet private weak var expirationDateTextField: CardTextField!
    @IBOutlet private weak var cvvTextField: CardTextField!
    @IBOutlet private weak var storeCardLabel: UILabel!
    @IBOutlet private weak var payButton: UIButton!
    
    @IBOutlet private weak var webViewContainer: UIView!
    
    @IBOutlet private weak var loaderAnimation: AnimationView!
    @IBOutlet private weak var loadingContainer: UIView!
    @IBOutlet private weak var loadingReason: UILabel!
    
    @IBOutlet private weak var resultContainer: AnimationContainer!
    
    @IBOutlet private weak var bottomButton: UIButton!
    
    private let cardView = CardView.loadFromNib()
    private let userCardsView: UserCardsView = UserCardsView.loadFromNib()
    
    private let webView = WKWebView()
    private var isWebViewReady = false
    
    private var isLoading: Bool = false
    
    private var previousPanTextFieldContent: String?
    private var previousPanTextSelection: UITextRange?
    private var previousDateTextFieldContent: String?
    private var previousDateTextSelection: UITextRange?
    private var previousCVVTextFieldContent: String?
    private var previousCardHolderNameFieldContent: String?
    
    private var installmentsOverlay: UIView? = nil
    
    private var state = State.idle {
        didSet {
            if state != .idle && state == oldValue {
                return
            }
                        
            scrollToTop()
            resetTextFields()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch self.state {
                case .idle:
                    self.state = .userCards
                case .userCards:
                    if self.sdk.userCards.isEmpty {
                        self.sdk.retrieveUserCards()
                    } else {
                        self.userCardsState()
                    }
                case .cardEntry:
                    self.cardEntryState()
                case .contactingAPI:
                    self.contactingAPIState()
                case .payment3DS:
                    self.payment3DSState()
                case .payment3DSResponded:
                    self.payment3DSRespondedState()
                case .payment3DSCompleted:
                    self.payment3DSCompleted()
                case .success(let transaction):
                    self.successState(transaction: transaction)
                case .failure(let transaction):
                    self.failureState(transaction: transaction)
                case .error(let error):
                    self.errorState(error)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        state = .idle
        
        prepareLiterals()
        prepareObservers()
        prepareUserCardsView()
        prepareWebView()
        
        scrollView.alpha = 0
        
        prepareCard()
        prepareInteractions()
        
        Animations.prepareLoaderAnim(loaderAnimation)
        
        reset()
    }
}

private extension CardPaymentViewController {
    @IBAction func payTapped(_ sender: Any) {
        isCardDataValid(true) { [weak self] isValid in
            guard let self = self, isValid else {
                return
            }
            
            let card = self.cardFromFields()
            self.submit(card)
        }
    }
    
    @IBAction func toggleStoreCard(_ sender: Any) {
        guard let storeCardSwitch = (sender as? UISwitch) else { return }
        
        sdk.payment?.shouldStoreCard = storeCardSwitch.isOn
    }
    
    @IBAction @objc func toggleInstallments() {
        if let _ = installmentsOverlay?.superview {
            UIView.animate(withDuration: 0.3, animations: {
                self.installmentsOverlay?.alpha = 0
            }) { [weak self] _ in
                self?.installmentsOverlay?.removeFromSuperview()
            }
            
            return
        }
        
        guard let window = view.window else { return }
        
        let overlay = UIView()
        installmentsOverlay = overlay
        overlay.alpha = 0
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.1)
        overlay.addToContainer(window)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.installmentsOverlay?.alpha = 1
        })
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(toggleInstallments))
        overlay.addGestureRecognizer(tapGR)
        
        let installmentsPickerView = UIPickerView()
        installmentsPickerView.backgroundColor = .white
        installmentsPickerView.delegate = self
        installmentsPickerView.dataSource = self
        installmentsPickerView.translatesAutoresizingMaskIntoConstraints = false
        
        overlay.addSubview(installmentsPickerView)
        
        installmentsPickerView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor).isActive = true
        installmentsPickerView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor).isActive = true
        installmentsPickerView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor).isActive = true
        
        updateInstallmentsSelection(pickerView: installmentsPickerView)
    }
    
    func updateInstallmentsSelection(pickerView installmentsPickerView: UIPickerView?) {
        let variations = installmentVariationsForPaymentAmount()
        var i = 0
        for variation in variations {
            if (variation.installments ?? 1) == sdk.payment?.installments ?? 0 {
                installmentsPickerView?.selectRow(i, inComponent: 0, animated: false)
                installmentsSelectionLabel.text = installmentsText(variation.installments ?? 1)
                return
            }
            
            i += 1
        }
    }
    
    func installmentsText(_ installments: Int) -> String {
        let numberOfInstallments = String(installments)
        let format = installments == 0
            ? NSLocalizedString("Without installments", comment: "")
            : installments == 1
                ? NSLocalizedString("%@ Installment", comment: "")
                : NSLocalizedString("%@ Installments", comment: "")
        
        return String(format: format, numberOfInstallments)
    }
    
    func installmentVariationsForPaymentAmount() -> [InstallmentsVariation] {
        Installments.generateInstallemnts(sdk: sdk)
    }
    
    func prepareInstallments() {
        let shouldShowInstallments = sdk.settings?.installments == true && !installmentVariationsForPaymentAmount().isEmpty
        if shouldShowInstallments {
            installmentsBox.layer.borderColor = UIColor(hex: "#3C42571F")?.cgColor
            installmentsBox.layer.borderWidth = 1.0
            installmentsBox.layer.cornerRadius = 8
            installmentsBox.layer.masksToBounds = true
            updateInstallmentsSelection(pickerView: nil)
        }
        
        showInstallments(shouldShowInstallments)
    }
    
    func showInstallments(_ shouldShow: Bool) {
        installmentsContainer.isHidden = !shouldShow
        installmentsZeroHeightConstraint.priority = shouldShow
        ? UILayoutPriority(1)
        : UILayoutPriority(999)

        if !installmentVariationsForPaymentAmount().isEmpty {
            userCardsView.showInstallments()
        }
    }
    
    func prepareLiterals() {
        installmentsTitleLabel.text = NSLocalizedString("Please Select Installments", comment: "")
        installmentsInputTitleLabel.text = NSLocalizedString(" Installments ", comment: "")
        
        panTextField.placeholder = NSLocalizedString("Card Number", comment: "")
        expirationDateTextField.placeholder = NSLocalizedString("Expiration Date", comment: "")
        cvvTextField.placeholder = NSLocalizedString("CVV", comment: "")
        cardHolderNameTextField.placeholder = NSLocalizedString("Name on Card", comment: "")
        storeCardLabel.text = NSLocalizedString("Store card for future transactions", comment: "")
        payButton.setTitle(NSLocalizedString("Pay", comment: ""), for: .normal)
    }
    
    func prepareObservers() {
        prepareJSObserver()
        prepareUserCardsObserver()
    }
    
    func cardFromFields() -> Card {
        let expYYYY = Int(CardValidation.expirationYYYY(expirationDateTextField.text ?? "") ?? "") ?? 0
        let expMM = Int(CardValidation.expirationMM(expirationDateTextField.text ?? "") ?? "") ?? 0
        let pan = panTextField.text?.removeNonDigits() ?? ""
        let cvv = cvvTextField.text?.removeNonDigits() ?? ""
        let cardHolder = cardHolderNameTextField.text?.trimWhiteSpace() ?? ""
        return Card(
            card_type: cardView.type,
            last4: String(pan.suffix(4)),
            expiry_month: expMM,
            expiry_year: expYYYY,
            pan: pan,
            cvv: cvv,
            cardholder_name: cardHolder
        )
    }
    
    func prepareJSObserver() {
        sdk.jsStatusObserver = { [weak self] status in
            guard let self = self else { return }
            
            switch status {
            case .idle:
                break
            case .isRetrieving:
                self.isLoading = true
            case let .available(js):
                self.isLoading = false
                let html = self.htmlFromJs(js)
                self.webView.navigationDelegate = self
                DispatchQueue.main.async { [weak self] in
                    self?.webView.loadHTMLString(html, baseURL: nil)
                }
            case .error(let error):
                self.isLoading = false
                self.state = .error(.errorLoadingJS(error))
            }
        }
    }
    
    func prepareUserCardsObserver() {
        sdk.userCardsObserver = { [weak self] status in
            guard let self = self else { return }
            if case .userCards = self.state {
                switch status {
                case .idle:
                    break
                case .isRetrieving:
                    self.userCardsStateLoading()
                case let .available(userCards):
                    if userCards.isEmpty {
                        self.state = .cardEntry
                        return
                    }
                    
                    self.userCardsState()
                    DispatchQueue.main.async { [weak self] in
                        self?.userCardsView.populateWithCards(userCards, acquirer: self?.sdk.settings?.acquirer)
                    }
                case .error(_):
                    self.setLoading(false)
                    self.state = .cardEntry
                }
            }
        }
    }
    
    func setLoading(_ isLoading: Bool, reason: String? = nil) {
        if isLoading {
            loadingContainer.fadeIn()
            loadingReason.text = reason
        } else {
            loadingContainer.fadeOut()
        }
    }
    
    func prepareWebView() {
        webView.addToContainer(webViewContainer)
    }
    
    func prepareUserCardsView() {
        userCardsView.sdk = sdk
        userCardsView.addToContainer(userCardsContainer)
        userCardsView.proceedCallback = { [weak self] card in
            guard let self = self else { return 0 }
            guard let card = card else {
                self.state = .cardEntry
                return self.cardView.bounds.size.height
            }
            
            self.cardView.populateWithCard(card)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.submit(card)
            }
            return self.cardView.bounds.size.height
        }
    }
    
    func prepareCard() {
        cardView.addToContainer(cardContainer)
    }
    
    @objc func reformatAsCardNumber(textField: UITextField) {
        var targetCursorPosition = 0
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offset(from: textField.beginningOfDocument, to: startPosition)
        }
        
        var cardNumberWithoutSpaces = ""
        if let text = textField.text {
            cardNumberWithoutSpaces = CardUtil.removeNonDigits(string: text, andPreserveCursorPosition: &targetCursorPosition)
        }
        
        if cardNumberWithoutSpaces.count > cardView.type.maxDigits() {
            textField.text = previousPanTextFieldContent
            textField.selectedTextRange = previousPanTextSelection
            textField.undoManager?.removeAllActions()
            return
        }
        
        let cardNumberWithSpaces = self.insertCreditCardSpaces(cardNumberWithoutSpaces, preserveCursorPosition: &targetCursorPosition)
        textField.text = cardNumberWithSpaces
        
        if let targetPosition = textField.position(from: textField.beginningOfDocument, offset: targetCursorPosition) {
            DispatchQueue.main.async {
                textField.selectedTextRange = textField.textRange(from: targetPosition, to: targetPosition)
            }
        }
        
        textField.undoManager?.removeAllActions()
    }
    
    func insertCreditCardSpaces(_ pan: String, preserveCursorPosition cursorPosition: inout Int) -> String {
        let (panWithSpaces, updatedCursorPosition, groups) = CardUtil.panWithSpacesCursorPositionAndGroups(
            pan: pan,
            cursorPosition: cursorPosition
        )
        
        cursorPosition = updatedCursorPosition
        updatePanPreview(panWithSpaces, groups: groups)
        
        return panWithSpaces
    }
    
    private func updatePanPreview(_ panSoFar: String, groups: [ Int ]) {
        cardView.cardPan.text = CardUtil.panPreview(panSoFar, groups: groups)
        determineCardTypeFromPAN(panSoFar)
    }
    
    @objc func reformatExpirationDate(textField: UITextField) {
        var targetCursorPosition = 0
        if let startPosition = textField.selectedTextRange?.start {
            targetCursorPosition = textField.offset(from: textField.beginningOfDocument, to: startPosition)
        }
        
        var formattedDate = ""
        if let text = textField.text {
            formattedDate = CardUtil.removeNonDigits(string: text, andPreserveCursorPosition: &targetCursorPosition)
        }
        
        if formattedDate.count > 4 {
            textField.text = previousDateTextFieldContent
            prepareDatePreview(textField.text ?? "")
            textField.selectedTextRange = previousDateTextSelection
            textField.undoManager?.removeAllActions()
            return
        }
        
        let dateWithSeparator = CardUtil.dateWithSeparators(
            formattedDate,
            currentValue: expirationDateTextField.text,
            previousValue: previousDateTextFieldContent,
            preserveCursorPosition: &targetCursorPosition
        )
        
        textField.text = dateWithSeparator
        
        let targetCursorPosition2 = min(dateWithSeparator.count, targetCursorPosition)
        if let targetPosition = textField.position(from: textField.beginningOfDocument, offset: targetCursorPosition2) {
            DispatchQueue.main.async {
                textField.selectedTextRange = textField.textRange(from: targetPosition, to: targetPosition)
            }
        }
        
        textField.undoManager?.removeAllActions()
        prepareDatePreview(textField.text ?? "")
    }
    
    func prepareDatePreview(_ date: String) {
        var dateOnCard = ""
        for i in 0..<5 {
            if let character = date.asciiAt(i) {
                dateOnCard += character
            } else {
                if i == 2 {
                    dateOnCard += "/"
                } else {
                    dateOnCard += "•"
                }
            }
        }
        
        cardView.cardDate.text = dateOnCard
    }
    
    @objc func reformatCVV(textField: UITextField) {
        var formattedCVV = ""
        let cardType = cardView.type;
        if let text = textField.text {
            var dummy = 0
            formattedCVV = CardUtil.removeNonDigits(string: text, andPreserveCursorPosition: &dummy)
        }
        
        if formattedCVV.count > cardType.maxCVVDigits() {
            textField.text = previousCVVTextFieldContent
            textField.undoManager?.removeAllActions()
            return
        }
        
        textField.text = formattedCVV
        prepareCVVpreview(formattedCVV)
    }
    
    func prepareCVVpreview(_ cvv: String) {
        var cvvPreview = ""
        for _ in 0..<cvv.count {
            cvvPreview.append("•")
        }
        
        cardView.cardRearCVV.text = cvvPreview
    }
    
    @objc func reformatCardHolder(textField: UITextField) {
        let formattedCardHolder = CardUtil.formattedCardHolder(textField.text ?? "")
        if formattedCardHolder.count > 40 {
            textField.text = previousCardHolderNameFieldContent
            textField.undoManager?.removeAllActions()
            return
        }
        
        textField.text = formattedCardHolder
        prepareCardHolderPreview(formattedCardHolder)
    }
    
    func prepareCardHolderPreview(_ cardHolder: String) {
        cardView.cardName.text = cardHolder
    }
    
    func determineCardTypeFromPAN(_ pan: String) {
        if isWebViewReady {
            webView.evalJSSafe("getCardType(\"\(pan)\")") { [weak self] result, error in
                guard let self = self else { return }
                if let _ = error {
                    self.cardView.type = .unknown
                    return
                }
                
                self.cardView.type = CardType.init(rawValue: result as? String ?? "") ?? .unknown
            }
        }
    }
    
    func focusOnFirstInvalidField() {
        if !panContainer.isValid {
            panTextField.becomeFirstResponder()
            return
        }
        
        if !expirationDateContainer.isValid {
            expirationDateTextField.becomeFirstResponder()
            return
        }
        
        if !cvvContainer.isValid {
            cvvTextField.becomeFirstResponder()
            return
        }
        
        if !cardHolderNameContainer.isValid {
            cardHolderNameTextField.becomeFirstResponder()
            return
        }
    }
    
    func isCardDataValidQuick(_ updateUI: Bool) -> Bool {
        if updateUI {
            resetTextFieldValidation()
        }
        
        var isValid = true
        if !CardValidation.isPanValid(cardView.cardPan.text ?? "", cardType: cardView.type) {
            if updateUI {
                panContainer.isValid = false
            }
            isValid = false
        }
        
        if !CardValidation.isExpirationValid(expirationDateTextField.text ?? "") {
            if updateUI {
                expirationDateContainer.isValid = false
            }
            isValid = false
        }
        
        if !CardValidation.isCVVValid(cvvTextField.text ?? "", cardType: cardView.type) {
            if updateUI {
                cvvContainer.isValid = false
            }
            isValid = false
        }
        
        if !CardValidation.isCardHolderValid(cardHolderNameTextField.text ?? "") {
            if updateUI {
                cardHolderNameContainer.isValid = false
            }
            isValid = false
        }
        
        return isValid
    }
    
    
    func isCardDataValid(_ updateUI: Bool, result: @escaping (Bool) -> Void) {
        if !isCardDataValidQuick(updateUI) {
            result(false)
            return
        }
        
        webView.evalJSSafe(
            "validatePan(\"\(cardView.cardPan.text?.removeNonDigits() ?? "")\", {})"
        ) { [weak self] value, error in
            guard let self = self else { return }
            let updateForValid: (Bool) -> Void = { isValid in
                self.panContainer.isValid = isValid
                if !isValid {
                    self.updateTitleForInvalidCard()
                }
                
                self.focusOnFirstInvalidField()
            }
            
            if let error = error {
                self.log.e("JS Error while calling validatePan (\(error))")
                if updateUI {
                    updateForValid(false)
                }
                
                result(false)
                return
            }
            
            guard
                let errorCount = value as? Int
            else {
                self.log.e("JS Error while casting result of validatePan")
                if updateUI {
                    updateForValid(false)
                }
                result(false)
                return
            }
            
            if updateUI {
                updateForValid(errorCount == 0)
            }
            
            result(errorCount == 0)
        }
    }
    
    private func updateUIFor3DSWebViewURL(_ url: URL?) {
        if url?.scheme != "about" {
            log.i("WebView moving to URL: \(url?.absoluteString ?? "")")
        }
        
        if
            url?.path.starts(with: ApiPath.success3DS.rawValue) == true ||
                url?.path.starts(with: ApiPath.fail3DS.rawValue) == true
        {
            state = .payment3DSResponded
        }
    }
    
    func prepareInteractions() {
        panTextField.addTarget(self, action: #selector(reformatAsCardNumber), for: .editingChanged)
        expirationDateTextField.addTarget(self, action: #selector(reformatExpirationDate), for: .editingChanged)
        cvvTextField.addTarget(self, action: #selector(reformatCVV), for: .editingChanged)
        cardHolderNameTextField.addTarget(self, action: #selector(reformatCardHolder), for: .editingChanged)
        bottomButton.addAction(for: .touchUpInside) { [weak self] in
            self?.bottomButtonPressed()
        }
        
        cvvTextField.delegate = self
    }
    
    func bottomButtonPressed() {
        switch state {
        case .idle, .userCards, .cardEntry, .contactingAPI, .payment3DS, .payment3DSResponded, .payment3DSCompleted:
            break
        case .success:
            dismiss(animated: true)
        case .failure, .error(_):
            reset()
        }
    }
    
    func reset() {
        state = .idle
        
        resetTextFieldValidation()
        resetTextFields()
        resetCard()
    }
    
    func resetTextFieldValidation() {
        panContainer.isValid = true
        cvvContainer.isValid = true
        expirationDateContainer.isValid = true
        cardHolderNameContainer.isValid = true
    }
    
    func resetTextFields() {
        panTextField.text = ""
        cvvTextField.text = ""
        expirationDateTextField.text = ""
        cardHolderNameTextField.text = ""
    }
    
    func resetCard() {
        updatePanPreview("", groups: [ 4, 4, 4, 4 ])
        prepareCVVpreview("")
        prepareDatePreview("")
        prepareCardHolderPreview("")
        
        cardView.type = .unknown
    }
    
    func htmlFromJs(_ js: String) -> String {
        return """
<html><head></head><body>
<script>
\(js)
</script>
</body>
"""
    }
    
    func submit(_ card: Card) {
        if card.pan != nil {
            encryptCardData(card) { [weak self] data in
                guard let self = self else {
                    return
                }
                
                guard let data = data else {
                    self.log.e("Error encrypting data via JS (empty data)")
                    return
                }
                
                self.submitPaymentToServer(cardEncData: data, cardType: card.card_type)
            }
        } else if let token = card.token {
            self.submitPaymentToServer(cardToken: token, cardType: card.card_type)
        } else {
            state = .error(.cardNoPanOrToken)
        }
    }
    
    func userCardsState() {
        showInstallments(false)
        if self.sdk.jsCode?.isEmpty != false {
            self.sdk.retrieveJS()
        }
        
        if self.sdk.userCards.isEmpty {
            self.sdk.retrieveUserCards()
        } else {
            userCardsView.populateWithCards(self.sdk.userCards, acquirer: sdk.settings?.acquirer)
        }
        prepareInstallments()
        pauseScrolling(true)
        userCardsView.fadeIn()
        cardContainer.isHidden = false
        scrollView.fadeOut()
        cardInfoStack.fadeOut()
        self.setLoading(false)
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeOut()
    }
    
    func userCardsStateLoading() {
        showInstallments(false)
        pauseScrolling(true)
        userCardsView.fadeOut()
        cardContainer.isHidden = true
        scrollView.fadeOut()
        cardInfoStack.fadeOut()
        self.setLoading(true, reason: NSLocalizedString(" Preparing payment...", comment: ""))
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeOut()
    }
    
    func cardEntryState() {
        updateTitleForInvalidCard()
        
        prepareInstallments()
        pauseScrolling(false)
        userCardsView.fadeOut()
        cardContainer.isHidden = false
        scrollView.fadeIn()
        cardInfoStack.fadeIn()
        self.setLoading(false)
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeOut()
        
        DispatchQueue.main.async { [weak self] in
            self?.panTextField.becomeFirstResponder()
        }
    }
    
    func contactingAPIState() {
        showInstallments(false)
        cardView.maskPan()
        titleLabel.text = NSLocalizedString("Completing payment...", comment: "")
        titleImage.isHidden = true
        
        pauseScrolling(true)
        userCardsView.fadeOut()
        cardContainer.isHidden = false
        scrollView.fadeIn()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ [weak self] in
            self?.userCardsView.fadeOut()
        }
        cardInfoStack.fadeOut()
        self.setLoading(true)
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeOut()
    }
    
    func payment3DSState() {
        showInstallments(false)
        updateTitleForValidCard()
        
        pauseScrolling(true)
        userCardsView.fadeOut()
        cardContainer.isHidden = false
        scrollView.fadeOut()
        cardInfoStack.fadeOut()
        self.setLoading(false)
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeIn()
    }
    
    func payment3DSRespondedState() {
        showInstallments(false)
        pauseScrolling(true)
        userCardsView.fadeOut()
        cardContainer.isHidden = false
        scrollView.fadeOut()
        cardInfoStack.fadeOut()
        self.setLoading(false)
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeOut()
    }
    
    func payment3DSCompleted() {
        showInstallments(false)
        pauseScrolling(true)
        userCardsView.fadeOut()
        cardContainer.isHidden = false
        scrollView.fadeOut()
        cardInfoStack.fadeIn()
        self.setLoading(false)
        resultContainer.fadeOut()
        bottomButton.fadeOut()
        webViewContainer.fadeOut()
        
        paymentFlowDidCompleteSuccessfully()
    }
    
    func successState(transaction: TransactionInternal?) {
        showInstallments(false)
        
        var message = ""
        //        #if DEBUG
        if let transactionId = transaction?.TxId {
            message = String(format: NSLocalizedString("\nTransaction id: (%@)", comment: ""), transactionId)
        }
        //        #endif
        titleLabel.text = NSLocalizedString("Your payment was successful!\(message)", comment: "")
        titleImage.isHidden = true
        bottomButton.setTitle(NSLocalizedString("Back to shop", comment: ""), for: .normal)
        
        Animations.prepareSuccessAnim(resultContainer)
        
        userCardsView.fadeOut()
        cardContainer.isHidden = false
        scrollView.fadeIn()
        cardInfoStack.fadeOut()
        self.setLoading(false)
        resultContainer.fadeIn()
        bottomButton.fadeIn()
        webViewContainer.fadeOut()
    }
    
    func failureState(transaction: TransactionInternal?) {
        showInstallments(false)
        var message = ""
        //        #if DEBUG
        if let error = transaction?.Description {
            message = String(format: NSLocalizedString("\nError: (%@)", comment: ""), error)
        }
        //        #endif
        titleLabel.text = NSLocalizedString("Payment failed\(message)", comment: "")
        titleImage.isHidden = true
        bottomButton.setTitle(NSLocalizedString("Retry", comment: ""), for: .normal)
        
        Animations.prepareErrorAnim(resultContainer)
        
        userCardsView.fadeOut()
        cardContainer.isHidden = true
        scrollView.fadeIn()
        cardInfoStack.fadeOut()
        self.setLoading(false)
        resultContainer.fadeIn()
        bottomButton.fadeIn()
        webViewContainer.fadeOut()
    }
    
    private func errorState(_ error: ErrorState) {
        showInstallments(false)
        titleLabel.text = error.message
        
        titleImage.isHidden = true
        bottomButton.setTitle(NSLocalizedString("Retry", comment: ""), for: .normal)
        
        Animations.prepareErrorAnim(resultContainer)
        
        userCardsView.fadeOut()
        cardContainer.isHidden = true
        scrollView.fadeIn()
        cardInfoStack.fadeOut()
        self.setLoading(false)
        resultContainer.fadeIn()
        bottomButton.fadeIn()
        webViewContainer.fadeOut()
    }
    
    func submitPaymentToServer(cardEncData: String, cardType: CardType) {
        state = .contactingAPI
        sdk.pay(cardEncData: cardEncData, cardType: cardType) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success3DS(let html3DS):
                self.show3DS(html3DS)
            case .successNo3DS(let transaction):
                self.completePaymentWithTransaction(transaction)
            case .failure(let error):
                self.state = .error(.sdkAPI(error))
            }
        }
    }
    
    func submitPaymentToServer(cardToken: String, cardType: CardType) {
        state = .contactingAPI
        sdk.pay(cardToken: cardToken, cardType: cardType) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success3DS(let html3DS):
                self.show3DS(html3DS)
            case .successNo3DS(let transaction):
                self.completePaymentWithTransaction(transaction)
            case .failure(let error):
                self.state = .error(.sdkAPI(error))
            }
        }
    }
    
    func show3DS(_ html3DS: String) {
        state = .payment3DS
        DispatchQueue.main.async { [weak self] in
            self?.webView.loadHTMLString(html3DS.properHtmlStructure(), baseURL: nil)
        }
    }
    
    func encryptCardData(_ card: Card, completion: @escaping (String?) -> Void) {
        webView.evalJSSafe(
            "encryptCardData(\"\(card.pan ?? "")\", \"\(card.expiry_year)\", \"\(card.expiry_month)\", \"\(card.cvv ?? "")\", \"\(card.cardholder_name ?? "")\", true, true)"
        ) { [weak self] dict, error in
            guard let self = self else { return }
            if error != nil {
                self.log.e("JS Error while encrypting card data (\(error?.localizedDescription ?? "unknown error"))")
                completion(nil)
                return
            }
            
            guard
                let dict = dict as? [String: Any],
                let cardEncData = dict["cardEncData"] as? String,
                !cardEncData.isEmpty,
                (dict["errorExpiryMonth"] as? String)?.isEmpty != false,
                (dict["errorExpiryYear"] as? String)?.isEmpty != false,
                (dict["errorCvv2"] as? String)?.isEmpty != false,
                (dict["errorHolderName"] as? String)?.isEmpty != false,
                (dict["errorCardEncData"] as? String)?.isEmpty != false,
                (dict["errorDebug"] as? String)?.isEmpty != false,
                (dict["errorPan"] as? String)?.isEmpty != false
            else {
                self.log.e("JS Error while encrypting cardEncData dict: \(dict ?? [])")
                completion(nil)
                return
            }
            
            completion(cardEncData)
        }
    }
    
    func paymentFlowDidCompleteSuccessfully() {
        webView.transactionFromContent(type: PaymentResponse.self) { [weak self] transaction in
            guard let self = self else { return }
            guard let response = transaction else {
                self.log.e("Error while transforming response from server success page via JS")
                self.state = .error(.response3DSJavaScriptError)
                return
            }
                                
            self.completePaymentWithTransaction(response.transaction)
        }
    }
    
    func updateTitleIsValid() -> Bool {
        if !isCardDataValidQuick(false) {
            updateTitleForInvalidCard()
            return false
        }
        
        if panContainer.isValid {
            updateTitleForValidCard()
        } else {
            updateTitleForInvalidCard()
        }
        
        return true
    }
    
    func updateTitleForValidCard() {
        titleLabel.text = NSLocalizedString("Proceed with payment", comment: "")
    }
    
    func updateTitleForInvalidCard() {
        titleLabel.text = NSLocalizedString("Please enter a valid card", comment: "")
        titleImage.isHidden = true
    }
    
    func completePaymentWithTransaction(_ transaction: TransactionInternal?) {
        guard
            let status = transaction?.Status
        else {
            state = .error(.noTransactionStatusAvailable)
            return
        }
        
        switch status {
        case .AUTHORIZED, .CAPTURED:
            log.e("PAYMENT SUCCESS - transaction: \(transaction.debugDescription)")
            state = .success(transaction)
        case .REFUSED, .REFUSEDRISK, .CANCELED, .ERROR:
            log.e("PAYMENT FAILURE - transaction: \(transaction.debugDescription)")
            state = .failure(transaction)
        }
    }
    
    func scrollToTop() {
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    func pauseScrolling(_ shouldPause: Bool) {
        scrollView.isScrollEnabled = !shouldPause
    }
}

extension CardPaymentViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isWebViewReady = true
        if state == .payment3DS {
            webView.fixScaleViaJS()
        }
        
        if
            state == .payment3DSResponded,
            webView.url?.path.starts(with: ApiPath.success3DS.rawValue) == true
        {
            self.state = .payment3DSCompleted
        }
        
        if webView.url?.path.starts(with: ApiPath.fail3DS.rawValue) == true {
            self.state = .failure(nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        log.e("WebView: Did fail provisional navigation. Error \(error)")
        if state == .payment3DS {
            state = .error(.server3DS(error))
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        updateUIFor3DSWebViewURL(navigationAction.request.url)
        decisionHandler(.allow)
    }
}

extension CardPaymentViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == cvvTextField {
            cardView.side = .rear
        } else {
            cardView.side = .front
        }
        
        var isImageHidden = true
        if textField == cardView.cardPan {
            titleLabel.text = NSLocalizedString("Enter your card number", comment: "")
        } else if textField == expirationDateTextField {
            titleLabel.text = NSLocalizedString("Enter the expiration date", comment: "")
        } else if textField == cvvTextField {
            titleLabel.text = NSLocalizedString("Enter CVV", comment: "")
        } else if textField == cardHolderNameTextField {
            titleLabel.text = NSLocalizedString("Enter cardholder's name", comment: "")
        } else {
            isImageHidden = updateTitleIsValid()
        }
        
        titleImage.isHidden = isImageHidden
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var isImageHidden = true
        if textField == cvvTextField {
            cardView.side = .front
        } else if textField == cardHolderNameTextField {
            isImageHidden = updateTitleIsValid()
        }
        
        titleImage.isHidden = isImageHidden
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == panTextField {
            expirationDateTextField.becomeFirstResponder()
        } else if textField == expirationDateTextField {
            cvvTextField.becomeFirstResponder()
        } else if textField == cvvTextField {
            cardHolderNameTextField.becomeFirstResponder()
        } else if textField == cardHolderNameTextField {
            view.endEditing(true)
            titleImage.isHidden = updateTitleIsValid()
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == panTextField {
            previousPanTextFieldContent = textField.text
            previousPanTextSelection = textField.selectedTextRange
        } else if textField == expirationDateTextField {
            previousDateTextFieldContent = textField.text
            previousDateTextSelection = textField.selectedTextRange
        } else if textField == cvvTextField {
            previousCVVTextFieldContent = textField.text
        } else if textField == cardHolderNameTextField {
            previousCardHolderNameFieldContent = textField.text
        }
        
        return true
    }
}

extension CardPaymentViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return installmentVariationsForPaymentAmount().count
    }
}

extension CardPaymentViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let variations = installmentVariationsForPaymentAmount()
        if variations.count <= row {
            return nil
        }
        
        let variation = variations[row]
        return installmentsText(variation.installments ?? 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let variations = installmentVariationsForPaymentAmount()
        if variations.count <= row {
            return
        }
        
        sdk.payment?.installments = UInt(variations[row].installments ?? 0)
        updateInstallmentsSelection(pickerView: pickerView)
        toggleInstallments()
    }
}

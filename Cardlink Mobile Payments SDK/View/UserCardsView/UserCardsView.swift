//
//  UserCardsView.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 1/12/22.
//

import Lottie
import UIKit

class UserCardsView: UIView {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var cardsContainer: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var acquirerLogo: UIImageView!
    @IBOutlet weak var installmentsView: UIView!
    
    @IBOutlet weak var installmentsSelectionLabel: UILabel!
    
    var sdk: CardlinkSDK!
    
    private var cards: [Card] = []
    private var cardViews: [CardView] = []
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        initialize()
    }
    
    private let addCardCellId = "addCard"
    private let cardCellId = "card"
    
    // Returns height of main view's card
    var proceedCallback: ((Card?) -> CGFloat?)? = nil
    
    private var selectedToken = ""
    private var isInitialized = false
    private static let CARDS_TO_DISPLAY = 3

    func initialize() {
        if isInitialized {
            return
        }
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardsContainer.addGestureRecognizer(tapGR)
        
        titleLabel.text = NSLocalizedString("Please wait...", comment: "")
        tableView.rowHeight = 48
        tableView.register(UINib(nibName: "CardCell", bundle: Bundle(for: type(of: self))), forCellReuseIdentifier: cardCellId)
        tableView.register(UINib(nibName: "AddCardCell", bundle: Bundle(for: type(of: self))), forCellReuseIdentifier: addCardCellId)
        tableView.backgroundView = nil
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        
        installmentsView.layer.borderWidth = 2
        installmentsView.layer.borderColor = UIColor(red: 185/255, green: 185/255, blue: 185/255, alpha: 1).cgColor
        installmentsView.layer.cornerRadius = 12
        installmentsView.isHidden = true
        let installementsTap = UITapGestureRecognizer(target: self, action: #selector(setupInstallmentsPicker))
        installmentsView.addGestureRecognizer(installementsTap)

    }
    
    @objc
    private func setupInstallmentsPicker() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let overlay = UIView(frame: CGRect(x: .zero, y: .zero, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        // installmentsOverlay = overlay
        overlay.alpha = 0
        overlay.backgroundColor = UIColor(white: 0, alpha: 0.1)
        overlay.addToContainer(window)
        
        UIView.animate(withDuration: 0.3, animations: {
            overlay.alpha = 1
        })

        let installmentsPickerView = UIPickerView()
        installmentsPickerView.backgroundColor = .white
        installmentsPickerView.delegate = self
        installmentsPickerView.dataSource = self
        installmentsPickerView.translatesAutoresizingMaskIntoConstraints = false
        
        overlay.addSubview(installmentsPickerView)
        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(removePicker(sender:)))
        overlay.addGestureRecognizer(overlayTap)
        
        
        installmentsPickerView.leadingAnchor.constraint(equalTo: overlay.leadingAnchor).isActive = true
        installmentsPickerView.trailingAnchor.constraint(equalTo: overlay.trailingAnchor).isActive = true
        installmentsPickerView.bottomAnchor.constraint(equalTo: overlay.bottomAnchor).isActive = true
        updateInstallmentsSelection(pickerView: installmentsPickerView)
    }
    
    @objc func removePicker(sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }

    func cardsToDisplay() -> [Card] {
        return Array(cards.prefix(Self.CARDS_TO_DISPLAY))
    }
    
    func showInstallments() {
        installmentsView.isHidden = false
    }
    
    func populateWithCards(_ cards: [Card], acquirer: Acquirer?) {
        titleLabel.text = String(format: NSLocalizedString("You have %d saved cards", comment: ""), cards.count)
        titleLabel.alpha = 1
        cardViews.forEach { $0.removeFromSuperview() }
        
        self.cards = cards
        let topCards = cardsToDisplay()
        
        cardViews.forEach {
            $0.removeFromSuperview()
        }
        
        cardViews = []
        
        translatesAutoresizingMaskIntoConstraints = false
        
        var i = CGFloat(topCards.count - 1)
        
        var scale = 0.65 + CGFloat(Self.CARDS_TO_DISPLAY - topCards.count) * 0.08
        let cardVerticalOffset: CGFloat = bounds.height * 0.04
        
        for card in topCards.reversed() {
            let cardView = CardView.loadFromNib()
            cardsContainer.addSubview(cardView)
            cardView.translatesAutoresizingMaskIntoConstraints = false
            cardView.centerXAnchor.constraint(equalTo: cardsContainer.centerXAnchor).isActive = true
            
            cardView.transform = CGAffineTransformTranslate(
                CGAffineTransform(scaleX: scale, y: scale),
                0, cardVerticalOffset * i
            )
            cardView.topAnchor.constraint(equalTo: cardsContainer.topAnchor).isActive = true
            cardView.widthAnchor.constraint(equalTo: cardsContainer.widthAnchor).isActive = true
            scale += 0.08
            
            cardView.populateWithCard(card)
            cardView.enableShadow = true
            cardViews.append(cardView)
            i -= 1
        }
        
        cardViews.first?.bottomAnchor.constraint(equalTo: cardsContainer.bottomAnchor).isActive = true
        cardViews.reverse()
        tableView.reloadData()
        isUserInteractionEnabled = true
        
        if let image = acquirer?.smallImage() {
            acquirerLogo?.image = UIImage(
                named: image,
                in: Bundle(for: type(of: self)),
                compatibleWith: nil
            )
            acquirerLogo?.isHidden = false
        } else {
            acquirerLogo?.isHidden = true
        }
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
}

private extension UserCardsView {
    @IBAction
    func cardTapped() {
        guard let card = cards.first(where: { $0.token == selectedToken }) else {
            guard let card = cards.first else {
                return
            }
            
            didSelectCard(card)
            return
        }
        
        didSelectCard(card)
    }
    
    func didSelectCard(_ card: Card) {
        selectedToken = card.token ?? ""
        tableView.reloadData()
        isUserInteractionEnabled = false
        guard let cardView = cardViews.first(where: { $0.card?.token == selectedToken }) else {
            _ = proceedCallback?(card)
            return
        }
        
        let duration = 0.6
        if let height = proceedCallback?(card) {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
                let scale = height / cardView.bounds.size.height
                cardView.fadeOutShadow(duration)
                cardView.transform = CGAffineTransformTranslate(CGAffineTransform(scaleX: scale, y: scale), 0, 0)
                self.titleLabel.alpha = -1
                var i: CGFloat = 1.4
                for otherCardView in self.cardViews {
                    if otherCardView == cardView {
                        continue
                    }
                    
                    otherCardView.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
                    otherCardView.transform = CGAffineTransformRotate(
                        CGAffineTransformTranslate(otherCardView.transform, 0, 0),
                        0.4 * i
                    )
                    otherCardView.alpha = -1 * i
                    
                    i += 3
                }
                self.layoutIfNeeded()
            })
        }
    }
}

extension UserCardsView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Card
            let card = cards[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: cardCellId, for: indexPath) as! CardCell
            cell.cardImage.image = UIImage(
                named: card.card_type.imageSmall(),
                in: Bundle(for: type(of: self)),
                compatibleWith: nil
            )
            
            cell.cardType.text = card.card_type.name()
            cell.cardNumber.text = "•••• \(card.last4)"
            cell.checkImage.alpha = (!selectedToken.isEmpty && card.token == selectedToken) ? 1 : 0
            return cell
        }
        
        // Add card button
        let cell = tableView.dequeueReusableCell(withIdentifier: addCardCellId, for: indexPath)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 1
        }
        
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
}

extension UserCardsView: UITableViewDelegate {
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section != 0 || cards.count <= indexPath.row {
            return nil
        }
        
        let card = cards[indexPath.row]
        guard let token = card.token else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, _ in
            let alert = UIAlertController(
                title: NSLocalizedString("Deleting card...", comment: ""),
                message: "\n\n\n\n",
                preferredStyle: .alert
            )
            
            let indicator = UIActivityIndicatorView(frame: alert.view.bounds)
            indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            alert.view.addSubview(indicator)
            indicator.isUserInteractionEnabled = false
            indicator.startAnimating()
            //            let ok = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default)
            //            alert.addAction(ok)
            
            self?.sdk.deleteCard(token: token) { [weak self] result in
                self?.cards.remove(at: indexPath.row)
                self?.tableView.reloadData()
                alert.dismiss(animated: true)
            }
            
            self?.window?.rootViewController?.presentedViewController?.present(alert, animated: true)
        }
        
        deleteAction.image = UIImage(named: "ic_delete", in: Bundle(for: type(of: self)), compatibleWith: nil)
        deleteAction.backgroundColor = .white
        
        let config = UISwipeActionsConfiguration(actions: [ deleteAction ])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            _ = proceedCallback?(nil)
            return
        }
        
        if indexPath.row < cards.count {
            let card = cards[indexPath.row]
            didSelectCard(card)
        }
    }
}

extension UserCardsView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let variations = installmentVariationsForPaymentAmount()
        if variations.count <= row {
            return
        }
        
        sdk.payment?.installments = UInt(variations[row].installments ?? 0)
        updateInstallmentsSelection(pickerView: pickerView)

        pickerView.superview?.removeFromSuperview()
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let variations = installmentVariationsForPaymentAmount()
        if variations.count <= row {
            return nil
        }
        
        let variation = variations[row]
        return installmentsText(variation.installments ?? 1)
    }
}

extension UserCardsView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return installmentVariationsForPaymentAmount().count
    }
    
}

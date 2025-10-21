//
//  CardView.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 29/11/22.
//

import UIKit

class CardView: UIView {
    enum CardSide {
        case front
        case rear
    }
    
    @IBOutlet private weak var cardFront: UIView!
    @IBOutlet private weak var cardFrontColor: CornerRadiusPercentView!
    @IBOutlet private weak var cardFrontShadow: UIView!
    @IBOutlet weak var cardFrontGlare: UIImageView!
    @IBOutlet weak var cardFrontLogo: UIImageView!
    @IBOutlet weak var cardPan: UILabel!
    @IBOutlet weak var cardName: UILabel!
    @IBOutlet weak var cardDate: UILabel!
    
    @IBOutlet private weak var cardRear: UIView!
    @IBOutlet weak var cardRearGlare: UIImageView!
    @IBOutlet private weak var cardRearColor: UIView!
    @IBOutlet private weak var cardRearShadow: UIView!
    @IBOutlet weak var cardRearCVV: UILabel!
    @IBOutlet weak var cardRearLogo: UIImageView!
    
    var side: CardSide = .front {
        didSet {
            if oldValue == side {
                return
            }
            
            performCardSideAnimation()
        }
    }
    
    var type: CardType = .unknown {
        didSet {
            if (type == oldValue) {
                return
            }
            
            cardFrontLogo.image = UIImage(named: type.image(), in: Bundle(for: CardlinkSDK.self), compatibleWith: nil)
            cardRearLogo.image = UIImage(named: "\(type.image())_r", in: Bundle(for: CardlinkSDK.self), compatibleWith: nil)
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn]) {
                self.updateColor()
            }
        }
    }
    
    var enableShadow: Bool = false {
        didSet {
            cardFrontColor.showShadow = enableShadow
        }
    }
    
    func fadeOutShadow(_ duration: CGFloat) {
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = cardFrontColor.layer.shadowOpacity
        animation.toValue = 0.0
        animation.duration = duration
        cardFrontColor.layer.add(animation, forKey: animation.keyPath)
        cardFrontColor.layer.shadowOpacity = 0.0
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        initialize()
    }
    
    var card: Card? = nil
    func populateWithCard(_ card: Card) {
        self.card = card
        type = card.card_type
        cardName.text = ""
        cardPan.text = "•••• •••• •••• \(card.last4)"
        cardDate.text = "\(String(card.expiry_month).suffix(2))/\(String(card.expiry_year).suffix(2))"
    }
    
    func maskPan() {
        let pan = cardPan.text ?? ""
        var maskedPan = ""
        var i = 0
        let unmaskAfter = pan.count - 4
        for character in pan {
            if character == " " {
                maskedPan += " "
            } else {
                maskedPan += i >= unmaskAfter
                ? String(character)
                : "•"
            }
            
            i += 1
        }
        
        cardPan.text = maskedPan
    }

    private var isInitialized = false
    
    private var displayLink: CADisplayLink?
    private var start: CFAbsoluteTime?
    private var duration: CFAbsoluteTime = 0.6
    private var flipProgress: CGFloat = 0
    
    private let c1: Double = 1.1
    private let c2: Double = 1.9
}

private extension CardView {
    func initialize() {
        if isInitialized {
            return
        }
        
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 900.0
        cardFront.superview?.layer.sublayerTransform = transform
        
        cardFrontShadow.layer.zPosition = 1000
        cardRearShadow.layer.zPosition = 1000
        
        cardFrontColor.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        cardFrontColor.layer.borderWidth = 1 / UIScreen.main.scale
        cardRearColor.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
        cardRearColor.layer.borderWidth = 1 / UIScreen.main.scale
        
        performMoveAnimationOnLayer(cardFrontGlare.layer, progress: 0, scaleProgress: 1)
        performMoveAnimationOnLayer(cardRearGlare.layer, progress: 0, scaleProgress: 1)
        
        updateColor()
        
        isInitialized = true
    }
    
    func updateColor() {
        let color = self.type.color()
        self.cardFrontColor.backgroundColor = color
        self.cardRearColor.backgroundColor = color
    }
    
    func performCardSideAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(self.handleDisplayLink(_:)))
    
        let now = CFAbsoluteTimeGetCurrent()
        var elapsed = max(0, now - (start ?? now))
        if start == nil || elapsed > duration {
            elapsed = 0
        } else {
            elapsed = duration - elapsed
        }
        
        start = now - elapsed
        displayLink?.add(to: .main, forMode: .common)
    }
        
    func ease(_ x: Double) -> Double {
        return x < 0.5
          ? (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
          : (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2;
    }
    
    @objc
    func handleDisplayLink(_ displayLink: CADisplayLink) {
        let elapsed = CFAbsoluteTimeGetCurrent() - start!
        flipProgress = side == .rear
        ? elapsed / duration
        : 1 - elapsed / duration
        
        if (elapsed >= duration) {
            displayLink.invalidate()
            self.displayLink = nil
            flipProgress = max(min(flipProgress, 1), 0)
        }
        
        flipProgress = ease(flipProgress)
        
        let isFront = flipProgress <= 0.5
        cardFront.isHidden = !isFront
        cardRear.isHidden = isFront
        
        let circularProgress = sin(flipProgress * .pi)
        let alphaProgress = circularProgress * 0.7
        let angleProgress = .pi * flipProgress
        let scaleProgress = 1 - circularProgress * 0.1
        
        if isFront {
            cardFrontShadow.alpha = alphaProgress
            performFlipAnimationOnLayer(cardFront.layer, progress: angleProgress, scaleProgress: scaleProgress)
            performMoveAnimationOnLayer(cardFrontGlare.layer, progress: angleProgress, scaleProgress: scaleProgress)
        } else {
            cardRearShadow.alpha = alphaProgress
            performFlipAnimationOnLayer(cardRear.layer, progress: angleProgress + .pi, scaleProgress: scaleProgress)
            performMoveAnimationOnLayer(cardRearGlare.layer, progress: angleProgress - .pi, scaleProgress: scaleProgress)
        }
    }
    
    func performFlipAnimationOnLayer(_ layer: CALayer, progress: CGFloat, scaleProgress: CGFloat) {
        layer.transform = CATransform3DScale(
            CATransform3DMakeRotation(progress, 0, 1, 0),
            scaleProgress, scaleProgress, scaleProgress
        )
    }
    
    func performMoveAnimationOnLayer(_ layer: CALayer, progress: CGFloat, scaleProgress: CGFloat) {
        layer.zPosition = 50
        layer.transform = CATransform3DScale(
            CATransform3DRotate(CATransform3DMakeTranslation(progress * layer.bounds.width, 0, 0), progress, 0, 1, 0),
            scaleProgress * 2, scaleProgress, scaleProgress
        )
    }
}

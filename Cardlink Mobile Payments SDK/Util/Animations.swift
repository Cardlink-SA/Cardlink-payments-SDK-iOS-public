//
//  Animations.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 1/12/22.
//

import Lottie

class Animations {
    static func prepareLoaderAnim(_ view: AnimationView) {
        view.animation = Animation.named("anim_loader", bundle: Bundle.init(for: CardlinkSDK.self))
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.animationSpeed = 2.5
        view.play()
    }
    
    static func prepareSuccessAnim(_ view: AnimationContainer) {
        view.widthConstraint.constant = 76
        view.layoutIfNeeded()
        view.animationView.animation = Animation.named("anim_ok", bundle: Bundle.init(for: CardlinkSDK.self))
        view.animationView.contentMode = .scaleToFill
        view.animationView.loopMode = .playOnce
        view.animationView.play()
    }
    
    static func prepareErrorAnim(_ view: AnimationContainer) {
        view.widthConstraint.constant = 84
        view.layoutIfNeeded()
        view.animationView.animation = Animation.named("anim_error", bundle: Bundle.init(for: CardlinkSDK.self))
        view.animationView.contentMode = .scaleAspectFit
        view.animationView.loopMode = .playOnce
        view.animationView.play()
    }
}

//
//  ViewControllerBase.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 18/9/22.
//  Copyright © 2022 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

class ViewControllerBase: UIViewController {
    @IBOutlet private weak var acquirerLogo: UIImageView?
    @IBOutlet private weak var backgroundView: UIView?
    
    private var _sdk: CardlinkSDK? = nil
    var sdk: CardlinkSDK {
        get {
            return _sdk!
        }
    }
    
    var module: LibraryModule {
        get {
            return _sdk!.module
        }
    }
    
    lazy var log = sdk.module.log
    
    var didAppearDueToCancelledSwipeToGoBack = false
    var isBeingPopped = false
    
    private var isFirstAppearance = true
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isBeingPopped = true
        didAppearDueToCancelledSwipeToGoBack = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isBeingPopped = false

        if !isFirstAppearance && !didAppearDueToCancelledSwipeToGoBack {
            isSwipeToGoBackEnabled = previousSwipeToGoBackStatus
        }

        isFirstAppearance = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareAcquirer()
        UIViewController.attemptRotationToDeviceOrientation()

        setNeedsStatusBarAppearanceUpdate()
        if isFirstAppearance {
            // This is where the `navigationController` will have become available
            // therefore the `SwipeBack` Pod setting must be set on it.
            updateSwipeToGoBackStatus()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didAppearDueToCancelledSwipeToGoBack = false

        previousSwipeToGoBackStatus = isSwipeToGoBackEnabled
    }

    func prepareAcquirer() {
        if let image = sdk.settings?.acquirer?.smallImage() {
            acquirerLogo?.image = UIImage(
                named: image,
                in: Bundle(for: type(of: self)),
                compatibleWith: nil
            )
            acquirerLogo?.isHidden = false
        } else {
            acquirerLogo?.isHidden = true
        }

        DispatchQueue.main.async {
            self.backgroundView?.backgroundColor = self.sdk.settings?.acquirer?.color() ?? UIColor.gray
            (self.parent?.parent as? ViewControllerBase)?.backgroundView?.backgroundColor = self.sdk.settings?.acquirer?.color() ?? UIColor.gray
        }
    }
    
    deinit {
        log.i("\(type(of: self)) dismissed.")
    }

    var timeInitialized: TimeInterval?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    func initialize() {
        #if DEBUG
        timeInitialized = Date().timeIntervalSince1970
        #endif
        hidesBottomBarWhenPushed = true
    }

    private var isSwipeToGoBackEnabled = true {
        didSet {
            updateSwipeToGoBackStatus()
        }
    }

    func updateSwipeToGoBackStatus() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = isSwipeToGoBackEnabled
    }

    /// Enables or disables the swipe-to-go-back gesture.
    ///
    /// - Parameter enabled
    /// - Note: This method sets the status **only for the current controller**.
    ///            When a new controller is presented its status will always be the
    ///            default one (currently true).
    ///
    ///            When this user returns to this controller again, its status will
    ///            be restored to this setting.
    func enableSwipeToGoBack(_ enabled: Bool) {
        isSwipeToGoBackEnabled = enabled
    }

    private var previousSwipeToGoBackStatus: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()

        removeBackButtonTitle()

        isSwipeToGoBackEnabled = true
    }

    @objc func goBack() {
    }

    func removeBackButtonTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }

    func wasNewControllerJustPushed() -> Bool {
        guard let vcs = navigationController?.viewControllers else {
            return false
        }

        let count = vcs.count
        return count > 1 && vcs[count - 2] == self
    }

    /// This is required for iOS 13 onwards, when presenting view controllers.
    /// The default presentation style has been changed, and if this is left unchanged, users will have the ability to swipe down
    /// to go to the previous screen.
    override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            return .fullScreen
        }
        set {
            super.modalPresentationStyle = newValue
        }
    }

    required init(bundle nibBundleOrNil: Bundle?) {
        let identifier = String(describing: Self.self)
        super.init(nibName: identifier, bundle: nibBundleOrNil)
    }
    
    class func loadFromNib(sdk: CardlinkSDK) -> Self {
        let vc = Self.init(bundle: Bundle(for: Self.self))
        vc._sdk = sdk
        return vc
    }
}

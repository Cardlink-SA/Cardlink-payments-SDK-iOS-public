//
//  MainViewController.swift
//  Cardlink Mobile Payments SDK
//
//  Created by Manolis Katsifarakis on 23/11/22.
//

import Lottie
import UIKit
import WebKit

class MainViewController: ViewControllerBase {
    @IBOutlet weak var navBar: NavbarView!
    
    @IBOutlet private weak var cartTotalTitleLabel: UILabel!
    @IBOutlet private weak var cartTotalLabel: UILabel!
    
    @IBOutlet private weak var content: RoundedCornersView!
    @IBOutlet private weak var container: UIView!
    
    @IBOutlet private weak var contractCartConstraint: NSLayoutConstraint!
    
    private var navController: UINavigationController!
    
    override func viewDidLoad() {
        content.roundedCorners = [.topLeft, .topRight]
        cartTotalLabel.text = "\(sdk.payment?.amountString() ?? "0\(Locale.current.decimalSeparator ?? ".")0")"
        
        prepareLiterals()
        prepareNavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBar.showLeftButton = true
    }
}

private extension MainViewController {
    func prepareLiterals() {
        navBar.title = NSLocalizedString("Payment", comment: "")
        cartTotalTitleLabel.text = NSLocalizedString("Cart total", comment: "")
    }
    
    func prepareNavigation() {
        navController = UINavigationController(rootViewController: paymentMethodsController())
        navController.view.backgroundColor = .white
        navController.setNavigationBarHidden(true, animated: false)
        
        navBar?.leftButton.addTarget(self, action: #selector(navBackPressed), for: .touchUpInside)
        setNestedViewController(navController)
        updateNav()
    }
    
    @objc func navBackPressed() {
        if (navController.viewControllers.count > 1 && sdk.settings?.accepted_payment_methods?.count ?? 0 > 1) {
            popController()
            return;
        }
        
        dismiss(animated: true)
    }
    
    func setNavButtonImage(named: String) {
        navBar?.leftButton.setImage(
            UIImage(
                named: named,
                in: Bundle(for: type(of: self)),
                compatibleWith: nil
            ),
            for: .normal
        )
    }
    
    func setCloseButton() {
        setNavButtonImage(named: "ic_close")
    }
    
    func setBackButton() {
        setNavButtonImage(named: "ic_back")
    }
    
    func updateNav() {
        if (navController.viewControllers.count > 1) {
            if (sdk.settings?.accepted_payment_methods?.count ?? 0) < 2 {
                setCloseButton()
                return
            }
            
            setBackButton()
        } else {
            setCloseButton()
        }
    }
    
    func paymentMethodsController() -> UIViewController {
        let vc = SelectMethodViewController.loadFromNib(sdk: sdk)
        vc.selectCallback = { [weak self] method, animated in
            switch (method) {
            case .card:
                self?.showCardPayment(animated)
            case .iris:
                self?.showIrisPayment(animated)
            case .paypal:
                self?.showPaypalPayment(animated)
            case .unknown:
                break
            }
        }
        
        return vc
    }
    
    func popController() {
        navController.popViewController(animated: true)
        updateNav()
    }
    
    func pushController(_ vc: UIViewController, animated: Bool) {
        navController.pushViewController(vc, animated: animated)
        updateNav()
    }
    
    func showCardPayment(_ animated: Bool) {
        pushController(CardPaymentViewController.loadFromNib(sdk: sdk), animated: animated)
    }
    
    func showIrisPayment(_ animated: Bool) {
        let vc = WebPaymentViewController.loadFromNib(sdk: sdk)
        vc.paymentType = .iris
        pushController(vc, animated: animated)
    }
    
    func showPaypalPayment(_ animated: Bool) {
        let vc = WebPaymentViewController.loadFromNib(sdk: sdk)
        vc.paymentType = .paypal
        pushController(vc, animated: animated)
    }
    
    func setNestedViewController(_ vc: UIViewController) {
        removeCurrentNestedView()
        
        addChild(vc)
        vc.view.addToContainer(container)
        vc.didMove(toParent: self)
    }
    
    func removeCurrentNestedView() {
        guard let vc = children.first else { return }
        
        vc.willMove(toParent: nil)
        vc.removeFromParent()
        vc.view.removeFromSuperview()
    }
    
    // Unused
    func contractCart(_ shouldContract: Bool) {
        contractCartConstraint.priority = UILayoutPriority(shouldContract ? 999 : 1)
        UIView.animate(withDuration: 0.3, delay: 0) {
            self.view.layoutIfNeeded()
        }
    }
}

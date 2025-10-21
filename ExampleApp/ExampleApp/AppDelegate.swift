//
//  AppDelegate.swift
//  ExampleApp
//
//  Created by Manolis Katsifarakis on 23/11/22.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController(nibName:"ViewController", bundle: nil)
        window?.makeKeyAndVisible()
        
        return true
    }
}


//
//  AppDelegate.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var loadingView: UIView?

    var window: UIWindow? // Do not remove, this is needed by Sprinklr

    private lazy var servicesManager = ServicesManager()

    func addLoadingView() {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor(white: 0.0, alpha: 0.6)
            let indicator = UIActivityIndicatorView(style: .medium)
            view.addSubview(indicator)
            indicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            indicator.startAnimating()
            window.addSubview(view)
            window.bringSubviewToFront(view)
            loadingView = view
        }
    }

    func removeLoadingView() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UISwitch.appearance().onTintColor = .tangemBlue
        UITableView.appearance().backgroundColor = .clear
        UIScrollView.appearance().keyboardDismissMode = AppConstants.defaultScrollViewKeyboardDismissMode
        UINavigationBar.appearance().tintColor = UIColor(Colors.Text.primary1)
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(Colors.Text.primary1),
        ]
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.textAccent

        servicesManager.initialize()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

//
//  AppDelegate.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit
import SomeTestLib

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? // Do not remove, this is needed by Sprinklr

    private lazy var servicesManager = ServicesManager()

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
        print(SomeEnum.default)

        return true
    }

    /// Disable custom keyboards
    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        switch extensionPointIdentifier {
        case UIApplication.ExtensionPointIdentifier.keyboard:
            return false
        default:
            return true
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

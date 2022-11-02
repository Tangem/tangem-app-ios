//
//  AppDelegate.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit
import Firebase
import AppsFlyerLib
import Amplitude


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var loadingView: UIView? = nil

    func addLoadingView() {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let view = UIView(frame: window.bounds)
            view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
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
        UIScrollView.appearance().keyboardDismissMode = .onDrag

        if #available(iOS 14.0, *) {
            UINavigationBar.appearance().tintColor = UIColor(Colors.Text.primary1)
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor(Colors.Text.primary1),
            ]
            // iOS 14 doesn't have extra separators below the list by default.
        } else {
            // To remove only extra separators below the list:
            UITableView.appearance().tableFooterView = UIView()
            UINavigationBar.appearance().tintColor = UIColor(named: "TextPrimary1")
            UINavigationBar.appearance().titleTextAttributes = [
                .foregroundColor: UIColor(named: "TextPrimary1") ?? UIColor.black,
            ]
        }

        if !AppEnvironment.current.isDebug {
            configureFirebase()
            configureAppsFlyer()
            configureAmplitude()
        }

        AppSettings.shared.numberOfLaunches += 1
        migrateTOS()
        print("isAvailable", FeatureProvider.isAvailable(.exchange))

        return true
    }


    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        else {
            return false
        }

        print("User continue with activity url: \(url)")

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        guard AppEnvironment.current.isProduction else { return }

        AppsFlyerLib.shared().start()
    }

    private func migrateTOS() {
        guard AppSettings.shared.isTermsOfServiceAccepted else { return }

        let defaultUrl = DummyConfig().touURL.absoluteString
        AppSettings.shared.termsOfServicesAccepted.insert(defaultUrl)
        AppSettings.shared.isTermsOfServiceAccepted = false
    }
}

private extension AppDelegate {
    func configureFirebase() {
        let plistName = "GoogleService-Info-\(AppEnvironment.current.rawValue.capitalizingFirstLetter())"

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            assertionFailure("GoogleService-Info.plist not found")
            return
        }

        FirebaseApp.configure(options: options)
    }

    func configureAppsFlyer() {
        guard AppEnvironment.current.isProduction else { return }

        AppsFlyerLib.shared().appsFlyerDevKey = try! CommonKeysManager().appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = "1354868448"
    }

    func configureAmplitude() {
        guard AppEnvironment.current.isProduction else { return }

        Amplitude.instance().trackingSessionEvents = true
        Amplitude.instance().initializeApiKey(try! CommonKeysManager().amplitudeApiKey)
    }
}

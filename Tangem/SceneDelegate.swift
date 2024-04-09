//
//  SceneDelegate.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.07.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import TangemSdk
import BlockchainSdk

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    @Injected(\.incomingActionHandler) private var incomingActionHandler: IncomingActionHandler

    var window: UIWindow?

    private lazy var appCoordinator = AppCoordinator()
    private var isSceneStarted = false

    // MARK: - Lifecycle

    // This method can be called during app close, so we have to move out the one-time initialization code outside.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if !handleUrlContexts(connectionOptions.urlContexts) {
            handleActivities(connectionOptions.userActivities)
        }

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            appCoordinator.start(with: .init(newScan: nil))
            let weakifyAdapter = StatusBarStyleConfiguratorWeakifyAdapter()
            let appView = AppCoordinatorView(coordinator: appCoordinator).environment(\.statusBarStyleConfigurator, weakifyAdapter)
            let rootViewController = RootHostingController(rootView: appView)
            weakifyAdapter.adaptee = rootViewController
            window.rootViewController = rootViewController
            self.window = window
            window.overrideUserInterfaceStyle = AppSettings.shared.appTheme.interfaceStyle
            window.makeKeyAndVisible()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !isSceneStarted else { return }

        isSceneStarted = true

        PerformanceMonitorConfigurator.configureIfAvailable()

        guard AppEnvironment.current.isProduction else { return }
    }

    // MARK: - Incoming actions

    /// Hot handle deeplinks `https://tangem.com, https://app.tangem.com`
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleActivities([userActivity])
    }

    /// Hot handle universal links  with `tangem://` scheme
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        handleUrlContexts(URLContexts)
    }

    @discardableResult
    private func handleActivities(_ userActivities: Set<NSUserActivity>) -> Bool {
        for activity in userActivities {
            switch activity.activityType {
            case NSUserActivityTypeBrowsingWeb:
                if let url = activity.webpageURL {
                    if incomingActionHandler.handleDeeplink(url) {
                        return true
                    }
                }

            default:
                if incomingActionHandler.handleIntent(activity.activityType) {
                    return true
                }
            }
        }

        return false
    }

    @discardableResult
    private func handleUrlContexts(_ urlContexts: Set<UIOpenURLContext>) -> Bool {
        for context in urlContexts {
            if incomingActionHandler.handleDeeplink(context.url) {
                return true
            }
        }

        return false
    }
}

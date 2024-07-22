//
//  RootViewControllerFactory.swift
//  Tangem
//
//  Created by m3g0byt3 on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct RootViewControllerFactory {
    func makeRootViewController(for rootView: some View) -> UIViewController {
        guard FeatureProvider.isAvailable(.markets) else {
            return UIHostingController(rootView: rootView)
        }

        let adapter = OverlayContentContainerViewControllerAdapter()

        let rootView = rootView
            .environment(\.overlayContentContainer, adapter)
            .environment(\.overlayContentStateObserver, adapter)

        let contentViewController = UIHostingController(rootView: rootView)

        // TODO: Andrey Fedorov - Adjust all numeric values here for different devices and safe area (IOS-7364)
        let containerViewController = OverlayContentContainerViewController(
            contentViewController: contentViewController,
            overlayCollapsedHeight: 102.0, // https://www.figma.com/design/91bpyCrISuWSvUzTLmcYRc/iOS-%E2%80%93-Draft?node-id=21140-91435&t=Z1kPdSQJ0JLoYgW0-4
            overlayExpandedVerticalOffset: 54.0 // https://www.figma.com/design/91bpyCrISuWSvUzTLmcYRc/iOS-%E2%80%93-Draft?node-id=22985-125042&t=Z1kPdSQJ0JLoYgW0-4
        )

        adapter.set(containerViewController)

        return containerViewController
    }
}

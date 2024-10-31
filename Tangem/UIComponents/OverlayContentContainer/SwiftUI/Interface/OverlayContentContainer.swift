//
//  OverlayContentContainer.swift
//  Tangem
//
//  Created by Andrey Fedorov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

/// Interface that exposes `OverlayContentContainerViewController`'s API into SwiftUI.
protocol OverlayContentContainer {
    var cornerRadius: CGFloat { get }
    var isScrollViewLocked: Bool { get }

    func installOverlay(_ overlayView: some View)
    func removeOverlay()

    /// An ugly workaround due to navigation issues in SwiftUI on iOS 18 and above, see IOS-7990 for details.
    /// Normally, the overlay is intended to be hidden/shown using the `installOverlay`/`removeOverlay` API.
    func setOverlayHidden(_ isHidden: Bool)
}

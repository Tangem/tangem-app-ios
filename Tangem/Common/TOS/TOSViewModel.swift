//
//  TOSViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

class TOSViewModel: ObservableObject {
    let url = AppConstants.tosURL
    let webViewModel: WebViewContainerViewModel

    let bottomOverlayHeight: CGFloat = 116

    init() {
        webViewModel = .init(
            url: url,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: false,
            withNavigationBar: false,
            contentInset: .init(top: 0, left: 0, bottom: bottomOverlayHeight / 2, right: 0)
        )
    }
}

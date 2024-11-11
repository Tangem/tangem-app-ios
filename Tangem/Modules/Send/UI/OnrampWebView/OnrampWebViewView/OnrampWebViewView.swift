//
//  OnrampWebViewView.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.11.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct OnrampWebViewView: View {
    @ObservedObject private var viewModel: OnrampWebViewViewModel

    init(viewModel: OnrampWebViewViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            WebView(url: viewModel.url, urlActions: viewModel.urlActions)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeButton
                    }
                }
        }
    }

    private var closeButton: some View {
        Button(action: viewModel.close) {
            Text(Localization.commonClose)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)
        }
    }
}

//
//  SupportChatViewModel.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 27.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SupportChatViewModel: ObservableObject, Identifiable {
    @Published var viewState: ViewState?
    @Published var showSupportActionSheet: ActionSheetBinder?

    @Injected(\.keysManager) private var keysManager: KeysManager

    private let input: SupportChatInputModel

    init(input: SupportChatInputModel) {
        self.input = input
        setupView()
    }

    func setupView() {
        switch input.environment {
        case .tangem:
            viewState = .zendesk(
                ZendeskSupportChatViewModel(
                    logsComposer: input.logsComposer,
                    showSupportChatSheet: { [weak self] sheet in
                        DispatchQueue.main.async {
                            self?.showSupportActionSheet = ActionSheetBinder(sheet: sheet)
                        }
                    }
                )
            )
        case .saltPay:
            let provider = keysManager.saltPay.sprinklr

            guard var url = URL(string: provider.baseURL) else {
                viewState = .none
                return
            }

            url = url.appendingPathComponent("page")

            guard var urlComponents = URLComponents(string: url.absoluteString) else {
                viewState = .none
                return
            }

            urlComponents.queryItems = [
                URLQueryItem(name: "appId", value: provider.appID),
                URLQueryItem(name: "device", value: "MOBILE"),
                URLQueryItem(name: "enableClose", value: "false"),
                URLQueryItem(name: "zoom", value: "false"),
            ]

            guard let url = urlComponents.url else {
                viewState = .none
                return
            }

            viewState = .webView(url)
        }
    }
}

extension SupportChatViewModel {
    enum ViewState {
        case webView(_ url: URL)
        case zendesk(_ viewModel: ZendeskSupportChatViewModel)
    }
}

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
    @Published var showSupportActionSheet: ActionSheetBinder?
    @Published var zendeskViewModel: ZendeskSupportChatViewModel?
    @Injected(\.keysManager) private var keysManager: KeysManager

    private let input: SupportChatInputModel

    init(input: SupportChatInputModel) {
        self.input = input
        zendeskViewModel = .init(
            logsComposer: input.logsComposer,
            showSupportChatSheet: { [weak self] sheet in
                DispatchQueue.main.async {
                    self?.showSupportActionSheet = ActionSheetBinder(sheet: sheet)
                }
            }
        )
    }
}

extension SupportChatViewModel {
    enum ViewState {
        case webView(_ url: URL)
        case zendesk(_ viewModel: ZendeskSupportChatViewModel)
    }
}

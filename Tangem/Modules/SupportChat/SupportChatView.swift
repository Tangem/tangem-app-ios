//
//  ChatView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SupportChatView: View {
    @ObservedObject var viewModel: SupportChatViewModel

    var body: some View {
        switch viewModel.viewState {
        case .webView(let url):
            WebView(url: url)
        case .zendesk(let zendeskViewModel):
            ZendeskSupportChatView(viewModel: zendeskViewModel)
                .actionSheet(item: $viewModel.showSupportActionSheet, content: { $0.sheet })
        case .none:
            EmptyView()
        }
    }
}

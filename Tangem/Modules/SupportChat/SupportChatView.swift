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
    @Environment(\.dismiss) var dismissAction

    var body: some View {
        VStack {
            //        SprinklrSupportChatView(viewModel: viewModel.sprinklrViewModel)
            Text("Not implemented")

            Button(action: { dismissAction() }, label: {
                Text("Dismiss")
            })
        }
    }
}

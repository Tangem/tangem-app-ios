//
//  CardInfoPageWarningIconAndTitleCellPreviewView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 02/06/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardInfoPageWarningIconAndTitleCellPreviewView: View {
    @ObservedObject var viewModel: CardInfoPageWarningIconAndTitleCellPreviewViewModel

    var body: some View {
        HStack {
            if let icon = viewModel.icon {
                Image(uiImage: icon)
            }

            Text(viewModel.title)
        }
        .padding()
        .infinityFrame(alignment: .topLeading)
    }
}

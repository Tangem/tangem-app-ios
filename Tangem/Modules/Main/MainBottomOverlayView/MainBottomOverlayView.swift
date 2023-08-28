//
//  MainBottomOverlayView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 26.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomOverlayView: View {
    let viewModel: MainBottomOverlayViewModel

    var body: some View {
        MainButton(
            title: viewModel.buttonTitle,
            isDisabled: viewModel.isButtonDisabled,
            action: viewModel.buttonAction
        )
        .padding(.horizontal, 16.0)
        .padding(.top, 14.0)
    }
}

//
//  MainBottomSheetHeaderContainerView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// A temporary entity for integration and testing, subject to change.
struct MainBottomSheetHeaderContainerView: View {
    @ObservedObject var viewModel: MainBottomSheetHeaderViewModel

    var body: some View {
        MainBottomSheetHeaderView(searchText: $viewModel.enteredSearchText, textFieldAllowsHitTesting: true)
    }
}

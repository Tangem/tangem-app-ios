//
//  MainBottomSheetHeaderViewModelDelegate.swift
//  Tangem
//
//  Created by Andrey Fedorov on 11.09.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MainBottomSheetHeaderViewModelDelegate: AnyObject {
    func isViewVisibleForHeaderViewModel(_ viewModel: MainBottomSheetHeaderViewModel) -> Bool
}

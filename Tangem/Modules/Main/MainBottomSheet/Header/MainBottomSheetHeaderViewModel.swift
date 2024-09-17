//
//  MainBottomSheetHeaderViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MainBottomSheetHeaderViewModel: ObservableObject {
    var enteredSearchTextPublisher: AnyPublisher<String, Never> {
        return $enteredSearchText.eraseToAnyPublisher()
    }

    @Published var enteredSearchText = ""
    @Published var inputShouldBecomeFocused = false

    weak var delegate: MainBottomSheetHeaderViewModelDelegate?

    func onBottomSheetExpand(isTapGesture: Bool) {
        guard
            isTapGesture,
            delegate?.isViewVisibleForHeaderViewModel(self) == true
        else {
            return
        }

        inputShouldBecomeFocused = true
    }

    func clearSearchBarAction() {
        delegate?.clearSearchInput()
        enteredSearchText = ""
    }
}

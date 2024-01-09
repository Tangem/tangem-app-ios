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

    func onBottomScrollableSheetStateChange(_ state: BottomScrollableSheetState) {
        if case .top(.tapGesture) = state {
            inputShouldBecomeFocused = true
        }
    }
}

//
//  MainBottomSheetHeaderViewModel.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// TODO: Andrey Fedorov - Add actual implementation
// TODO: Andrey Fedorov - inject routable (coordinator) if needed
final class MainBottomSheetHeaderViewModel: ObservableObject {
    var enteredSearchTextPublisher: some Publisher<String, Never> { return $enteredSearchText }

    @Published var enteredSearchText: String = ""
}

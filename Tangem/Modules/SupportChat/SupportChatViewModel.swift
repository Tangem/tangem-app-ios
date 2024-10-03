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
//    @Published var sprinklrViewModel = SprinklrSupportChatViewModel()
    private let input: SupportChatInputModel

    init(input: SupportChatInputModel) {
        self.input = input
    }
}

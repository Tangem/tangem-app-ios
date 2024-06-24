//
//  SendSummaryInputOutputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

class SendSummaryInputOutputMock: SendSummaryInput, SendSummaryOutput {}

class SendSummaryInteractorMock: SendSummaryInteractor {
    var isSending: AnyPublisher<Bool, Never> { .just(output: false) }
}

//
//  SendDestinationInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendDestinationInput: AnyObject {
    var destinationPublisher: AnyPublisher<SendAddress, Never> { get }
    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { get }
}

protocol SendDestinationOutput: AnyObject {
    func destinationDidChanged(_ address: SendAddress?)
    func destinationAdditionalParametersDidChanged(_ type: SendDestinationAdditionalField)
}

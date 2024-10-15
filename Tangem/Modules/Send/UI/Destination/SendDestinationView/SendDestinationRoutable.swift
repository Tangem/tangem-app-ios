//
//  SendDestinationRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

protocol SendDestinationRoutable: AnyObject {
    func openQRScanner(with codeBinding: Binding<String>, networkName: String)
}

protocol SendDestinationStepRoutable: AnyObject {
    func destinationStepFulfilled()
}

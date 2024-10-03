//
//  UserCodeRecovering.swift
//  Tangem
//
//  Created by Alexander Osokin on 15.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

protocol UserCodeRecovering: AnyObject {
    var isUserCodeRecoveryAllowed: Bool { get }
    var isUserCodeRecoveryAllowedPublisher: AnyPublisher<Bool, Never> { get }

    func toggleUserCodeRecoveryAllowed(completion: @escaping (Result<Bool, TangemSdkError>) -> Void)
}

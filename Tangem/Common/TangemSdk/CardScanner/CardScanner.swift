//
//  CardScanner.swift
//  Tangem
//
//  Created by Alexander Osokin on 11.04.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

protocol CardScanner {
    func scanCard(completion: @escaping (Result<AppScanTaskResponse, TangemSdkError>) -> Void)
    func scanCardPublisher() -> AnyPublisher<AppScanTaskResponse, TangemSdkError>
}

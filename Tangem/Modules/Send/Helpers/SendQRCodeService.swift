//
//  SendQRCodeService.swift
//  Tangem
//
//  Created by Sergey Balashov on 09.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendQRCodeService {
    var qrCodeDestination: AnyPublisher<String?, Never> { get }
    var qrCodeAdditionalField: AnyPublisher<String?, Never> { get }
    var qrCodeAmount: AnyPublisher<Decimal?, Never> { get }

    func qrCodeDidScanned(value: String)
}

struct CommonSendQRCodeService {
    private let parser: QRCodeParser
    private let _result = PassthroughSubject<QRCodeParser.Result, Never>()

    init(parser: QRCodeParser) {
        self.parser = parser
    }
}

extension CommonSendQRCodeService: SendQRCodeService {
    var qrCodeDestination: AnyPublisher<String?, Never> {
        _result.map { $0.destination }.eraseToAnyPublisher()
    }

    var qrCodeAdditionalField: AnyPublisher<String?, Never> {
        _result.map { $0.memo }.eraseToAnyPublisher()
    }

    var qrCodeAmount: AnyPublisher<Decimal?, Never> {
        _result.map { $0.amount?.value }.eraseToAnyPublisher()
    }

    func qrCodeDidScanned(value: String) {
        guard let result = parser.parse(value) else {
            return
        }

        _result.send(result)
    }
}

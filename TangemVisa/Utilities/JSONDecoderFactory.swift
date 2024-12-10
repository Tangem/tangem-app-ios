//
//  JSONDecoderFactory.swift
//  TangemVisa
//
//  Created by Andrew Son on 05.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JSONDecoderFactory {
    func makePayAPIDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }

    func makeCIMDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS")
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
}

//
//  VisaAuthorizationAPIError.swift
//  TangemVisa
//
//  Created by Andrew Son on 07.11.24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaAuthorizationAPIError: Decodable, LocalizedError {
    public let error: String
    public let errorDescription: String?
}

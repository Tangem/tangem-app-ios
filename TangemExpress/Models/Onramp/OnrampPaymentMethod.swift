//
//  OnrampPaymentMethod.swift
//  TangemApp
//
//  Created by Sergey Balashov on 14.10.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

public struct OnrampPaymentMethod: Hashable {
    public let id: String
    public let name: String
    public let image: URL

    public var type: MethodType {
        MethodType(rawValue: id) ?? .other
    }

    public init(id: String, name: String, image: URL) {
        self.id = id
        self.name = name
        self.image = image
    }
}

public extension OnrampPaymentMethod {
    enum MethodType: String {
        case applePay = "apple-pay"
        case card

        // Google Pay doesn't support on iOS
        case googlePay = "google-pay"

        // Generic for other not so important methods
        case other

        public var priority: Int {
            switch self {
            case .applePay: return 2
            case .card: return 1
            case .other: return 0
            case .googlePay: return -1
            }
        }
    }
}

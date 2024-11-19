//
//  XRPLResponse.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation
import AnyCodable

// struct XRPWebSocketResponse<T:Codable>: Codable {
//    var id: String
//    var status: String
//    var type: String
//    var result: T
// }

struct XRPWebSocketResponse: Codable {
    let id: String
    let status: String
    let type: String
    private let _result: AnyCodable
    var result: [String: AnyObject] {
        return _result.value as! [String: AnyObject]
    }

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case type
        case _result = "result"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        status = try values.decode(String.self, forKey: .status)
        type = try values.decode(String.self, forKey: .type)
        _result = try values.decode(AnyCodable.self, forKey: ._result)
    }
}

struct XRPJsonRpcResponse<T> {
    var result: T
}

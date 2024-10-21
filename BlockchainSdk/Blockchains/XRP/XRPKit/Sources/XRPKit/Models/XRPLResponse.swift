//
//  XRPLResponse.swift
//  BigInt
//
//  Created by Mitch Lang on 2/3/20.
//

import Foundation
import AnyCodable


//public struct XRPWebSocketResponse<T:Codable>: Codable {
//    public var id: String
//    public var status: String
//    public var type: String
//    public var result: T
//}

public struct XRPWebSocketResponse: Codable{
    public let id: String
    public let status: String
    public let type: String
    private let _result: AnyCodable
    public var result: [String:AnyObject] {
        return _result.value as! [String:AnyObject]
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case type
        case _result = "result"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        status = try values.decode(String.self, forKey: .status)
        type = try values.decode(String.self, forKey: .type)
        _result = try values.decode(AnyCodable.self, forKey: ._result)
    }
}

public struct XRPJsonRpcResponse<T> {
    public var result: T
}

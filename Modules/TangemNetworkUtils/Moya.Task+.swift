//
//  Moya.Task+.swift
<<<<<<<< HEAD:Modules/TangemNetworkLayerAdditions/Moya.Task+.swift
//  TangemNetworkLayerAdditions
========
//  TangemNetworkUtils
>>>>>>>> develop:Modules/TangemNetworkUtils/Moya.Task+.swift
//
//  Created by Sergey Balashov on 28.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import struct Alamofire.URLEncoding

public extension Moya.Task {
    static func requestParameters(
        _ encodable: Encodable,
        encoder: JSONEncoder = JSONEncoder(),
        encoding: ParameterEncoding = URLEncoding()
    ) -> Task {
        do {
            let data = try encoder.encode(encodable)
            let parameters = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return .requestParameters(parameters: parameters ?? [:], encoding: encoding)
        } catch {
            assertionFailure("Moya.Task request parameters catch error \(error)")
            return .requestPlain
        }
    }
}

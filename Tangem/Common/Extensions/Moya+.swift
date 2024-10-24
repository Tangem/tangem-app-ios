//
//  Moya+.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

protocol CachePolicyProvider {
    var cachePolicy: URLRequest.CachePolicy { get }
}

class CachePolicyPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let cachePolicyGettable = target as? CachePolicyProvider {
            var mutableRequest = request
            mutableRequest.cachePolicy = cachePolicyGettable.cachePolicy
            return mutableRequest
        }

        return request
    }
}

protocol TimeoutIntervalProvider {
    var timeoutInterval: TimeInterval? { get }
}

class TimeoutIntervalPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if let timeoutIntervalProvider = target as? TimeoutIntervalProvider,
           let timeoutInterval = timeoutIntervalProvider.timeoutInterval {
            var mutableRequest = request
            mutableRequest.timeoutInterval = timeoutInterval
            return mutableRequest
        }

        return request
    }
}

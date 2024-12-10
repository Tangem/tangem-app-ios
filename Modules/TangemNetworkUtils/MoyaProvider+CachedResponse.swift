//
//  MoyaProvider+CachedResponse
//  TangemNetworkUtils
//
//  Created by Dmitry Fedorov on 10/12/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

public extension MoyaProvider {
    /// Get cached response for provided target.
    /// Limited to targets which provide the same URLRequest on different calls.
    /// - Parameter target: request target
    /// - Returns: response from urlCache
    func cachedResponse(for target: Target) -> CachedURLResponse? {
        let endpoint = endpoint(target)
        guard let urlRequest = try? endpoint.urlRequest() else { return nil }
        return session.session.configuration.urlCache?.cachedResponse(for: urlRequest)
    }
}

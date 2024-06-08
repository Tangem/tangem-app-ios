//
//  APIListUtils.swift
//  Tangem
//
//  Created by Andrew Son on 25/04/24.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct APIListUtils {
    private let fileName = "providers_order"

    func parseLocalAPIListJson() throws -> APIList {
        let apiListDTO = try JsonUtils.readBundleFile(with: fileName, type: APIListDTO.self)
        return convertToSDKModels(apiListDTO)
    }

    func convertToSDKModels(_ listDTO: APIListDTO) -> APIList {
        return listDTO.reduce(into: [:]) { partialResult, element in
            let providers: [NetworkProviderType] = element.value.compactMap { apiInfo in
                switch APIType(rawValue: apiInfo.type) {
                case .public:
                    guard
                        let link = apiInfo.url,
                        // Check that link is valid
                        URL(string: link) != nil
                    else {
                        return nil
                    }

                    return NetworkProviderType.public(link: link)
                case .private:
                    return mapToNetworkProviderType(name: apiInfo.name)
                case .none:
                    return nil
                }
            }

            partialResult[element.key] = providers
        }
    }

    private func mapToNetworkProviderType(name: String?) -> NetworkProviderType? {
        guard
            let name,
            let apiProvider = APIProvider(rawValue: name)
        else {
            return nil
        }

        return apiProvider.blockchainProvider
    }
}

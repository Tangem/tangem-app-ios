//
//  CommonSmartContractMethodMapper.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class CommonSmartContractMethodMapper {
    private lazy var dataSource: [String: ContractMethod] = {
        do {
            var json: [String: ContractMethod] = [:]
            try DispatchQueue.global().sync {
                json = try JsonUtils.readBundleFile(with: "contract_methods", type: [String: ContractMethod].self)
            }
            return json
        } catch {
            AppLog.shared.debug("Contract methods doesn't found")
            return [:]
        }
    }()

    init() {}
}

// MARK: - SmartContractMethodMapper

extension CommonSmartContractMethodMapper: SmartContractMethodMapper {
    func getName(for method: String) -> String? {
        dataSource[method]?.name
    }
}

private extension CommonSmartContractMethodMapper {
    struct ContractMethod: Decodable {
        let name: String
        let source: URL?
        let info: String?
    }
}

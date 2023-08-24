//
//  OrganizeTokensOptionsEditing.swift
//  Tangem
//
//  Created by Andrey Fedorov on 05.08.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol OrganizeTokensOptionsEditing {
    func group(by groupingOption: OrganizeTokensOptions.Grouping)
    func sort(by sortingOption: OrganizeTokensOptions.Sorting)
    func save(reorderedWalletModelIds: [WalletModel.ID]) -> AnyPublisher<Void, Never>
}

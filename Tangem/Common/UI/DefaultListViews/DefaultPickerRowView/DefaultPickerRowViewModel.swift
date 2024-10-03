//
//  DefaultPickerRowViewModel.swift
//  Tangem
//
//  Created by Alexander Osokin on 13.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DefaultPickerRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }

    let title: String
    let options: [String]
    let selection: BindingValue<String>

    init(title: String, options: [String], selection: BindingValue<String>) {
        self.title = title
        self.options = options
        self.selection = selection
    }
}

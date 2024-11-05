//
//  SearchUtil.swift
//  TangemApp
//
//  Created by Aleksei Muraveinik on 3.11.24..
//  Copyright © 2024 Tangem AG. All rights reserved.
//

enum SearchUtil<T> {
    static func search(_ items: [T], in keyPath: KeyPath<T, String>, for searchText: String) -> [T] {
        if searchText.isEmpty {
            return items
        }

        let loweccasedSearchText = searchText.lowercased().trimmed()

        return items
            .filter { item in
                item[keyPath: keyPath]
                    .lowercased()
                    .contains(loweccasedSearchText)
            }
            .sorted { item, _ in
                item[keyPath: keyPath]
                    .split(separator: " ")
                    .contains { $0.starts(with: searchText) }
            }
    }
}

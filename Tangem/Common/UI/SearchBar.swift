//
//  SearchBar.swift
//  Tangem
//
//  Created by Alexander Osokin on 18.01.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import CombineExt

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        @Published private var inputText = ""
        private var cancellable: AnyCancellable?

        init(text: Binding<String>) {
            _text = text
            super.init()
            cancellable = $inputText
                .dropFirst()
                .assign(to: \.text, on: self, ownership: .weak)
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            inputText = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = true
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = false
        }
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal

        searchBar.autocapitalizationType = .none
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }
}
